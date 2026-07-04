"""
Pruebas de integracion del motor de IA de zonas de riesgo (motor_ia_zonas_riesgo.py)
sobre mongomock.

Valida las reglas de negocio agregadas en esta iteracion:
- El motor detecta automaticamente el ultimo mes con datos SIDPOL y genera
  las zonas SOLO con ese mes (no con el historico completo).
- Cada zona guarda anio_periodo / mes_periodo (la app los usa para auto-filtrar).
- Los datos fuera de la provincia de Tacna o SIN COORDENADA se ignoran.
- El cooldown de la notificacion "mapa actualizado" registra su marca en db.config.
"""
from datetime import datetime

import mongomock
import pytest

import motor_ia_zonas_riesgo as motor


@pytest.fixture
def db(monkeypatch):
    mock_db = mongomock.MongoClient()["test_geocrimen"]
    monkeypatch.setattr(motor, "db", mock_db)
    return mock_db


def _sidpol(fecha, lat=-18.0146, lng=-70.2536, provincia="TACNA", estado_coord="CON COORDENADA"):
    return {
        "ubicacion": {"type": "Point", "coordinates": [lng, lat]},
        "subtipo_hecho": "HURTO",
        "fuente": "arcgis_sidpol",
        "provincia_hecho": provincia,
        "estado_coord": estado_coord,
        "fecha_hecho": fecha,
    }


def _sembrar_cluster(db, fecha, n=8, **kwargs):
    """n puntos casi identicos (< 150 m) → DBSCAN debe formar un cluster."""
    docs = [_sidpol(fecha, lat=-18.0146 + i * 0.0001, **kwargs) for i in range(n)]
    db.historial_delitos.insert_many(docs)


# ────────────────── _detectar_ultimo_mes_sidpol ──────────────────

def test_detecta_el_mes_mas_reciente_con_datos(db):
    db.historial_delitos.insert_many([
        _sidpol(datetime(2026, 3, 10)),
        _sidpol(datetime(2026, 5, 20)),   # el mas reciente
        _sidpol(datetime(2025, 12, 1)),
    ])
    assert motor._detectar_ultimo_mes_sidpol() == (2026, 5)


def test_sin_datos_sidpol_cae_al_mes_actual(db):
    anio, mes = motor._detectar_ultimo_mes_sidpol()
    ahora = motor._utcnow()
    assert (anio, mes) == (ahora.year, ahora.month)


# ────────────────── ejecutar_ia_zonas_riesgo ──────────────────

def test_genera_zonas_solo_del_ultimo_mes(db):
    # Mes reciente: cluster valido de 8 puntos en mayo 2026
    _sembrar_cluster(db, datetime(2026, 5, 15), n=8)
    # Historico viejo en otra ubicacion (enero 2024): NO debe producir zona
    _sembrar_cluster(db, datetime(2024, 1, 10), n=8, lng=-70.30)

    motor.ejecutar_ia_zonas_riesgo()

    zonas = list(db.zonas_riesgo.find({}))
    assert len(zonas) == 1, "solo el cluster del mes detectado (05/2026) genera zona"
    zona = zonas[0]
    assert zona["anio_periodo"] == 2026 and zona["mes_periodo"] == 5
    assert zona["total_incidentes"] == 8
    assert zona["nivel_riesgo"] == "bajo"          # < 10 casos
    assert zona["delito_predominante"] == "HURTO"
    # El centroide debe caer sobre el cluster real (zona centro de Tacna)
    lng, lat = zona["centroide"]["coordinates"]
    assert abs(lat - (-18.0146)) < 0.01 and abs(lng - (-70.2536)) < 0.01


def test_ignora_otras_provincias_y_sin_coordenada(db):
    fecha = datetime(2026, 5, 15)
    _sembrar_cluster(db, fecha, n=8, provincia="TARATA")                 # otra provincia
    _sembrar_cluster(db, fecha, n=8, estado_coord="SIN COORDENADA")     # geo-forzada

    motor.ejecutar_ia_zonas_riesgo()

    assert db.zonas_riesgo.count_documents({}) == 0


def test_menos_de_5_puntos_no_genera_zonas(db):
    _sembrar_cluster(db, datetime(2026, 5, 15), n=4)   # bajo el min_samples de DBSCAN

    motor.ejecutar_ia_zonas_riesgo()

    assert db.zonas_riesgo.count_documents({}) == 0


def test_regenerar_reemplaza_zonas_anteriores(db):
    db.zonas_riesgo.insert_one({"distrito": "ZONA VIEJA", "nivel_riesgo": "critico"})
    _sembrar_cluster(db, datetime(2026, 5, 15), n=8)

    motor.ejecutar_ia_zonas_riesgo()

    assert db.zonas_riesgo.count_documents({"distrito": "ZONA VIEJA"}) == 0, \
        "el guardado es atomico: borra las zonas anteriores antes de insertar"


def test_cooldown_registra_marca_de_notificacion(db):
    _sembrar_cluster(db, datetime(2026, 5, 15), n=8)

    motor.ejecutar_ia_zonas_riesgo()

    marca = db.config.find_one({"key": "last_map_update_notification"})
    assert marca is not None and "sent_at" in marca


def test_cooldown_no_reenvia_antes_de_24h(db, monkeypatch):
    _sembrar_cluster(db, datetime(2026, 5, 15), n=8)
    # Marca de envio hace 1 hora
    hace_1h = motor._utcnow()
    db.config.insert_one({"key": "last_map_update_notification", "sent_at": hace_1h})

    enviados = []
    import firebase_service
    monkeypatch.setattr(
        firebase_service, "send_push_notification",
        lambda **kw: enviados.append(kw) or True,
    )

    motor.ejecutar_ia_zonas_riesgo()

    assert enviados == [], "dentro de la ventana de 24h no debe salir notificacion"
    # La marca original no debe haberse sobreescrito (tolerancia de 1 s por el
    # truncado BSON de microsegundos a milisegundos)
    marca = db.config.find_one({"key": "last_map_update_notification"})
    assert abs((marca["sent_at"] - hace_1h).total_seconds()) < 1.0
