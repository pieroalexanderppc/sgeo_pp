"""
Pruebas de integracion del router de autenticacion (routes/auth.py).

Cubre: registro de ciudadano, duplicados, login correcto/incorrecto y el
flujo de aprobacion policial (cuenta nace inactiva y el login responde 403
hasta que el admin la apruebe). El envio de email se anula con monkeypatch
para no depender de SMTP.
"""
import mongomock
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import routes.auth as auth_module
from config.database import get_db
from utils.crypto import hash_password


@pytest.fixture
def mongo_db():
    return mongomock.MongoClient()["test_geocrimen"]


@pytest.fixture
def client(monkeypatch, mongo_db):
    # El email post-registro de policia no debe intentar salir a SMTP en tests
    async def _sin_email(**kwargs):
        return None
    monkeypatch.setattr(auth_module.email_service, "solicitar_datos_policia", _sin_email)

    app = FastAPI()
    app.include_router(auth_module.router)
    app.dependency_overrides[get_db] = lambda: mongo_db
    return TestClient(app)


def _registro(rol="ciudadano", email="juan@test.com", nombre="Juan Test"):
    return {
        "nombre": nombre,
        "email": email,
        "password": "Secreta123!",
        "rol": rol,
        "is_active": True,
    }


# ────────────────── registro ──────────────────

def test_registro_ciudadano_exitoso(client, mongo_db):
    r = client.post("/api/auth/register", json=_registro())

    assert r.status_code == 200
    assert r.json()["status"] == "success"
    guardado = mongo_db.usuarios.find_one({"email": "juan@test.com"})
    assert guardado["rol"] == "ciudadano" and guardado["activo"] is True
    assert guardado["password_hash"] != "Secreta123!"  # nunca en texto plano


def test_registro_email_duplicado_devuelve_400(client):
    client.post("/api/auth/register", json=_registro())
    r = client.post("/api/auth/register", json=_registro(nombre="Otro Nombre"))
    assert r.status_code == 400
    assert "registrado" in r.json()["detail"].lower()


def test_registro_nombre_duplicado_devuelve_400(client):
    client.post("/api/auth/register", json=_registro())
    r = client.post("/api/auth/register", json=_registro(email="otro@test.com"))
    assert r.status_code == 400


def test_registro_policia_queda_pendiente_de_aprobacion(client, mongo_db):
    r = client.post(
        "/api/auth/register",
        json=_registro(rol="policia", email="agente@pnp.gob.pe", nombre="Agente PNP"),
    )

    assert r.status_code == 200
    guardado = mongo_db.usuarios.find_one({"email": "agente@pnp.gob.pe"})
    # Gate de seguridad: la cuenta policial nace desactivada hasta revision del admin
    assert guardado["activo"] is False
    assert guardado["aprobacion_pendiente"] is True


# ────────────────── login ──────────────────

def test_login_exitoso_devuelve_datos_sin_password(client, mongo_db):
    mongo_db.usuarios.insert_one({
        "nombre": "Maria", "email": "maria@test.com",
        "password_hash": hash_password("clave123"),
        "rol": "ciudadano", "activo": True,
    })

    r = client.post("/api/auth/login", json={"email": "maria@test.com", "password": "clave123"})

    assert r.status_code == 200
    usuario = r.json()["usuario"]
    assert usuario["rol"] == "ciudadano"
    assert "password_hash" not in usuario and "password" not in usuario


def test_login_password_incorrecta_devuelve_401(client, mongo_db):
    mongo_db.usuarios.insert_one({
        "nombre": "Maria", "email": "maria@test.com",
        "password_hash": hash_password("clave123"),
        "rol": "ciudadano", "activo": True,
    })
    r = client.post("/api/auth/login", json={"email": "maria@test.com", "password": "incorrecta"})
    assert r.status_code == 401


def test_login_email_inexistente_devuelve_401_mismo_mensaje(client):
    # Mismo mensaje que password incorrecta: no revelar si el correo existe
    r = client.post("/api/auth/login", json={"email": "nadie@test.com", "password": "x"})
    assert r.status_code == 401
    assert "incorrectos" in r.json()["detail"].lower()


def test_login_policia_pendiente_devuelve_403(client, mongo_db):
    mongo_db.usuarios.insert_one({
        "nombre": "Agente", "email": "agente@pnp.gob.pe",
        "password_hash": hash_password("clave123"),
        "rol": "policia", "activo": False, "aprobacion_pendiente": True,
    })
    r = client.post("/api/auth/login", json={"email": "agente@pnp.gob.pe", "password": "clave123"})
    assert r.status_code == 403
    assert "revisada" in r.json()["detail"].lower()


def test_login_policia_rechazado_informa_motivo(client, mongo_db):
    mongo_db.usuarios.insert_one({
        "nombre": "Agente", "email": "agente@pnp.gob.pe",
        "password_hash": hash_password("clave123"),
        "rol": "policia", "activo": False,
        "motivo_rechazo": "Documento CIP ilegible",
    })
    r = client.post("/api/auth/login", json={"email": "agente@pnp.gob.pe", "password": "clave123"})
    assert r.status_code == 403
    assert "CIP" in r.json()["detail"]
