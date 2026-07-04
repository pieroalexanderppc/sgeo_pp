"""
Pruebas unitarias del servicio de reportes (services/report_service.py) con mongomock.

Incluye la prueba de regresion del bug corregido en esta iteracion: al confirmar un
reporte, la copia a historial_delitos debe usar los nombres de campo del schema
(departamento_hecho, provincia_hecho, distrito_hecho, turno_hecho) y fuente="ciudadano";
los nombres antiguos (departamento, provincia, ...) y fuente="CIUDADANO_APP" provocaban
"Document failed validation" en MongoDB Atlas.
"""
from datetime import datetime, timezone

import mongomock
import pytest
from bson.objectid import ObjectId
from fastapi import HTTPException

from models.report_schemas import ReporteCiudadano
from services.report_service import (
    validar_limite_diario,
    construir_metadatos_reporte,
    confirmar_reporte_en_db,
    rechazar_reporte_en_db,
)


def _utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)


@pytest.fixture
def db():
    return mongomock.MongoClient()["test_geocrimen"]


def _reporte_pendiente(db, **extra):
    """Siembra un reporte pendiente realista y devuelve su ObjectId."""
    doc = {
        "usuario_id": ObjectId(),
        "anonimo": False,
        "tipo_hecho": "PATRIMONIO (DELITO)",
        "subtipo_hecho": "ROBO",
        "modalidad_hecho": "ARREBATO",
        "ubicacion": {"type": "Point", "coordinates": [-70.2536, -18.0146]},
        "direccion_hecho": "Av. Bolognesi 123",
        "distrito_hecho": "TACNA",
        "provincia_hecho": "TACNA",
        "departamento_hecho": "TACNA",
        "estado": "pendiente",
        "fecha_hora_hecho": _utcnow(),
        "turno_hecho": "NOCHE",
        "anio": 2026, "mes": 7, "dia": 2,
        "creado_en": _utcnow(),
    }
    doc.update(extra)
    return db.reportes_ciudadano.insert_one(doc).inserted_id


# ────────────────── construir_metadatos_reporte (unitaria pura) ──────────────────

def test_construir_metadatos_estructura_completa():
    reporte = ReporteCiudadano(subtipo_hecho="robo", latitud=-18.01, longitud=-70.25)
    user_id = ObjectId()

    meta = construir_metadatos_reporte(reporte, user_id)

    assert meta["subtipo_hecho"] == "ROBO"                      # normaliza a mayúsculas
    assert meta["estado"] == "pendiente"                        # nace pendiente siempre
    assert meta["anonimo"] is False and meta["usuario_id"] == user_id
    # GeoJSON: orden [longitud, latitud]
    assert meta["ubicacion"] == {"type": "Point", "coordinates": [-70.25, -18.01]}
    # Temporalidad derivada de hora local de Lima
    assert meta["turno_hecho"] in ("MADRUGADA", "MAÑANA", "TARDE", "NOCHE")
    assert meta["dia_semana"] in (
        "lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"
    )
    assert isinstance(meta["anio"], int) and isinstance(meta["mes"], int)


def test_construir_metadatos_anonimo_sin_usuario():
    reporte = ReporteCiudadano(subtipo_hecho="HURTO", latitud=-18.0, longitud=-70.2)
    meta = construir_metadatos_reporte(reporte, None)
    assert meta["anonimo"] is True and meta["usuario_id"] is None


def test_construir_metadatos_modalidad_por_defecto():
    reporte = ReporteCiudadano(subtipo_hecho="HURTO", latitud=-18.0, longitud=-70.2)
    meta = construir_metadatos_reporte(reporte, None)
    assert meta["modalidad_hecho"] == "NO ESPECIFICADO"


# ────────────────── validar_limite_diario ──────────────────

def test_limite_diario_pasa_con_menos_de_5(db):
    user = ObjectId()
    for _ in range(4):
        db.reportes_ciudadano.insert_one(
            {"usuario_id": user, "creado_en": _utcnow()}
        )
    assert validar_limite_diario(db, user) is True


def test_limite_diario_bloquea_el_sexto(db):
    user = ObjectId()
    for _ in range(5):
        db.reportes_ciudadano.insert_one(
            {"usuario_id": user, "creado_en": _utcnow()}
        )
    with pytest.raises(HTTPException) as exc:
        validar_limite_diario(db, user)
    assert exc.value.status_code == 429


# ────────────────── confirmar_reporte_en_db ──────────────────

def test_confirmar_actualiza_estado_y_devuelve_coordenadas(db):
    rid = _reporte_pendiente(db)

    resultado = confirmar_reporte_en_db(db, str(rid))

    assert resultado["status"] == "success"
    assert resultado["lat"] == -18.0146 and resultado["lng"] == -70.2536
    actualizado = db.reportes_ciudadano.find_one({"_id": rid})
    assert actualizado["estado"] == "confirmado"
    assert "confirmado_en" in actualizado


def test_regresion_confirmar_copia_historial_con_campos_del_schema(db):
    """Bug corregido: el insert a historial_delitos usaba departamento/provincia/
    distrito/turno y fuente=CIUDADANO_APP, violando el $jsonSchema de la coleccion."""
    rid = _reporte_pendiente(db)

    confirmar_reporte_en_db(db, str(rid))

    hist = db.historial_delitos.find_one({})
    assert hist is not None, "el reporte confirmado debe copiarse a historial_delitos"
    # Campos con el sufijo _hecho exigidos por el validador de MongoDB
    for campo in ("departamento_hecho", "provincia_hecho", "distrito_hecho", "turno_hecho"):
        assert campo in hist, f"falta {campo} en historial_delitos"
    # El enum del schema solo admite: arcgis_sidpol | ciudadano
    assert hist["fuente"] == "ciudadano"
    assert hist["estado_coord"] == "VALIDADO APP"
    assert hist["fecha_hecho"] is not None


def test_confirmar_id_invalido_devuelve_400(db):
    with pytest.raises(HTTPException) as exc:
        confirmar_reporte_en_db(db, "no-es-un-objectid")
    assert exc.value.status_code == 400


def test_confirmar_reporte_inexistente_devuelve_404(db):
    with pytest.raises(HTTPException) as exc:
        confirmar_reporte_en_db(db, str(ObjectId()))
    assert exc.value.status_code == 404


def test_confirmar_dos_veces_devuelve_400(db):
    rid = _reporte_pendiente(db)
    confirmar_reporte_en_db(db, str(rid))
    with pytest.raises(HTTPException) as exc:
        confirmar_reporte_en_db(db, str(rid))
    assert exc.value.status_code == 400


# ────────────────── rechazar_reporte_en_db ──────────────────

def test_rechazar_marca_estado_rechazado(db):
    rid = _reporte_pendiente(db)

    resultado = rechazar_reporte_en_db(db, str(rid))

    assert resultado["status"] == "success"
    doc = db.reportes_ciudadano.find_one({"_id": rid})
    assert doc["estado"] == "rechazado" and "rechazado_en" in doc
    # Un rechazo NO debe alimentar el historial de la IA
    assert db.historial_delitos.count_documents({}) == 0


def test_rechazar_reporte_inexistente_devuelve_404(db):
    with pytest.raises(HTTPException) as exc:
        rechazar_reporte_en_db(db, str(ObjectId()))
    assert exc.value.status_code == 404
