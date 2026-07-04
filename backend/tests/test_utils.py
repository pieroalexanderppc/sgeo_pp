"""
Pruebas unitarias de los modulos utilitarios puros (sin BD ni red):
- utils.time_helpers: clasificacion de turnos y pesos de riesgo por hora.
- utils.string_helpers: normalizacion difusa de nombres de distritos.
- utils.crypto: hash y verificacion de contrasenas con bcrypt.
"""
import pytest

from utils.time_helpers import get_turno, get_turno_weight, get_local_time
from utils.string_helpers import limpiar_distrito, COORDENADAS_DISTRITOS
from utils.crypto import hash_password, verify_password


# ─────────────────────────── time_helpers ───────────────────────────

@pytest.mark.parametrize("hora,esperado", [
    (0, "MADRUGADA"), (5, "MADRUGADA"),   # límites inferiores
    (6, "MAÑANA"), (11, "MAÑANA"),
    (12, "TARDE"), (17, "TARDE"),
    (18, "NOCHE"), (23, "NOCHE"),
])
def test_get_turno_limites_de_cada_franja(hora, esperado):
    assert get_turno(hora) == esperado


def test_get_turno_weight_madrugada_es_el_mas_riesgoso():
    pesos = {h: get_turno_weight(h) for h in [3, 9, 15, 21]}
    # MADRUGADA (1.5) > NOCHE (1.2) > TARDE (0.8) > MAÑANA (0.7)
    assert pesos[3] > pesos[21] > pesos[15] > pesos[9]


def test_get_local_time_devuelve_hora_de_lima_por_defecto():
    dt = get_local_time()
    assert dt.tzinfo is not None
    assert dt.utcoffset().total_seconds() == -5 * 3600  # Peru es UTC-5 fijo


def test_get_local_time_zona_invalida_usa_lima():
    dt = get_local_time("Zona/Inexistente")
    assert dt.utcoffset().total_seconds() == -5 * 3600


# ─────────────────────────── string_helpers ───────────────────────────

def test_limpiar_distrito_nombre_exacto():
    assert limpiar_distrito("POCOLLAY") == "POCOLLAY"


def test_limpiar_distrito_normaliza_minusculas_y_tildes():
    assert limpiar_distrito("pocóllay") == "POCOLLAY"
    assert limpiar_distrito("  Calaná ") == "CALANA"


@pytest.mark.parametrize("entrada,esperado", [
    ("GREGORIO ALBARRACIN", "CORONEL GREGORIO ALBARRACIN LANCHIPA"),
    ("C.G. ALBARRACIN", "CORONEL GREGORIO ALBARRACIN LANCHIPA"),
    ("LA YARADA", "LA YARADA LOS PALOS"),
    ("ALTO ALIANZA", "ALTO DE LA ALIANZA"),
])
def test_limpiar_distrito_atajos_manuales(entrada, esperado):
    assert limpiar_distrito(entrada) == esperado


def test_limpiar_distrito_fuzzy_matching():
    # Error tipografico razonable → corrige al distrito real
    assert limpiar_distrito("POCOLAY") == "POCOLLAY"


def test_limpiar_distrito_vacio_o_desconocido_cae_a_tacna():
    assert limpiar_distrito(None) == "TACNA"
    assert limpiar_distrito("") == "TACNA"
    assert limpiar_distrito("XYZ123") == "TACNA"


def test_coordenadas_distritos_dentro_de_rango_de_tacna():
    for nombre, c in COORDENADAS_DISTRITOS.items():
        assert -19.0 < c["lat"] < -17.0, f"lat fuera de rango en {nombre}"
        assert -71.0 < c["lng"] < -69.5, f"lng fuera de rango en {nombre}"


# ─────────────────────────── crypto ───────────────────────────

def test_hash_y_verify_password_roundtrip():
    h = hash_password("MiClaveSegura123!")
    assert h != "MiClaveSegura123!"          # nunca en texto plano
    assert verify_password("MiClaveSegura123!", h) is True


def test_verify_password_rechaza_clave_incorrecta():
    h = hash_password("correcta")
    assert verify_password("incorrecta", h) is False


def test_verify_password_hash_corrupto_no_lanza_excepcion():
    assert verify_password("algo", "no-es-un-hash-bcrypt") is False


def test_hash_password_usa_salt_aleatorio():
    # Dos hashes de la misma clave deben ser distintos (salt aleatorio)
    assert hash_password("misma") != hash_password("misma")
