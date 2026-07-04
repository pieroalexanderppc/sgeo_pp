"""
Pruebas de integracion del flujo del rol POLICIA sobre /api/reportes:
confirmar, rechazar y el listado completo para el mapa/validaciones.

La notificacion push y el motor de IA (background task) se reemplazan por dobles
de prueba: aqui se valida el contrato HTTP y los efectos en la base de datos.
"""
from datetime import datetime, timezone

import mongomock
import pytest
from bson.objectid import ObjectId
from fastapi import FastAPI
from fastapi.testclient import TestClient

import routes.reports as reports_module


def _utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)


@pytest.fixture
def mongo_db():
    return mongomock.MongoClient()["test_geocrimen"]


@pytest.fixture
def entorno(monkeypatch, mongo_db):
    """Client + registro de llamadas a push/IA (no deben ejecutarse de verdad)."""
    llamadas = {"push": [], "ia": 0}

    monkeypatch.setattr(reports_module, "db", mongo_db)
    monkeypatch.setattr(
        reports_module, "send_push_notification",
        lambda **kw: llamadas["push"].append(kw) or True,
    )

    def _ia_falsa():
        llamadas["ia"] += 1
    monkeypatch.setattr(reports_module, "ejecutar_ia_zonas_riesgo", _ia_falsa)

    app = FastAPI()
    app.include_router(reports_module.router)
    return TestClient(app), llamadas


def _reporte_pendiente(db):
    return db.reportes_ciudadano.insert_one({
        "subtipo_hecho": "ROBO",
        "ubicacion": {"type": "Point", "coordinates": [-70.2536, -18.0146]},
        "estado": "pendiente",
        "distrito_hecho": "TACNA", "provincia_hecho": "TACNA",
        "departamento_hecho": "TACNA", "turno_hecho": "NOCHE",
        "fecha_hora_hecho": _utcnow(), "creado_en": _utcnow(),
    }).inserted_id


def test_confirmar_dispara_push_con_coordenadas_e_ia(entorno, mongo_db):
    client, llamadas = entorno
    rid = _reporte_pendiente(mongo_db)

    r = client.post(f"/api/reportes/confirmar/{rid}")

    assert r.status_code == 200
    assert r.json()["status"] == "success"
    # La alerta push a los ciudadanos lleva el punto GPS exacto del incidente
    assert len(llamadas["push"]) == 1
    push = llamadas["push"][0]
    assert push["tipo_alerta"] == "incident"
    assert push["lat"] == -18.0146 and push["lng"] == -70.2536
    assert push["topic"] == "alertas_ciudadanos"
    # El recalculo de zonas corre como tarea de fondo tras responder
    assert llamadas["ia"] == 1


def test_confirmar_inexistente_devuelve_404_y_no_notifica(entorno):
    client, llamadas = entorno

    r = client.post(f"/api/reportes/confirmar/{ObjectId()}")

    assert r.status_code == 404
    assert llamadas["push"] == [] and llamadas["ia"] == 0


def test_rechazar_no_dispara_push_ni_ia(entorno, mongo_db):
    client, llamadas = entorno
    rid = _reporte_pendiente(mongo_db)

    r = client.post(f"/api/reportes/rechazar/{rid}")

    assert r.status_code == 200
    assert mongo_db.reportes_ciudadano.find_one({"_id": rid})["estado"] == "rechazado"
    assert llamadas["push"] == [] and llamadas["ia"] == 0


def test_listado_policia_incluye_los_tres_estados(entorno, mongo_db):
    client, _ = entorno
    base = {
        "subtipo_hecho": "HURTO",
        "ubicacion": {"type": "Point", "coordinates": [-70.25, -18.01]},
        "fecha_hora_hecho": _utcnow(),
    }
    mongo_db.reportes_ciudadano.insert_many([
        {**base, "estado": "pendiente"},
        {**base, "estado": "confirmado"},
        {**base, "estado": "rechazado"},
        {**base, "estado": "agrupado"},   # agrupados NO van al listado
    ])

    r = client.get("/api/reportes/policia")

    assert r.status_code == 200
    estados = sorted(p["estado"] for p in r.json()["puntos"])
    assert estados == ["confirmado", "pendiente", "rechazado"]


def test_eliminar_solo_reportes_pendientes(entorno, mongo_db):
    client, _ = entorno
    rid = _reporte_pendiente(mongo_db)
    confirmado = mongo_db.reportes_ciudadano.insert_one({
        "subtipo_hecho": "ROBO", "estado": "confirmado",
        "ubicacion": {"type": "Point", "coordinates": [-70.25, -18.01]},
    }).inserted_id

    assert client.delete(f"/api/reportes/{rid}").status_code == 200
    assert client.delete(f"/api/reportes/{confirmado}").status_code == 400
    # El pendiente se borro; el confirmado sigue intacto
    assert mongo_db.reportes_ciudadano.find_one({"_id": rid}) is None
    assert mongo_db.reportes_ciudadano.find_one({"_id": confirmado}) is not None
