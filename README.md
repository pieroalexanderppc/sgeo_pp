# 📱 SGEO — Sistema de Geolocalización de Inseguridad Ciudadana

Aplicación móvil híbrida orientada a la participación ciudadana y la acción policial estratégica en la región de **Tacna, Perú**. Su objetivo es registrar, visualizar, predecir y alertar sobre zonas de inseguridad en tiempo real combinando reportes comunitarios, datos gubernamentales oficiales (SIDPOL / Unidad de Flagrancia) y un motor de Inteligencia Artificial de Machine Learning Espacial y Predictivo.

---

## 🎨 Sistema de Diseño: Premium Tactical Dark

Toda la aplicación (Frontend) está construida rigurosamente bajo el sistema de diseño nativo **Premium Tactical Dark**. Esta estética prioriza interfaces *glassmórficas*, sombras dinámicas, modales tácticos y componentes reutilizables (`SafetyLayout`, `SafetyCard`, `SafetyButton`) para asegurar que el sistema no solo sea altamente funcional sino inmersivo, visualmente impresionante y moderno para cualquiera de los tres roles.

---

## 📂 Arquitectura Completa del Repositorio

El sistema está estructurado bajo una arquitectura de microservicios con interfaces modulares, separando estrictamente el **Frontend** (App Híbrida Flutter) del **Backend** (API Inteligente Python).

```text
📦 SGEO_PP/
├── 📱 lib/                                      # Frontend: App Híbrida (Flutter/Dart)
│   ├── main.dart                                # Punto de entrada, routing inteligente por roles, Firebase y notificaciones
│   ├── firebase_options.dart                    # Configuración generada por FlutterFire CLI
│   │
│   ├── core/                                    # Núcleo compartido
│   │   ├── services/                            # Servicios lógicos (Auth, Mapas, Geocercas, Reportes, Notificaciones, Tutorial)
│   │   ├── models/                              # Modelos tipados
│   │   └── widgets/                             # Sistema Maestro "Premium Tactical Dark" (SafetyLayout, SafetyCard, etc.)
│   │
│   ├── features/                                # Módulos transversales (independientes de rol)
│   │   └── auth/views/
│   │       ├── login_view.dart                  # Pantalla de inicio de sesión
│   │       └── register_view.dart               # Pantalla de registro de nuevo usuario
│   │
│   └── roles/                                   # Arquitectura Basada en Roles (RBAC 100% Independiente)
│       ├── user/                                # 👤 Rol: Ciudadano
│       │   ├── home/views/home_view.dart        #   → Shell principal con BottomNavigationBar
│       │   ├── map/views/map_view.dart          #   → Mapa interactivo y creación de reportes
│       │   ├── news/views/news_view.dart        #   → Feed de noticias de seguridad RSS/XML
│       │   ├── notifications/views/             #   → Bandeja de notificaciones locales
│       │   ├── reports/views/my_reports_view.dart  # → Historial de reportes propios
│       │   └── profile/views/profile_view.dart  #   → Perfil nativo ciudadano
│       │
│       ├── police/                              # 👮 Rol: Policía
│       │   ├── home/views/home_view.dart        #   → Shell principal policial
│       │   ├── map/views/map_view.dart          #   → Mapa policial táctico (perímetro 3km)
│       │   ├── validations/views/               #   → Panel de validación de reportes
│       │   └── profile/views/profile_view.dart  #   → Perfil nativo policial
│       │
│       └── admin/                               # 🛡️ Rol: Administrador
│           ├── home/views/home_view.dart        #   → Shell principal táctico
│           ├── dashboard/views/dashboard_view.dart  # → Dashboard Analítico con fl_chart (Dual Tab: Vivo / Big Data SIDPOL)
│           ├── users/views/users_manage_view.dart   # → Gestión gráfica de usuarios por rol
│           └── profile/views/profile_view.dart  #   → Perfil nativo administrativo
│
├── 🧠 backend/                                  # Backend: Servidor Inteligente (Python + FastAPI)
│   ├── main.py                                  # API RESTful central: auth, reportes, mapas, usuarios, IA Predictiva
│   ├── motor_ia_espacial.py                     # Motor ML Espacial: DBSCAN + fusión SIDPOL/Flagrancia
│   ├── firebase_service.py                      # Servicio FCM: Push Notifications con Admin SDK
│   ├── requirements.txt                         # Dependencias Python (FastAPI, Scikit-Learn, Pandas)
│   ├── Procfile                                 # Despliegue en Railway
│   └── scripts_iniciales/                       # Scripts de Ingeniería de Datos (ETL)
│       ├── setup_db.py                          #   → Creación de colecciones MongoDB
│       ├── importador_mensual.py                #   → Scraping SIDPOL + Flagrancia
│       └── importador_data.py                   #   → Migración masiva SIDPOL 2018-2026
│
├── 📄 docs/
│   └── SCRUM.md                                 # Documentación ágil: Product Backlog, Sprints
│
├── ⚙️ pubspec.yaml                              # Dependencias Flutter (fl_chart, flutter_map, etc.)
└── 📁 android/ ios/ build/                      # Configuraciones de compilación nativa
```

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
└── alertas                     # Registro de alertas del sistema
```

---

## 🔌 Endpoints de la API RESTful

| Método | Ruta | Responsabilidad |
|--------|------|-----------------|
| `POST` | `/api/auth/login` | Autenticación con verificación bcrypt |
| `POST` | `/api/auth/register` | Registro con validación de email y nombre |
| `GET` | `/api/map/zonas_riesgo` | Zonas de riesgo calculadas por la IA |
| `GET` | `/api/map/puntos_exactos` | Reportes confirmados para el mapa |
| `POST` | `/api/map/generar_zonas_ia` | Trigger manual del motor de IA DBSCAN |
| `POST` | `/api/reportes` | Crear reporte ciudadano (límite: 5/día) |
| `POST` | `/api/reportes/confirmar/{id}` | Policía confirma → agrupa cercanos 500m → Push FCM → Trigger IA |
| `POST` | `/api/reportes/rechazar/{id}` | Policía rechaza reporte falso |
| `GET` | `/api/reportes/mis_reportes/{user_id}` | Historial del ciudadano |
| `GET` | `/api/admin/dashboard_stats` | Métricas en vivo de reportes de la app |
| `GET` | `/api/admin/sidpol_stats` | Métricas BigData SIDPOL: Top Distritos, Tipos y cronología |
| `GET` | `/api/admin/sidpol_predict` | **Predicción ML (Regresión Lineal):** Proyecciones a 3 meses y riesgo |

---

## 📋 Módulos y Funcionalidades Clave

### 🧠 Inteligencia Artificial (Doble Motor: Espacial y Predictivo)

El sistema emplea inteligencia artificial en dos frentes distintos:

1. **Machine Learning Espacial (DBSCAN) - Análisis Micro:**  
   Aplicado sobre los incidentes en vivo de la aplicación usando `scikit-learn` (métrica haversine con `ball_tree`). Detecta clústeres geográficos de reportes confirmados y define radios dinámicos (150-400 metros) catalogados como zonas rojas.

2. **Machine Learning Predictivo (Linear Regression) - Análisis Macro:**  
   Implementado en el rol de Administrador. Procesa la colección masiva de SIDPOL Histórico empleando `pandas` y `LinearRegression`. Emite predicciones precisas sobre cuántos crímenes sucederán en los próximos tres meses y detecta de manera automatizada cuál distrito experimentará el mayor aumento de riesgo inminente.

### 🛡️ Geocercas (Geofencing) y Monitoreo GPS Silencioso

- **Rastreo en Background:** El servicio `GeofenceService` monitoriza la posición del usuario cada 50 metros mediante `Geolocator`.
- **Cálculo de Proximidad:** Evalúa constantemente la distancia hacia las zonas rojas de la IA.
- **Alarma Preventiva:** Si se cruza una zona roja, dispara una notificación local inmediata (vibración + sonido).

### 🚨 Sistema Multirrol (RBAC Estricto — 3 Roles)

| Rol | Funcionalidades |
|-----|-----------------|
| **Ciudadano** | Crear denuncias con GPS, ver mapas de riesgo, feed de noticias de seguridad RSS, historial propio. |
| **Policía** | Panel de validación táctica. Confirmar o rechazar incidentes de la comunidad, visualizando alertas en un perímetro local de 3km. |
| **Administrador** | Dashboard de doble pestaña (*App en vivo* vs *Big Data SIDPOL*). Panel gráfico interactivo con `fl_chart`. Predicciones IA a futuro. Administración de usuarios y suspensión de cuentas. |

### 📡 Notificaciones Push (FCM)
- Backend utiliza Firebase Admin SDK para mandar alertas (Topic: `alertas_ciudadanos`).
- Persistencia local en buzón interno para ver notificaciones pasadas, implementando navegación automática al punto exacto del robo.

### 🔄 Pipeline ETL Automatizado (Extracción de Datos)
Scripts (`importador_mensual.py`, `importador_data.py`) ejecutan tareas Cron para visitar fuentes gubernamentales (Policía del Perú y Unidad de Flagrancia), raspar, limpiar mediante pandas e inyectar data en la MongoDB.

---

## 🛠️ Stack Tecnológico Completo

| Capa | Herramientas | Versión / Detalle |
|------|-------------|-------------------|
| **Frontend Móvil** | Flutter (Dart) | SDK `^3.11.3` |
| **Analítica Visual** | fl_chart, flutter_animate | Gráficos e interfaces interactivas Premium |
| **Mapas & GPS** | flutter_map, Geolocator | Capas OSM e integración latlong2 |
| **Backend API** | FastAPI (Python 3.11), Uvicorn | Async, BackgroundTasks, Servidor ultra rápido |
| **Base de Datos** | MongoDB Atlas (PyMongo) | Esquemas validados, índices geoespaciales 2dsphere |
| **Machine Learning**| Scikit-Learn | DBSCAN (Espacial) y Regresión Lineal (Predictiva) |
| **Minería de Datos**| Pandas, NumPy, BeautifulSoup | Web Scraping y manipulación masiva de Excel/CSV |
| **Notificaciones** | FCM, Firebase Admin | Notificaciones en Background y Foreground |

---

## ⚡ Inicio Rápido

### Requisitos Previos
- Flutter SDK `^3.11.3`
- Python `3.11.x`
- MongoDB Atlas (o instancia local)
- Firebase con FCM habilitado

### Ejecución Local de Flutter
```bash
flutter clean
flutter pub get
flutter run
```

### 📦 Generación de Instaladores a Producción
```bash
# 1. Android - Generar APK Estándar (Pruebas)
flutter build apk

# 2. Android - Generar App Bundle (Obligatorio para subir a la Play Store)
flutter build appbundle

# 3. iOS - Generar archivo IPA (Requiere exclusivamente Mac y Xcode)
flutter build ipa
```

### Ejecución Local del Backend (FastAPI)
```bash
cd backend
python -m venv venv
venv\Scripts\activate        # En Windows
pip install -r requirements.txt
python scripts_iniciales/setup_db.py  # (Solo primera vez)
uvicorn main:app --reload
```

---

## 📐 Metodología de Desarrollo

El proyecto se gestiona bajo el marco ágil **SCRUM** con Product Backlog, Épicas e Historias de Usuario documentadas en `docs/SCRUM.md`. Se organizan Sprints iterativos enfocados en validación temprana, análisis de datos y robustez arquitectónica.

---

*Desarrollado integralmente para neutralizar la inseguridad ciudadana explotando redes participativas, minería de datos gubernamentales oficiales y modelos avanzados de predicción espacial y algorítmica.*
