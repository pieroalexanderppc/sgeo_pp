# 📱 SGEO — Sistema de Geolocalización de Inseguridad Ciudadana

Aplicación móvil híbrida orientada a la participación ciudadana y la acción policial estratégica en la región de **Tacna, Perú**. Su objetivo es registrar, visualizar, predecir y alertar sobre zonas de inseguridad en tiempo real combinando reportes comunitarios, datos gubernamentales oficiales (SIDPOL / Unidad de Flagrancia) y un motor de Inteligencia Artificial de Machine Learning Espacial (DBSCAN).

---

## 📂 Arquitectura Completa del Repositorio

El sistema está estructurado bajo una arquitectura de microservicios con interfaces modulares, separando estrictamente el **Frontend** (App Híbrida Flutter) del **Backend** (API Inteligente Python).

```
📦 SGEO_PP/
├── 📱 lib/                                      # Frontend: App Híbrida (Flutter/Dart)
│   ├── main.dart                                # Punto de entrada, inicialización Firebase, FCM, notificaciones y routing por rol
│   ├── firebase_options.dart                    # Configuración generada por FlutterFire CLI (Android)
│   │
│   ├── core/                                    # Núcleo compartido de la aplicación
│   │   ├── services/                            # Capa de servicios lógicos (6 archivos):
│   │   │   ├── auth_service.dart                #   → Autenticación: login, registro, logout, persistencia de sesión
│   │   │   ├── map_service.dart                 #   → Comunicación con API de mapas, caché con TTL de 15 min, concurrencia controlada
│   │   │   ├── geofence_service.dart            #   → Geocercas: rastreo GPS en background, cálculo de proximidad, alertas locales
│   │   │   ├── report_service.dart              #   → CRUD de reportes del ciudadano (mis reportes, eliminar pendientes)
│   │   │   ├── notifications_storage_service.dart  # → Persistencia offline de notificaciones (SharedPreferences + ValueNotifier)
│   │   │   └── tutorial_service.dart            #   → Sistema de tutorial interactivo guiado (ShowcaseView)
│   │   ├── models/
│   │   │   └── report_model.dart                # Modelo tipado de reporte con parsing GeoJSON → Dart
│   │   └── theme/
│   │       └── app_theme.dart                   # Sistema dual de temas (Light/Dark) con Material 3 y Google Fonts Poppins
│   │
│   ├── features/                                # Módulos transversales (independientes de rol)
│   │   └── auth/views/
│   │       ├── login_view.dart                  # Pantalla de inicio de sesión
│   │       └── register_view.dart               # Pantalla de registro de nuevo usuario
│   │
│   └── roles/                                   # Arquitectura Basada en Roles (RBAC)
│       ├── user/                                # 👤 Rol: Ciudadano
│       │   ├── home/views/home_view.dart        #   → Shell principal con BottomNavigationBar (4 pestañas)
│       │   ├── map/views/
│       │   │   ├── map_view.dart                #   → Mapa interactivo: zonas de riesgo, puntos confirmados, geolocalización
│       │   │   └── widgets/report_dialog.dart   #   → Diálogo modal para crear reportes con selección de tipo, modalidad y relación
│       │   ├── news/views/news_view.dart        #   → Feed de noticias de seguridad con scraping RSS/XML en tiempo real
│       │   ├── notifications/views/             #   → Bandeja de notificaciones locales (inbox persistente)
│       │   ├── reports/views/my_reports_view.dart  # → Historial de reportes propios con estados y acciones
│       │   └── profile/views/profile_view.dart  #   → Perfil: editar datos, toggle tema, tutorial, cerrar sesión
│       │
│       ├── police/                              # 👮 Rol: Policía
│       │   ├── home/views/home_view.dart        #   → Shell principal con BottomNavigationBar (3 pestañas)
│       │   ├── map/views/map_view.dart          #   → Mapa policial: reportes pendientes + confirmados, confirmar/rechazar en mapa
│       │   ├── validations/views/               #   → Panel de validación masiva de reportes ciudadanos (listado)
│       │   └── profile/views/profile_view.dart  #   → Perfil policial: datos, configuración de tema
│       │
│       └── admin/                               # 🛡️ Rol: Administrador
│           ├── home/views/home_view.dart        #   → Shell principal con BottomNavigationBar (3 pestañas)
│           ├── dashboard/views/dashboard_view.dart  # → Dashboard con métricas del sistema
│           ├── users/views/users_manage_view.dart   # → Gestión de usuarios: activar, desactivar, administrar cuentas
│           └── profile/views/profile_view.dart  #   → Perfil administrativo
│
├── 🧠 backend/                                  # Backend: Servidor Inteligente (Python + FastAPI)
│   ├── main.py                                  # API RESTful central (520 líneas): auth, reportes, mapas, usuarios, IA
│   ├── motor_ia_espacial.py                     # Motor de ML Espacial: DBSCAN + fusión SIDPOL/Flagrancia (2 fases)
│   ├── firebase_service.py                      # Servicio FCM: Push Notifications con Admin SDK (topics + coordenadas)
│   ├── requirements.txt                         # 14 dependencias Python de producción
│   ├── runtime.txt                              # Runtime: Python 3.11.x
│   ├── Procfile                                 # Despliegue: uvicorn main:app --host 0.0.0.0 --port $PORT
│   ├── .env                                     # Variables de entorno (MONGO_URL, credenciales — no versionado)
│   └── scripts_iniciales/                       # Scripts de Ingeniería de Datos (ETL)
│       ├── setup_db.py                          #   → Creación de 7 colecciones MongoDB con jsonSchema + índices 2dsphere + usuarios seed
│       ├── importador_mensual.py                #   → Cron Job mensual: Web Scraping SIDPOL (gob.pe) + Flagrancia (csjtacna.exgperu.com)
│       └── importador_data.py                   #   → Migración histórica masiva SIDPOL 2018-2026 (limpieza Pandas multi-hoja)
│
├── 📄 docs/
│   └── SCRUM.md                                 # Documentación ágil: Product Backlog, Épicas, Historias de Usuario, Sprints
│
├── ⚙️ pubspec.yaml                              # Dependencias Flutter (12 paquetes principales)
├── ⚙️ firebase.json                             # Configuración Firebase ↔ Flutter (proyecto sgeo-7e191)
├── ⚙️ analysis_options.yaml                     # Reglas de análisis estático de Dart
├── ⚙️ .gitignore                                # Exclusiones de seguridad (.env, firebase-adminsdk.json, __pycache__)
├── 📁 android/                                  # Configuraciones nativas Android (Gradle, Manifest, google-services.json)
├── 📁 ios/                                      # Configuraciones nativas iOS (Xcode, Info.plist)
└── 📁 build/                                    # Directorio temporal de compilación (no versionado)
```

**Conteo del proyecto:** 15 archivos Dart en el frontend, 6 archivos Python en el backend, ~35 archivos fuente totales.

---

## 🚀 Arquitectura y Despliegue en Producción

El sistema opera bajo una arquitectura de **Nube Integrada (Cloud Computing)** con los siguientes componentes:

| Componente | Plataforma | Detalle |
|---|---|---|
| **API RESTful** | Railway | `https://sgeo-backend-production.up.railway.app` — FastAPI + Uvicorn |
| **Base de Datos** | MongoDB Atlas | Cluster `geocrimen_tacna` con 7 colecciones y índices `2dsphere` |
| **Notificaciones Push** | Firebase Cloud Messaging | Proyecto `sgeo-7e191`, topic `alertas_ciudadanos` |
| **ETL Automático** | Railway Cron | Scripts de scraping mensual (SIDPOL + Flagrancia) |

### Esquema de Base de Datos MongoDB (7 Colecciones)

```
geocrimen_tacna/
├── usuarios                    # Cuentas con rol (ciudadano|policia|admin), bcrypt hash, estado activo
├── reportes_ciudadano          # Denuncias ciudadanas con GeoJSON Point, estado (pendiente|confirmado|rechazado|agrupado)
├── incidentes                  # Incidentes verificados geolocalizados (fuente: ciudadano|policia|sidpol)
├── estadisticas_sidpol         # Datos mensuales importados de SIDPOL (Ministerio del Interior)
├── estadisticas_flagrancia     # Datos mensuales importados de Unidad de Flagrancia (Corte Superior Tacna)
├── estadisticas_sidpol_historico  # Acumulado histórico SIDPOL 2018-2026
├── zonas_riesgo                # Zonas calculadas por la IA: centroide GeoJSON, radio, nivel_riesgo, tendencia
└── alertas                     # Registro de alertas del sistema (nuevo_incidente|zona_peligrosa|zona_actualizada)
```

---

## 🔌 Endpoints de la API RESTful

| Método | Ruta | Responsabilidad |
|--------|------|-----------------|
| `POST` | `/api/auth/login` | Autenticación con verificación bcrypt |
| `POST` | `/api/auth/register` | Registro con validación de email y nombre únicos |
| `GET` | `/api/map/zonas_riesgo` | Zonas de riesgo calculadas por la IA (caché 10 min en servidor) |
| `GET` | `/api/map/puntos_exactos` | Reportes confirmados para el mapa ciudadano |
| `POST` | `/api/map/generar_zonas_ia` | Trigger manual del motor de IA (BackgroundTasks) |
| `POST` | `/api/reportes` | Crear reporte ciudadano (límite: 5/día por usuario) |
| `POST` | `/api/reportes/confirmar/{id}` | Policía confirma → agrupa cercanos 500m → Push FCM → recalcula IA |
| `POST` | `/api/reportes/rechazar/{id}` | Policía rechaza → agrupa rechazados cercanos 500m |
| `GET` | `/api/reportes/mis_reportes/{user_id}` | Historial de reportes del ciudadano autenticado |
| `DELETE` | `/api/reportes/{id}` | Eliminar reporte propio (solo si está pendiente) |
| `GET` | `/api/reportes/policia` | Todos los reportes pendientes + confirmados (vista policial) |
| `GET` | `/api/usuarios/{user_id}` | Obtener perfil del usuario |
| `PUT` | `/api/usuarios/{user_id}` | Actualizar nombre, email y teléfono |

---

## 📋 Módulos y Funcionalidades Clave

### 🧠 Inteligencia Artificial Espacial (Motor de 2 Fases)

El archivo `motor_ia_espacial.py` ejecuta un análisis híbrido dividido en dos fases complementarias:

- **FASE 1 — Análisis MACRO (Estadísticas Gubernamentales):**  
  Procesa los datos importados de SIDPOL y Unidad de Flagrancia, agrupando por distrito de Tacna. Calcula la moda estadística del delito predominante y asigna niveles de riesgo (`bajo`, `medio`, `alto`, `crítico`) según umbrales de incidencia acumulada. Genera zonas con radios adaptativos de **1–2+ km**.

- **FASE 2 — Análisis MICRO (Machine Learning DBSCAN):**  
  Aplica el algoritmo **DBSCAN** (Scikit-Learn) sobre los incidentes geolocalizados de la app usando la métrica **haversine** con `ball_tree`. Configuración: `epsilon ≈ 400 metros`, `min_samples = 3`. Los clústeres detectados generan **Hotspots** con radios de **150–400 metros**, nivel de riesgo proporcional y tendencia `subiendo`.

- **Fusión de Resultados:** Ambas fases se almacenan unificadas en la colección `zonas_riesgo` y disparan automáticamente una notificación push de actualización de mapa a todos los dispositivos.

### 🛡️ Geocercas (Geofencing) y Monitoreo GPS Silencioso

- **Rastreo en Background:** El servicio `GeofenceService` monitoriza la posición del usuario cada 50 metros mediante `Geolocator.getPositionStream()` sin necesidad de tener la app abierta.
- **Cálculo de Proximidad:** Evalúa la distancia entre la posición actual y cada centroide de zona de riesgo usando `Geolocator.distanceBetween()`.
- **Alarma Preventiva:** Si el usuario cruza el radio de una zona roja, se dispara una notificación local (vibración + sonido) con un **cooldown de 15 minutos** entre alertas.
- **Persistencia:** Las alertas de geocerca se almacenan en la bandeja de notificaciones local con el mismo formato que las notificaciones push de Firebase.

### 🚨 Sistema Multirrol (RBAC — 3 Roles)

| Rol | Módulos | Funcionalidades |
|-----|---------|-----------------|
| **Ciudadano** (`roles/user/`) | Mapa, Reportes, Noticias, Notificaciones, Perfil | Crear denuncias con GPS, ver zonas de riesgo, feed de noticias RSS, historial de reportes, tutorial interactivo |
| **Policía** (`roles/police/`) | Mapa Policial, Validaciones, Perfil | Ver todos los reportes (pendientes + confirmados), confirmar/rechazar incidentes, trigger de IA automático |
| **Administrador** (`roles/admin/`) | Dashboard, Gestión de Usuarios, Perfil | Métricas del sistema, activar/desactivar cuentas de usuario, administración general |

### 📡 Notificaciones Push (Firebase Cloud Messaging)

- **Backend → Dispositivos:** `firebase_service.py` envía notificaciones masivas por **topic** (`alertas_ciudadanos`) con payload personalizado (`type: incident|update|risk_zone`) y coordenadas GPS opcionales.
- **Credenciales Duales:** El servicio detecta automáticamente si ejecutar con variable de entorno (Railway) o archivo local (`sgeo-firebase-adminsdk.json`).
- **Routing Inteligente en Flutter:** Al tocar una notificación, `main.dart` redirige según el `type`:
  - `update` → Limpia caché del mapa + abre la bandeja de notificaciones.
  - `incident` → Navega al mapa centrado en las coordenadas del incidente.
- **Persistencia Offline:** `NotificationsStorageService` guarda cada notificación en `SharedPreferences` formando un inbox local con estados de lectura.

### 📰 Feed de Noticias de Seguridad

El módulo `news_view.dart` implementa un lector de noticias en tiempo real que consume feeds RSS/XML de fuentes oficiales de seguridad, con renderizado inline y diseño responsivo.

### 🎨 Sistema de Temas (Light / Dark Mode)

- Implementado con `ValueNotifier<ThemeMode>` en `AppTheme` para cambio reactivo sin reinicio.
- **Material 3** con paleta personalizada y tipografía **Google Fonts Poppins**.
- Toggle accesible desde el perfil de cualquier rol.

### 🔄 Pipeline ETL Automatizado

| Script | Fuente | Frecuencia | Proceso |
|--------|--------|------------|---------|
| `importador_mensual.py` | SIDPOL (gob.pe) + Flagrancia (csjtacna) | Mensual (Cron) | Scraping → Descarga .xlsx/.xls → Filtrado Pandas (Tacna + Delitos Patrimoniales) → MongoDB |
| `importador_data.py` | SIDPOL Histórico | Una vez | Extracción multi-hoja 2018-2026 → Limpieza adaptativa de formatos antiguos → MongoDB |
| `setup_db.py` | — | Inicial | Crea 7 colecciones con validadores jsonSchema, índices 2dsphere, índices compuestos únicos y 3 usuarios semilla |

---

## 🛠️ Stack Tecnológico Completo

| Capa | Herramientas | Versión / Detalle |
|------|-------------|-------------------|
| **Frontend Móvil** | Flutter (Dart), Material 3 | SDK `^3.11.3` · 12 dependencias pub |
| **Mapas** | flutter_map + OpenStreetMap (Tiles) | latlong2 para coordenadas |
| **Geolocalización** | Geolocator | Alta precisión, distanceFilter: 50m |
| **UI/UX** | Google Fonts (Poppins), flutter_animate, sliding_up_panel, Lottie, ShowcaseView | Animaciones, paneles deslizantes, tutoriales interactivos |
| **Persistencia Local** | SharedPreferences | Sesión, notificaciones offline, tutoriales |
| **Backend API** | FastAPI (Python 3.11), Uvicorn | Async, BackgroundTasks, Pydantic v2 con EmailStr |
| **Base de Datos** | MongoDB Atlas (PyMongo) | jsonSchema validators, índices `2dsphere` y compuestos únicos |
| **Seguridad** | bcrypt | Hash de contraseñas con salt |
| **Machine Learning** | Scikit-Learn (DBSCAN) | Métrica haversine, ball_tree, clustering geoespacial |
| **Ingeniería de Datos** | Pandas, NumPy, OpenPyXL, lxml | ETL de archivos .xlsx gubernamentales |
| **Web Scraping** | BeautifulSoup4, Requests | Extracción automática de URLs de descarga de SIDPOL y Flagrancia |
| **Notificaciones** | Firebase Cloud Messaging (FCM API v1), Firebase Admin SDK | Push masivo por topic + notificaciones locales |
| **Deploy** | Railway (Backend), Firebase (Messaging) | Procfile + variables de entorno |

---

## ⚡ Inicio Rápido

### Requisitos Previos
- Flutter SDK `^3.11.3`
- Python `3.11.x`
- MongoDB Atlas (o instancia local)
- Cuenta Firebase con FCM habilitado

### Frontend (Flutter)
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo/emulador
flutter run
```

### Backend (FastAPI)
```bash
cd backend

# Crear entorno virtual
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Linux/Mac

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
# Crear archivo .env con: MONGO_URL=<tu_cadena_de_conexión>

# Inicializar base de datos (primera vez)
python scripts_iniciales/setup_db.py

# Importar data histórica (primera vez)
python scripts_iniciales/importador_data.py

# Iniciar servidor
uvicorn main:app --reload
```

---

## 📐 Metodología de Desarrollo

El proyecto se gestiona bajo el marco ágil **SCRUM** con Product Backlog, Épicas e Historias de Usuario documentadas en [`docs/SCRUM.md`](docs/SCRUM.md). Se organizan Sprints iterativos enfocados en:

1. **Sprint 1** *(Completado):* Localización GPS, UX de reportes, conexión Backend.
2. **Sprint 2** *(En progreso):* Autenticación completa, carga masiva SIDPOL, visualización de mapa de calor IA.

---

*Desarrollado integralmente para neutralizar la inseguridad ciudadana explotando redes participativas, minería de datos gubernamentales oficiales y modelos avanzados de predicción espacial.*
