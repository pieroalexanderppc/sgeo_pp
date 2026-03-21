import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()
MONGO_URL = os.getenv('MONGO_URL')

client = MongoClient(MONGO_URL)
db = client['geocrimen_tacna']

resultado = db.estadisticas_sidpol.delete_many({'distrito': 'TACNA'})
print(f'Se borraron {resultado.deleted_count} registros de estadisticas_sidpol del distrito TACNA.')

