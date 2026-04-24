# 📱 SGEO - Sistema de Geolocalización de Inseguridad Ciudadana

Aplicación móvil orientada a la participación ciudadana y la acción policial estratégica. Su objetivo es registrar, visualizar, predecir y alertar sobre zonas de inseguridad en tiempo real combinando reportes comunitarios y datos oficiales procesados mediante Inteligencia Artificial (Machine Learning Espacial).

## 📂 Arquitectura Completa del Repositorio (Análisis de Carpetas)

El sistema está estructurado bajo una arquitectura de microservicios e interfaces modulares, separando estrictamente el Frontend (App Híbrida) del Backend (API de datos inteligente).

```bash
📦 SGEO_PP/
├── 📱 lib/                             # Frontend: App Híbrida construida en Flutter (Dart)
│   ├── core/                           # Núcleo del cliente:
│   │   ├── services/                   # -> Servicios lógicos: auth_service, geofence_service, map_service, firebase...
│   │   ├── models/ y theme/            # -> Estructuras de datos locales y diseño visual base
│   ├── features/                       # Módulos globales e independientes (ej. Pantallas de Autenticación / Registro)
│   ├── roles/                          # Arquitectura Basada en Roles (Vistas y Controladores):
│   │   ├── user/                       # -> Vistas de ciudadano (crear denuncia, ver mapa personal, notificaciones)
│   │   ├── police/                     # -> Vistas y panel de Policía (validación de reportes, patrullaje)
│   │   └── admin/                      # -> Panel de control de administradores del sistema
│   └── main.dart                       # Punto de entrada de la aplicación móvil y configuraciones base. 
│
├── 🌍 backend/                         # Backend: Servidor Inteligente en Python (FastAPI)
│   ├── main.py                         # API RESTful central (Rutas de reportes, mapas, motor y usuarios)
│   ├── motor_ia_espacial.py            # Motor de Machine Learning (Scikit-Learn / Algoritmo DBSCAN)
│   ├── firebase_service.py             # Transmisor de Push Notifications globales usando Admins SDK (FCM)
│   ├── requirements.txt y runtime.txt  # Dependencias de Python y versión del Runtime (Production)
│   ├── Procfile                        # Orquestador de despliegue principal para uvicorn en servidor
│   └── scripts_iniciales/              # Scripts de Ingeniería de Datos (ETL) y Scraping:
│       ├── importador_mensual.py       # -> Cron Job automático mensual (Web Scraping de MININTER)
│       ├── importador_data.py          # -> Migrador de Data Histórica Masiva 2018-2026 (Limpieza Pandas)
│       └── setup_db.py                 # -> Configuración e índices geoespaciales 2dsphere (MongoDB)
│
├── 📄 docs/                            # Documentación técnica y marcos metodológicos (SCRUM.md)
├── ⚙️ pubspec.yaml                     # Orquestación de dependencias del ecosistema móvil de Dart/Flutter
├── ⚙️ firebase.json                    # Enlace estructurado de configuración Firebase-Flutter
├── ⚙️ ios/                             # Configuraciones nativas generadas para compilar en Apple y Xcode
├── ⚙️ android/                         # Configuraciones nativas (Gradle, manifest) para dispositivos Android
└── ⚙️ build/                           # Directorio temporal de salidas de compilación en local 
```

## 🚀 Arquitectura y Despliegue en Producción

El cerebro y los almacenes de datos del sistema operan bajo una estructura de Nube Integrada (Cloud Computing).

- **API RESTful Backend**: Alojada productivamente en `https://sgeo-backend-production.up.railway.app`
- **Integración DevOps**: `Procfile` y procesos Cron (Railway / Cloud) garantizan un funcionamiento continuo mensual de los ETL.
- **Base de Datos MongoDB Atlas**: Almacenamiento centralizado NoSQL con optimización matemática de consultas geoespaciales y almacenamiento en caché nativo de métricas geográficas.

## 📋 Módulos y Funcionalidades Clave del Ecosistema

### 🧠 Inteligencia Artificial y Topografía de Riesgo 
- **Clustering Espacial (DBSCAN):** Analiza en la nube los reportes validados, evaluando la cercanía geográfica por metros para fusionarlos en "Puntos Calientes" (Hotspots) predictivos de manera automática.
- **Fusión de Variables:** Cruza métricas históricas de la Unidad de Flagrancia y la Policía Nacional (SIDPOL) con la capa comunitaria moderna detectada por la app para declarar diferentes niveles de peligrosidad.

### 🛡️ Geocercas (Geofencing) y Monitoreo Satelital Silencioso
- **Vigilancia Transparente:** El teléfono vigila el entorno físico del usuario sin necesidad de tener la pantalla de la app abierta mediante `Geolocator`.
- **Alarma Preventiva Local:** Realiza cálculos de distancia de proximidad en tiempo real. Si la latitud del usuario cruza el radio trazado de una zona roja detectada por la IA, el teléfono alerta al usuario (vibración/sonido) para su rápida prevención.

### 🚨 Sistema Multirrol: Comunidad y Autoridad
- **Ciudadano (`roles/user`):** Ingresa denuncias instantáneas, sube evidencia temporal a la nube y consume el nivel de riesgo de su zona en mapas personalizados integrados.
- **Autoridad Policial (`roles/police`):** Su vista administrativa les permite validar falsos positivos y "Confirmar" los reportes ciudadanos incrementando la eficiencia del algoritmo DBSCAN.

### 📡 Sincronización Inmediata Notificada (Firebase FCM)
- Cuando el motor del backend decide un incremento sustancial en el peligro de una matriz, notifica y dispara alertas masivas (Push Notifications) mediante la vinculación con el archivo `firebase_service.py` hacia toda la comunidad que posea un dispositivo registrado.
- La aplicación retiene de forma local estas notificaciones (`SharedPreferences`) permitiendo ver un historial de alarmas activadas históricamente (Cache/Inbox Local).

## 🛠️ Stack Tecnológico Transversal

| Capa Técnica | Herramientas Utilizadas | Responsabilidad Primaria |
|------------|-------------------------|--------------------------|
| **Frontend Móvil** | Flutter (Dart), Geolocator, SharedPrefs | Interfaces multirrol, geocercas background y persistencias. |
| **Backend & API** | FastAPI (Python), Uvicorn | Orquestación veloz asíncrona y endpoint securizados (Bcrypt). |
| **BBDD & GeoQueries**| MongoDB Atlas (jsonSchema & `2dsphere`) | Álgebra espacial documental (Point / Coordenadas). |
| **Ingeniería ETL** | Pandas, BeautifulSoup, Python | Extraer gigas de hojas `.xlsx` gubernamentales para la IA. |
| **Data Analytics (AI)**| Scikit-learn (`DBSCAN`) | Aprendizaje Automático para detección de concentraciones criminales. |
| **Notificaciones** | Firebase Cloud Messaging (FCM API v1) | Tráfico de alertas Push remotas globales a iOS/Android. |

---

*Desarrollado integralmente para neutralizar la inseguridad explotando redes ciudadanas participativas, minería de datos oficial y avanzados modelos de predicción espacial.*
