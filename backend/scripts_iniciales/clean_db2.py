import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()
MONGO_URL = os.getenv('MONGO_URL')

client = MongoClient(MONGO_URL)
db = client['geocrimen_tacna']

rt = db.zonas_riesgo.delete_many({'distrito': 'TACNA'})
print(f'Borrados {rt.deleted_count} de zonas de riesgo.')

