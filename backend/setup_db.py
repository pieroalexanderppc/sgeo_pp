import os
from datetime import datetime
from pymongo import MongoClient
from dotenv import load_dotenv
import bcrypt

# Cargar configuración desde .env
load_dotenv()

MONGO_URL = os.getenv("MONGO_URL")

def get_password_hash(password):
    # Genera el salt y cifra la contraseña usando la librería oficial de bcrypt directamente
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def setup_db():
    if not MONGO_URL:
        print("❌ Error: Faltan las credenciales MONGO_URL en el archivo .env")
        return

    client = MongoClient(MONGO_URL)
    db = client['geocrimen_tacna']

    print("✅ Conectado a MongoDB Railway")

    # 1. USUARIOS
    try:
        db.create_collection('usuarios', validator={
            "$jsonSchema": {
                "bsonType": "object",
                "required": ["nombre", "email", "password_hash", "rol"],
                "properties": {
                    "nombre": {"bsonType": "string"},
                    "email": {"bsonType": "string"},
                    "password_hash": {"bsonType": "string"},
                    "rol": {"enum": ["ciudadano", "policia", "admin"]},
                    "telefono": {"bsonType": "string"},
                    "ubicacion_default": {
                        "bsonType": "object",
                        "properties": {
                            "type": {"enum": ["Point"]},
                            "coordinates": {"bsonType": "array"}
                        }
                    },
                    "distrito": {"bsonType": "string"},
                    "ubigeo": {"bsonType": "string"},
                    "activo": {"bsonType": "bool"},
                    "creado_en": {"bsonType": "date"}
                }
            }
        })
        db.usuarios.create_index("email", unique=True)
        db.usuarios.create_index([("ubicacion_default", "2dsphere")])
        print("✅ Colección 'usuarios' creada")
    except Exception as e:
        print("⚠️  La colección 'usuarios' ya existe o hubo un error:", e)

    # 2. REPORTES_CIUDADANO
    try:
        db.create_collection('reportes_ciudadano', validator={
            "$jsonSchema": {
                "bsonType": "object",
                "required": ["sub_tipo", "modalidad", "ubicacion", "distrito", "fecha_hecho", "estado"],
                "properties": {
                    "usuario_id": {"bsonType": ["objectId", "null"]},
                    "anonimo": {"bsonType": "bool"},
                    "tipo": {"enum": ["PATRIMONIO (DELITO)"]},
                    "sub_tipo": {"enum": ["HURTO", "ROBO", "EXTORSION"]},
                    "modalidad": {"bsonType": "string"},
                    "ubicacion": {
                        "bsonType": "object",
                        "required": ["type", "coordinates"],
                        "properties": {
                            "type": {"enum": ["Point"]},
                            "coordinates": {"bsonType": "array"}
                        }
                    },
                    "direccion": {"bsonType": "string"},
                    "distrito": {"bsonType": "string"},
                    "ubigeo": {"bsonType": "string"},
                    "fecha_hecho": {"bsonType": "date"},
                    "hora_aprox": {"bsonType": "string"},
                    "descripcion": {"bsonType": "string"},
                    "fotos": {"bsonType": "array"},
                    "estado": {"enum": ["pendiente", "confirmado", "rechazado"]},
                    "creado_en": {"bsonType": "date"}
                }
            }
        })
        print("✅ Colección 'reportes_ciudadano' creada")
    except Exception as e:
        print("⚠️  La colección 'reportes_ciudadano' ya existe o hubo un error.")

    # 3. INCIDENTES
    try:
        db.create_collection('incidentes', validator={
            "$jsonSchema": {
                "bsonType": "object",
                "required": ["fuente", "sub_tipo", "modalidad", "ubicacion", "distrito", "fecha_hecho", "anio", "mes"],
                "properties": {
                    "fuente": {"enum": ["ciudadano", "policia", "sidpol"]},
                    "reporte_id": {"bsonType": ["objectId", "null"]},
                    "verificado_por": {"bsonType": ["objectId", "null"]},
                    "tipo": {"enum": ["PATRIMONIO (DELITO)"]},
                    "sub_tipo": {"enum": ["HURTO", "ROBO", "EXTORSION"]},
                    "modalidad": {"bsonType": "string"},
                    "ubicacion": {
                        "bsonType": "object",
                        "required": ["type", "coordinates"],
                        "properties": {
                            "type": {"enum": ["Point"]},
                            "coordinates": {"bsonType": "array"}
                        }
                    },
                    "direccion": {"bsonType": "string"},
                    "distrito": {"bsonType": "string"},
                    "ubigeo": {"bsonType": "string"},
                    "fecha_hecho": {"bsonType": "date"},
                    "anio": {"bsonType": "int"},
                    "mes": {"bsonType": "int", "minimum": 1, "maximum": 12},
                    "descripcion": {"bsonType": "string"},
                    "fotos": {"bsonType": "array"},
                    "creado_en": {"bsonType": "date"}
                }
            }
        })
        db.incidentes.create_index([("ubicacion", "2dsphere")])
        print("✅ Colección 'incidentes' creada")
    except Exception as e:
        print("⚠️  La colección 'incidentes' ya existe o hubo un error.")

    # 4. ESTADISTICAS_SIDPOL
    try:
        db.create_collection('estadisticas_sidpol', validator={
            "$jsonSchema": {
                "bsonType": "object",
                "required": ["anio", "mes", "ubigeo", "distrito", "cantidad"],
                "properties": {
                    "anio": {"bsonType": "int"},
                    "mes": {"bsonType": "int", "minimum": 1, "maximum": 12},
                    "ubigeo": {"bsonType": "string"},
                    "departamento": {"bsonType": "string"},
                    "provincia": {"bsonType": "string"},
                    "distrito": {"bsonType": "string"},
                    "tipo": {"bsonType": "string"},
                    "sub_tipo": {"bsonType": "string"},
                    "modalidad": {"bsonType": "string"},
                    "cantidad": {"bsonType": "int"},
                    "importado_en": {"bsonType": "date"}
                }
            }
        })
        db.estadisticas_sidpol.create_index(
            [("ubigeo", 1), ("anio", 1), ("mes", 1), ("sub_tipo", 1), ("modalidad", 1)],
            unique=True,
            name="unique_sidpol"
        )
        print("✅ Colección 'estadisticas_sidpol' creada")
    except Exception as e:
        print("⚠️  La colección 'estadisticas_sidpol' ya existe o hubo un error.")

    # 5. ZONAS_RIESGO
    try:
        db.create_collection('zonas_riesgo', validator={
            "$jsonSchema": {
                "bsonType": "object",
                "required": ["centroide", "radio_metros", "distrito", "nivel_riesgo", "total_incidentes", "tendencia"],
                "properties": {
                    "centroide": {
                        "bsonType": "object",
                        "required": ["type", "coordinates"],
                        "properties": {
                            "type": {"enum": ["Point"]},
                            "coordinates": {"bsonType": "array"}
                        }
                    },
                    "radio_metros": {"bsonType": "int"},
                    "distrito": {"bsonType": "string"},
                    "ubigeo": {"bsonType": "string"},
                    "nivel_riesgo": {"enum": ["bajo", "medio", "alto", "critico"]},
                    "total_incidentes": {"bsonType": "int"},
                    "delito_predominante": {"bsonType": "string"},
                    "tendencia": {"enum": ["subiendo", "estable", "bajando"]},
                    "periodo_analizado": {
                        "bsonType": "object",
                        "properties": {
                            "desde": {"bsonType": "date"},
                            "hasta": {"bsonType": "date"}
                        }
                    },
                    "calculado_en": {"bsonType": "date"}
                }
            }
        })
        db.zonas_riesgo.create_index([("centroide", "2dsphere")])
        print("✅ Colección 'zonas_riesgo' creada")
    except Exception as e:
        print("⚠️  La colección 'zonas_riesgo' ya existe o hubo un error.")

    # 6. ALERTAS
    try:
        db.create_collection('alertas', validator={
            "$jsonSchema": {
                "bsonType": "object",
                "required": ["usuario_id", "tipo", "mensaje"],
                "properties": {
                    "usuario_id": {"bsonType": "objectId"},
                    "incidente_id": {"bsonType": ["objectId", "null"]},
                    "zona_id": {"bsonType": ["objectId", "null"]},
                    "tipo": {"enum": ["nuevo_incidente", "zona_peligrosa", "zona_actualizada"]},
                    "mensaje": {"bsonType": "string"},
                    "leida": {"bsonType": "bool"},
                    "push_enviado": {"bsonType": "bool"},
                    "creado_en": {"bsonType": "date"}
                }
            }
        })
        print("✅ Colección 'alertas' creada")
    except Exception as e:
        print("⚠️  La colección 'alertas' ya existe o hubo un error.")

    # Crear Usuarios Iniciales
    print("\n--- CREANDO USUARIOS DE PRUEBA Y ADMIN ---")
    
    import datetime as dt
    now_utc = dt.datetime.now(dt.timezone.utc)
    
    usuarios_iniciales = [
        {
            "nombre": "Admin Supremo",
            "email": "admin@sgeo.com",
            "password_hash": get_password_hash("ffe.Ad95"),
            "rol": "admin",
            "activo": True,
            "creado_en": now_utc
        },
        {
            "nombre": "Agente Policia 1",
            "email": "policia@sgeo.com",
            "password_hash": get_password_hash("123456"),
            "rol": "policia",
            "activo": True,
            "creado_en": now_utc
        },
        {
            "nombre": "Ciudadano Juan",
            "email": "juan@ciudadano.com",
            "password_hash": get_password_hash("123456"),
            "rol": "ciudadano",
            "activo": True,
            "creado_en": now_utc
        }
    ]

    for user in usuarios_iniciales:
        # Verifica si ya existe para no duplicarlo cada vez
        if not db.usuarios.find_one({"email": user["email"]}):
            db.usuarios.insert_one(user)
            print(f"👤 Creado: {user['email']} ({user['rol']})")
        else:
            print(f"🔹 Ya existía: {user['email']}")

    print("\n🎉 Base de datos lista.")

if __name__ == "__main__":
    setup_db()