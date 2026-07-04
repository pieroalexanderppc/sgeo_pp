"""
Pruebas de integracion del router de mapas (routes/maps.py) con TestClient + mongomock.

Cubre los contratos que consumen los mapas de la app Flutter:
- /api/map/zonas_riesgo: serializacion y cache en memoria (60 s).
- /api/map/puntos_exactos: solo confirmados y solo de los ultimos 60 dias
  (regla agregada en esta iteracion para que el mapa no acumule alertas viejas).
- /api/map/historial_puntos: excluye documentos SIN COORDENADA.
"""
from datetime import datetime, timedelta, timezone

import mongomock
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import routes.maps as maps_module


def _utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)


@pytest.fixture
def mongo_db():
    return mongomock.MongoClient()["test_geocrimen"]


@pytest.fixture
def client(monkeypatch, mongo_db):
    monkeypatch.setattr(maps_module, "db", mongo_db)
    maps_module._cache_store.clear()  # el cache es global al modulo: aislar cada test

    app = FastAPI()
    app.include_router(maps_module.router)
    return TestClient(app)


# ────────────────── /zonas_riesgo ──────────────────

def test_zonas_riesgo_serializa_y_conserva_periodo(client, mongo_db):
    mongo_db.zonas_riesgo.insert_one({
        "centroide": {"type": "Point", "coordinates": [-70.25, -18.01]},
        "radio_metros": 200,
        "distrito": "Zona Caliente Detectada",
        "nivel_riesgo": "medio",
        "total_incidentes": 13,
        "delito_predominante": "HURTO",
        "tendencia": "estable",
        "calculado_en": _utcnow(),
        "anio_periodo": 2026,
        "mes_periodo": 5,
    })

    r = client.get("/api/map/zonas_riesgo")

    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "success" and body["cached"] is False
    zona = body["zonas"][0]
    assert isinstance(zona["_id"], str)                 # ObjectId serializado
    assert isinstance(zona["calculado_en"], str)        # datetime → isoformat
    # El mapa ciudadano usa estos campos para auto-filtrar el periodo
    assert zona["anio_periodo"] == 2026 and zona["mes_periodo"] == 5


def test_zonas_riesgo_segunda_llamada_sale_del_cache(client, mongo_db):
    mongo_db.zonas_riesgo.insert_one({
        "centroide": {"type": "Point", "coordinates": [-70.2, -18.0]},
        "radio_metros": 150, "distrito": "X", "nivel_riesgo": "bajo",
        "total_incidentes": 5, "delito_predominante": "HURTO",
        "tendencia": "estable", "calculado_en": _utcnow(),
    })

    assert client.get("/api/map/zonas_riesgo").json()["cached"] is False
    assert client.get("/api/map/zonas_riesgo").json()["cached"] is True


def test_zonas_riesgo_vacio_devuelve_lista_vacia(client):
    r = client.get("/api/map/zonas_riesgo")
    assert r.status_code == 200
    assert r.json()["zonas"] == []


# ────────────────── /puntos_exactos ──────────────────

def test_puntos_exactos_solo_confirmados_recientes(client, mongo_db):
    base = {
        "subtipo_hecho": "ROBO",
        "ubicacion": {"type": "Point", "coordinates": [-70.25, -18.01]},
        "fecha_hora_hecho": _utcnow(),
    }
    mongo_db.reportes_ciudadano.insert_many([
        # 1) confirmado hace 1 dia → SI debe salir
        {**base, "estado": "confirmado", "confirmado_en": _utcnow() - timedelta(days=1)},
        # 2) confirmado hace 100 dias → NO (regla de 60 dias)
        {**base, "estado": "confirmado", "confirmado_en": _utcnow() - timedelta(days=100)},
        # 3) pendiente → NO (nunca se muestran al ciudadano)
        {**base, "estado": "pendiente"},
        # 4) rechazado → NO
        {**base, "estado": "rechazado"},
    ])

    r = client.get("/api/map/puntos_exactos")

    assert r.status_code == 200
    puntos = r.json()["puntos"]
    assert len(puntos) == 1
    assert puntos[0]["estado"] == "confirmado"


# ────────────────── /historial_puntos ──────────────────

def test_historial_excluye_sin_coordenada(client, mongo_db):
    base = {
        "subtipo_hecho": "HURTO",
        "ubicacion": {"type": "Point", "coordinates": [-70.24, -18.02]},
        "fuente": "arcgis_sidpol",
        "fecha_hecho": _utcnow(),
    }
    mongo_db.historial_delitos.insert_many([
        {**base, "estado_coord": "CON COORDENADA"},
        {**base, "estado_coord": "VALIDADO APP"},
        {**base, "estado_coord": "SIN COORDENADA"},  # geo-forzada a comisaria: excluir
    ])

    r = client.get("/api/map/historial_puntos")

    assert r.status_code == 200
    puntos = r.json()["puntos"]
    assert len(puntos) == 2
    assert all(p.get("fuente") == "arcgis_sidpol" for p in puntos)
