import os
import requests
import pandas as pd
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()
MONGO_URL = os.getenv("MONGO_URL")

def descargar_archivo(url, ruta_destino):
    print(f"Descargando {url}...")
    headers = {'User-Agent': 'Mozilla/5.0'}
    
    try:
        respuesta = requests.get(url, headers=headers)
        if respuesta.status_code == 200:
            os.makedirs(os.path.dirname(ruta_destino), exist_ok=True)
            with open(ruta_destino, 'wb') as f:
                f.write(respuesta.content)
            print(f"Descarga completada: {ruta_destino}")
            return True
        else:
            print(f"Error al descargar. Codigo: {respuesta.status_code}")
            return False
    except Exception as e:
        print(f"Excepcion al descargar {url}: {e}")
        return False

def insertar_datos_historicos_mongodb(df, nombre_coleccion, mapeo_columnas):
    client = MongoClient(MONGO_URL)
    db = client['geocrimen_tacna']  
    coleccion = db[nombre_coleccion]
    
    columnas_mantener = [c for c in mapeo_columnas.keys() if c in df.columns]
    df = df[columnas_mantener].copy()
    
    df = df.rename(columns=mapeo_columnas)
    
    import numpy as np
    df = df.replace({np.nan: None})
    
    print(f"Borrando datos antiguos en {nombre_coleccion} para insertar data histórica limpia...")
    coleccion.delete_many({}) # Como es importación masiva histórica completa, vaciamos la colección

    documentos = df.to_dict('records')
    ahora = datetime.now(timezone.utc)
    
    for doc in documentos:
        doc['importado_en'] = ahora
        for k, v in list(doc.items()):
            if pd.isna(v):
                doc[k] = None
    
    if documentos:
        try:
            print(f"Insertando {len(documentos)} registros históricos...")
            coleccion.insert_many(documentos, ordered=False)
            print(f"Éxito: Se insertaron los registros históricos en {nombre_coleccion}.")
        except Exception as e:
            print(f"Excepcion al insertar bloque masivo en {nombre_coleccion}: {e}")
    else:
        print(f"Advertencia: No hay documentos para insertar en {nombre_coleccion}.")

def obtener_url_sidpol():
    """Busca el enlace de descarga mas reciente en la pagina de Mininter (SIDPOL)."""
    url_gob = "https://www.gob.pe/institucion/mininter/informes-publicaciones"
    headers = {'User-Agent': 'Mozilla/5.0'}
    try:
        res = requests.get(url_gob, headers=headers)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        enlaces = soup.find_all('a', href=True)
        for enlace in enlaces:
            href = enlace['href']
            if 'cdn.www.gob.pe' in href and 'sidpol' in href.lower() and '.xlsx' in href:
                return href
            
        for enlace in enlaces:
            if 'base-de-datos' in enlace.get('href', '') and 'sidpol' in enlace.get('href', ''):
                sub_url = f"https://www.gob.pe{enlace['href']}" if enlace['href'].startswith('/') else enlace['href']
                res_sub = requests.get(sub_url, headers=headers)
                soup_sub = BeautifulSoup(res_sub.text, 'html.parser')
                btn_descargar = soup_sub.find('a', string=lambda t: t and 'Descargar' in t)
                if btn_descargar:
                    return btn_descargar['href']
                    
    except Exception as e:
        print(f"Error scrapeando SIDPOL: {e}")
        
    return "https://cdn.www.gob.pe/uploads/document/file/9667704/7912719-base-de-datos-del-sistema-de-denuncias-policiales-sidpol-a-febrero-del-2026.xlsx"


def automatizacion_historica():
    carpeta_datos = "datos_descargados"
    ruta_sidpol = f"{carpeta_datos}/sidpol_historico.xlsx"
    
    url_sidpol = obtener_url_sidpol()
    print(f"URL de SIDPOL detectada: {url_sidpol}")
    
    descarga_sidpol_ok = descargar_archivo(url_sidpol, ruta_sidpol)

    if descarga_sidpol_ok:
        print("\n--- PROCESANDO DATA HISTÓRICA DE SIDPOL (2018-2026) ---")
        try:
            xls = pd.ExcelFile(ruta_sidpol)
            
            dfs_validos = []
            print(f"Buscando y extrayendo datos de todas las hojas válidas (adaptando formatos antiguos)... esto tardará...")
            for sheet in xls.sheet_names:
                df_temp = pd.read_excel(xls, sheet_name=sheet)
                df_temp.columns = df_temp.columns.str.strip()
                
                # Verificar si la hoja tiene información por distrito (PROV_HECHO) y algún detalle del delito (TIPO, SUB_TIPO o P_MODALIDADES)
                if 'PROV_HECHO' in df_temp.columns and ('TIPO' in df_temp.columns or 'SUB_TIPO' in df_temp.columns or 'P_MODALIDADES' in df_temp.columns):
                    
                    # Normalizar columnas de hojas antiguas como Temp5.2
                    if 'P_MODALIDADES' in df_temp.columns and 'MODALIDAD' not in df_temp.columns:
                        df_temp = df_temp.rename(columns={'P_MODALIDADES': 'MODALIDAD'})
                        
                    # Rellenar columnas vacías para que pandas concat y groupby funcionen sin errores de columna faltante
                    if 'TIPO' not in df_temp.columns:
                        df_temp['TIPO'] = 'NO ESPECIFICADO'
                    if 'SUB_TIPO' not in df_temp.columns:
                        df_temp['SUB_TIPO'] = 'NO ESPECIFICADO'
                    if 'MODALIDAD' not in df_temp.columns:
                        df_temp['MODALIDAD'] = 'NO ESPECIFICADO'

                    print(f" - Hoja válida encontrada y leída: {sheet} ({len(df_temp)} filas)")
                    dfs_validos.append(df_temp)
            
            if not dfs_validos:
                print("No se encontraron hojas con el detalle requerido en el archivo.")
                return
            
            df_sidpol = pd.concat(dfs_validos, ignore_index=True)
            
            df_sidpol['UBIGEO_HECHO'] = df_sidpol['UBIGEO_HECHO'].astype(str).str.strip()
            
            # 1. FILTRAR POR RANGO DE AÑOS (2018 hasta 2026)
            df_sidpol['ANIO'] = pd.to_numeric(df_sidpol['ANIO'], errors='coerce')
            df_sidpol = df_sidpol[(df_sidpol['ANIO'] >= 2018) & (df_sidpol['ANIO'] <= 2026)]
            
            # 2. FILTRAR SOLO RESULTADOS DE TACNA
            df_sidpol = df_sidpol[df_sidpol['DPTO_HECHO_NEW'].astype(str).str.upper().str.strip() == 'TACNA']
            df_sidpol = df_sidpol[df_sidpol['PROV_HECHO'].astype(str).str.upper().str.strip() == 'TACNA']
            
            df_sidpol = df_sidpol.dropna(subset=['DIST_HECHO'])
            df_sidpol = df_sidpol[df_sidpol['DIST_HECHO'].astype(str).str.strip() != '']
            df_sidpol = df_sidpol[df_sidpol['DIST_HECHO'].astype(str).str.upper().str.strip() != 'TACNA']
            
            # 3. FILTRAR TIPOS DE DELITOS DE ATENCIÓN PATRIMONIAL
            palabras_clave = ['ROBO', 'HURTO', 'USURPACIÓN', 'USURPACION']
            patron = '|'.join(palabras_clave)
            df_sidpol = df_sidpol[
                df_sidpol['SUB_TIPO'].astype(str).str.upper().str.contains(patron, na=False) |
                df_sidpol['MODALIDAD'].astype(str).str.upper().str.contains(patron, na=False) |
                df_sidpol['TIPO'].astype(str).str.upper().str.contains(patron, na=False) # Agregado porque en las antiguas podría estar aquí
            ]
            
            # 4. AGRUPACIÓN PARA CREAR LA ESTADÍSTICA FINAL
            columnas_agrupar = ['ANIO', 'MES', 'UBIGEO_HECHO', 'DPTO_HECHO_NEW', 'PROV_HECHO', 'DIST_HECHO', 'TIPO', 'SUB_TIPO', 'MODALIDAD']
            df_sidpol = df_sidpol.groupby(columnas_agrupar, as_index=False)['n_dist_ID_DGC'].sum()
            
            mapeo_sidpol = {
                'ANIO': 'anio', 
                'MES': 'mes',
                'UBIGEO_HECHO': 'ubigeo',
                'DPTO_HECHO_NEW': 'departamento',
                'PROV_HECHO': 'provincia',
                'DIST_HECHO': 'distrito',
                'TIPO': 'tipo',
                'SUB_TIPO': 'sub_tipo',
                'MODALIDAD': 'modalidad',
                'n_dist_ID_DGC': 'cantidad'
            }
            
            if not df_sidpol.empty:
                insertar_datos_historicos_mongodb(df_sidpol, 'estadisticas_sidpol_historico', mapeo_sidpol)
            else:
                print("No se encontraron registros históricos en SIDPOL tras aplicar filtros (2018-2026).")
                
        except Exception as e:
            print(f"Error procesando SIDPOL Histórico: {e}")
        finally:
            if 'xls' in locals():
                xls.close()
            if os.path.exists(ruta_sidpol):
                try:
                    os.remove(ruta_sidpol)
                    print("Limpieza: Archivo temporal .xlsx eliminado.")
                except Exception as e:
                    print(f"No se pudo eliminar el archivo. {e}")

if __name__ == "__main__":
    if not MONGO_URL:
        print("Error: Faltan credenciales MONGO_URL en el entorno")
    else:
        print("Iniciando extracción y guardado histórico (2018-2026)...")
        automatizacion_historica()
