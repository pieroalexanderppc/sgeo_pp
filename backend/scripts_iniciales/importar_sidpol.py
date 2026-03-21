import os
import csv
from datetime import datetime
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()
MONGO_URL = os.getenv("MONGO_URL")

def importar_datos_reales():
    if not MONGO_URL:
        print("❌ Error: Faltan credenciales MONGO_URL")
        return

    client = MongoClient(MONGO_URL)
    db = client['geocrimen_tacna']

    print("🧹 Limpiando base de datos estadisticas_sidpol...")
    db.estadisticas_sidpol.delete_many({})

    ruta_txt = '../DATOS.txt' # El script se corre desde /backend
    if not os.path.exists(ruta_txt):
        print(f"❌ No se encontro {ruta_txt}")
        return

    docs = []
    
    with open(ruta_txt, 'r', encoding='utf-8') as f:
        # Usar tabulación como delimitador
        reader = csv.reader(f, delimiter='\t')
        headers = next(reader) # Leer cabeceras
        
        # Encontrar el indice de la columna de Cantidad dinamicamente
        idx_cantidad = -1
        for i, h in enumerate(headers):
            if "Cantidad" in h:
                idx_cantidad = i
                break
                
        if idx_cantidad == -1:
            idx_cantidad = 9 # Por defecto la ultima columna del txt
            
        for row in reader:
            if not row or len(row) < 10: continue
            
            docs.append({
                "anio": int(row[0]),
                "mes": int(row[1]),
                "ubigeo": row[2],
                "departamento": row[3],
                "provincia": row[4],
                "distrito": row[5],
                "tipo": row[6],
                "sub_tipo": row[7],
                "modalidad": row[8],
                "cantidad": int(row[idx_cantidad]),
                "importado_en": datetime.utcnow()
            })

    if docs:
        db.estadisticas_sidpol.insert_many(docs)
        print(f"✅ ¡Éxito! Se han importado {len(docs)} lineas de estadísticas desde DATOS.txt a MongoDB.")
    else:
        print("⚠️ No se encontraron datos para importar.")

if __name__ == "__main__":
    importar_datos_reales()