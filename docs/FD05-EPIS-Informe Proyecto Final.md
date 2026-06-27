![Logo UPT](media/image1.png)

**UNIVERSIDAD PRIVADA DE TACNA**  
**FACULTAD DE INGENIERÍA**  
**Escuela Profesional de Ingeniería de Sistemas**  

**Proyecto: "SGEO — Sistema de Geolocalización de Inseguridad Ciudadana con Machine Learning Predictivo y Espacial"**  

**Curso:** Construcción De Software II  
**Docente:** Alberto Johnatan Flor Rodriguez  

**Integrante:**  
- Piero Alexander Paja de la Cruz (2020067576)

**Tacna -- Perú**  
**2026**  

---

**Documento Informe de Proyecto Final**  
**Versión:** 1.0  

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha      | Motivo           |
|---------|-----------|--------------|--------------|------------|------------------|
| 1.0     | PP        | PP           | AF           | 06/06/2026 | Versión Original |

---

## ÍNDICE GENERAL

1. [Antecedentes](#1-antecedentes)
2. [Planteamiento del Problema](#2-planteamiento-del-problema)
   - 2.1. [Problema General](#21-problema-general)
   - 2.2. [Problemas Específicos](#22-problemas-específicos)
   - 2.3. [Alcance](#23-alcance)
3. [Objetivos](#3-objetivos)
   - 3.1. [Objetivo General](#31-objetivo-general)
   - 3.2. [Objetivos Específicos](#32-objetivos-específicos)
4. [Marco Teórico](#4-marco-teórico)
5. [Desarrollo de la Solución](#5-desarrollo-de-la-solución)
   - 5.1. [Arquitectura General](#51-arquitectura-general)
   - 5.2. [Componentes Implementados](#52-componentes-implementados)
   - 5.3. [Metodología de Implementación](#53-metodología-de-implementación)
   - 5.4. [Tecnologías Utilizadas](#54-tecnologías-utilizadas)
   - 5.5. [Resultados Obtenidos](#55-resultados-obtenidos)
6. [Cronograma](#6-cronograma)
7. [Presupuesto](#7-presupuesto)
8. [Conclusiones](#8-conclusiones)
9. [Recomendaciones](#9-recomendaciones)
10. [Bibliografía](#10-bibliografía)

---

# 1. Antecedentes

La inseguridad ciudadana constituye uno de los principales problemas sociales de la región de Tacna, Perú. Según los datos históricos del Sistema de Información Policial (SIDPOL) y la Unidad de Flagrancia del Ministerio Público de la región, el volumen de incidentes criminales registrados entre 2018 y 2026 refleja un patrón sostenido de actividad delictiva distribuida geográficamente de manera heterogénea en los diferentes distritos de la ciudad.

A nivel tecnológico, diversas ciudades del mundo han adoptado soluciones de inteligencia artificial y geolocalización para la prevención del crimen. Iniciativas como PredPol (actualmente Geolitica) en Estados Unidos, la plataforma ShotSpotter, y los sistemas de predicción de la Policía Metropolitana del Reino Unido, demuestran la viabilidad técnica de los enfoques basados en Machine Learning para la optimización del patrullaje preventivo. Sin embargo, estas soluciones propietarias no son accesibles para municipalidades de países en vías de desarrollo.

En el ámbito académico nacional, los trabajos de investigación sobre sistemas de geolocalización criminal en el Perú han sido mayoritariamente teóricos o de alcance reducido, sin llegar a implementaciones funcionales que integren reportes comunitarios en tiempo real, validación policial oficial y algoritmos de clustering espacial sobre datos históricos masivos del Estado Peruano.

El proyecto SGEO surge como respuesta a esta brecha tecnológica, proponiendo e implementando una solución completa, de código abierto y adaptada a la realidad socioeconómica de Tacna, que combina inteligencia artificial, participación ciudadana colaborativa y datos oficiales del SIDPOL en una plataforma móvil accesible para la ciudadanía, las unidades policiales y los administradores de seguridad.

---

# 2. Planteamiento del Problema

## 2.1 Problema General

¿En qué medida el desarrollo e implementación de SGEO, un sistema de geolocalización de inseguridad ciudadana con Machine Learning predictivo y espacial, contribuye a la reducción de los tiempos de respuesta policial y al incremento de la capacidad de prevención civil en la región de Tacna durante el año 2026?

## 2.2 Problemas Específicos

- **PE-01:** ¿Cómo puede un algoritmo de clustering espacial DBSCAN, entrenado sobre el historial criminológico confirmado del SIDPOL 2018-2026, identificar y delimitar automáticamente las zonas geográficas de mayor concentración delictiva en Tacna?

- **PE-02:** ¿De qué manera un motor predictivo contextual basado en Regresión Lineal y análisis temporal puede generar proyecciones de riesgo por distrito, horario y turno que sean consultables en tiempo real por ciudadanos y autoridades a través de una API REST?

- **PE-03:** ¿Cómo un sistema de geofencing móvil basado en la detección GPS de ingreso a zonas DBSCAN puede emitir alertas preventivas locales contextualizadas al ciudadano sin requerir interacción activa del usuario?

- **PE-04:** ¿En qué medida la separación estricta de interfaces por rol (Ciudadano, Policía, Administrador) bajo un esquema RBAC garantiza la integridad del proceso de validación policial y previene la contaminación del historial analítico por reportes falsos?

## 2.3 Alcance

El sistema SGEO abarca el desarrollo, implementación y validación de los siguientes componentes:

**Alcance del Frontend (Flutter):**
- Interfaz del Ciudadano: mapa interactivo con zonas DBSCAN, Safety Score dinámico, creación de reportes geolocalizados, historial personal, noticias de seguridad, notificaciones push y geofencing automático.
- Interfaz del Policía: mapa táctico con reportes pendientes filtrados a radio de 3km, módulo de validación (confirmar/rechazar), mapa de puntos exactos confirmados.
- Interfaz del Administrador: dashboard analítico con estadísticas de reportes (por estado y tipo) mediante `fl_chart`, predicción de incidentes por distrito vía Regresión Lineal, gestión de usuarios del sistema.

**Alcance del Backend (FastAPI):**
- 6 módulos de rutas REST: autenticación, reportes ciudadanos, mapas geoespaciales, motor predictivo (5 endpoints), gestión de usuarios, administración.
- Motor espacial DBSCAN ejecutado en hilo daemon al inicio y como BackgroundTask tras confirmación policial.
- Motor predictivo contextual con 4 clases: SafetyScoreCalculator, TemporalAnalyzer, InsightGenerator, SafeHoursCalculator.
- Integración con Firebase Cloud Messaging para notificaciones push masivas.

**Alcance de la Base de Datos (MongoDB Atlas):**
- Base `geocrimen_tacna` con 4 colecciones: `usuarios`, `reportes_ciudadano`, `historial_delitos`, `zonas_riesgo`.
- Índices geoespaciales `2dsphere` para consultas `$nearSphere` en tiempo sub-250ms.

**Alcance del ETL:**
- Importación del historial criminológico SIDPOL 2018-2026 (~3.4 MB de datos ArcGIS) mediante scripts `extract_arcgis_data.py` e `import_arcgis_data.py`.

**Fuera del alcance (Roadmap futuro):**
- Integración de videocámaras municipales en el mapa.
- Predicción multivariable mediante redes neuronales profundas (Deep Learning).
- Panel web administrativo independiente.

---

# 3. Objetivos

## 3.1 Objetivo General

Desarrollar e implementar un sistema inteligente de geolocalización de inseguridad ciudadana (SGEO) que integre reportes comunitarios en tiempo real, validación policial oficial, análisis geoespacial mediante DBSCAN, predicción temporal mediante Regresión Lineal y alertas preventivas automáticas vía Firebase Cloud Messaging, con el fin de reducir los tiempos de respuesta policial y aumentar la capacidad de prevención civil en la región de Tacna.

## 3.2 Objetivos Específicos

- **OE-01:** Implementar el motor de clustering espacial DBSCAN con parámetros geoespaciales (`epsilon=150m`, `min_samples=5`, `algorithm='ball_tree'`, `metric='haversine'`) capaz de procesar el historial de incidentes confirmados y generar automáticamente zonas de riesgo con niveles (bajo/medio/alto/crítico) y radios dinámicos (150m–350m).

- **OE-02:** Desarrollar el motor predictivo contextual (`predictive_context_engine.py`) con cuatro componentes funcionales: `SafetyScoreCalculator` (score 0-100 con 4 factores), `TemporalAnalyzer` (distribución por hora/día/turno y tendencia), `InsightGenerator` (hasta 6 recomendaciones contextuales por ubicación) y `SafeHoursCalculator` (franjas horarias seguras estadísticas).

- **OE-03:** Construir el servicio de geofencing móvil (`GeofenceService`) que realice seguimiento GPS continuo con `distanceFilter=50m`, detecte el ingreso a zonas DBSCAN y emita alertas locales contextualizadas con información del turno horario, implementando un mecanismo de cooldown de 30 minutos para evitar saturación de notificaciones.

- **OE-04:** Diseñar e implementar tres interfaces de usuario nativas diferenciadas en Flutter bajo el sistema visual "Premium Tactical Dark", con enrutamiento dinámico estricto basado en el atributo `rol` autenticado, garantizando que únicamente los usuarios con rol `policia` puedan confirmar o rechazar reportes, y que solo los reportes confirmados alimenten el historial analítico del sistema.

- **OE-05:** Desplegar el backend FastAPI en Railway PaaS con inicio automático vía Procfile, y la base de datos MongoDB Atlas con replica set y failover automático, garantizando una disponibilidad operativa del sistema superior al 99.8% mensual.

---

# 4. Marco Teórico

## 4.1 Algoritmo DBSCAN (Density-Based Spatial Clustering of Applications with Noise)

DBSCAN es un algoritmo de clustering no paramétrico propuesto por Ester et al. (1996) que agrupa puntos en función de su densidad espacial. A diferencia de K-Means, no requiere especificar el número de clústeres a priori, lo que lo hace idóneo para entornos criminológicos donde la distribución de delitos es desconocida e irregular.

Sus parámetros fundamentales son:
- **epsilon (ε):** Radio máximo de vecindad para considerar dos puntos como vecinos. En SGEO se utiliza `epsilon = 0.15 / 6371.0` radianes, equivalente a 150 metros de distancia geográfica.
- **min_samples:** Número mínimo de puntos requeridos para formar un clúster denso. En SGEO se utiliza `min_samples=5`, lo que exige al menos 5 incidentes confirmados en un radio de 150m para declarar una zona de riesgo.
- **metric:** Función de distancia empleada. SGEO utiliza `metric='haversine'` para calcular distancias exactas sobre la superficie esférica de la Tierra.

Los puntos que no pertenecen a ningún clúster se clasifican como "ruido" y son excluidos del mapa de riesgo, evitando que reportes aislados generen falsas alarmas geográficas.

## 4.2 Regresión Lineal para Series Temporales Criminológicas

La Regresión Lineal Simple es un método estadístico que modela la relación entre una variable dependiente (número de incidentes) y una variable independiente numérica (índice temporal = año × 12 + mes). En SGEO se emplea para:

1. **Predicción global:** Proyectar el total de incidentes esperados para los próximos 3 meses a nivel de toda la ciudad.
2. **Predicción por distrito:** Identificar el distrito con mayor riesgo proyectado para el mes siguiente, permitiendo a los administradores policiales anticipar la concentración de recursos de patrullaje.
3. **Cálculo de tendencia:** Determinar si los incidentes en un área geográfica muestran tendencia ascendente, descendente o estable, mediante el análisis del coeficiente de pendiente (slope) del modelo.

## 4.3 Safety Score Contextual (0-100)

El Safety Score es una métrica escalar compuesta implementada en `SafetyScoreCalculator` que evalúa el nivel de seguridad de una ubicación en un momento dado. Se calcula mediante la multiplicación de cuatro factores independientes normalizados:

| Factor | Rango | Descripción |
|--------|-------|-------------|
| Proximidad a zonas DBSCAN | 0.3 – 1.0 | Penalización por distancia a hotspots críticos |
| Densidad de incidentes (radio 1km, últimos 90 días) | 0.4 – 1.0 | Penalización por densidad histórica reciente |
| Factor temporal (turno horario) | 0.7 – 1.0 | Mayor penalización en madrugada y noche |
| Tendencia distrital (3 meses) | 0.8 – 1.0 | Penalización adicional si tendencia es ascendente |

La interpretación del score resultante es: Seguro (≥80, verde), Precaución (50-79, amarillo), Alto Riesgo (<50, rojo).

## 4.4 Firebase Cloud Messaging (FCM)

FCM es el servicio de mensajería push de Google que permite el envío masivo de notificaciones a dispositivos Android e iOS de manera confiable y de baja latencia. SGEO utiliza:
- **Publicación por tópico:** El tópico `alertas_ciudadanos` permite enviar notificaciones a todos los dispositivos suscritos simultáneamente sin necesidad de gestionar tokens individuales.
- **Tipos de notificación:** `incident` (coordenadas GPS del incidente confirmado), `update` (recálculo de zonas DBSCAN), `risk_zone` (alerta local de geofencing).
- **Estados de la aplicación:** FCM gestiona la entrega de notificaciones en los tres estados posibles de la app Flutter: foreground (app abierta), background (app en segundo plano) y terminated (app cerrada).

## 4.5 Arquitectura REST y FastAPI

FastAPI es un framework web moderno para Python basado en el estándar ASGI (Asynchronous Server Gateway Interface), implementado sobre Uvicorn y Starlette. Sus características clave en SGEO:
- **Concurrencia asíncrona:** Mediante `async/await`, FastAPI despacha múltiples peticiones HTTP sin bloquear el Event Loop, garantizando tiempos de respuesta sub-400ms bajo carga concurrente.
- **BackgroundTasks:** Permite ejecutar tareas computacionalmente costosas (como el recálculo DBSCAN) en segundo plano sin bloquear la respuesta HTTP al cliente, mejorando la experiencia de usuario del policía que confirma un reporte.
- **Validación automática con Pydantic v2:** Garantiza la integridad tipológica de todos los datos de entrada y salida de la API, previniendo inyecciones NoSQL y errores de formato.

## 4.6 MongoDB y Consultas Geoespaciales

MongoDB es una base de datos NoSQL orientada a documentos que almacena datos en formato BSON (Binary JSON). Sus capacidades geoespaciales son fundamentales para SGEO:
- **Índices 2dsphere:** Permiten al motor de C++ de MongoDB resolver consultas de proximidad geográfica (`$nearSphere`, `$geoWithin`) con complejidad O(log n), sin delegar iteraciones matriciales a Python.
- **Formato GeoJSON:** Los campos `ubicacion` (reportes) y `centroide` (zonas de riesgo) almacenan coordenadas en el formato estándar `{"type": "Point", "coordinates": [lng, lat]}`.
- **Agregación con pipelines:** Los análisis temporales del `TemporalAnalyzer` utilizan MongoDB Aggregation Framework para calcular distribuciones por hora, día y mes directamente en el servidor de base de datos.

---

# 5. Desarrollo de la Solución

## 5.1 Arquitectura General

SGEO implementa una arquitectura Cliente-Servidor de N capas con integración de Inteligencia Artificial en el servidor, siguiendo el patrón 4+1 de Kruchten:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA CLIENTE (Flutter)                        │
│  ┌───────────────┐ ┌──────────────┐ ┌─────────────────────────┐ │
│  │  Ciudadano    │ │   Policía    │ │     Administrador       │ │
│  │ (6 módulos)   │ │ (4 módulos)  │ │    (4 módulos)          │ │
│  └───────────────┘ └──────────────┘ └─────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │         Core Services (7 servicios compartidos)              │ │
│  │ AuthService | GeofenceService | MapService | PredictiveService│ │
│  │ ReportService | NotificationsStorageService | TutorialService │ │
│  └──────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │ HTTPS/TLS + JSON
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CAPA API (FastAPI / Uvicorn)                    │
│  ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐   │
│  │  /api/auth │ │/api/rep. │ │/api/map  │ │/api/predictive │   │
│  └────────────┘ └──────────┘ └──────────┘ └────────────────┘   │
│  ┌──────────────┐ ┌────────────────────────────────────────────┐ │
│  │ /api/users   │ │              /api/admin                    │ │
│  └──────────────┘ └────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              CAPA DE INTELIGENCIA ARTIFICIAL                 │ │
│  │  motor_ia_zonas_riesgo.py │ predictive_context_engine.py    │ │
│  │  DBSCAN (BackgroundTask)  │ SafetyScore + Insights + Linear │ │
│  └──────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                    │                        │
                    ▼                        ▼
┌───────────────────────────┐  ┌────────────────────────────────┐
│   MongoDB Atlas            │  │      Google Firebase           │
│   (geocrimen_tacna)        │  │   Cloud Messaging (FCM)        │
│   4 colecciones            │  │   Tópico: alertas_ciudadanos   │
│   Índices 2dsphere         │  │   Push: incident/update/zone   │
└───────────────────────────┘  └────────────────────────────────┘
```

**Patrones arquitectónicos aplicados:**
- **REST (Representational State Transfer):** Protocolo estándar con verbos HTTP estrictos (GET, POST, DELETE) para toda la comunicación cliente-servidor.
- **N-Tier:** Separación en capas de Presentación (Routers FastAPI), Lógica de Negocio (Services) y Acceso a Datos (PyMongo + DatabaseProxy).
- **Observer/Pub-Sub:** Firebase FCM para la distribución masiva de alertas push por tópico.
- **RBAC (Role-Based Access Control):** Control de acceso basado en roles persistido en `SharedPreferences` (cliente) y validado mediante contraseñas Bcrypt (servidor).

## 5.2 Componentes Implementados

### 5.2.1 Frontend Flutter — Módulos por Rol

**Módulo Ciudadano (`lib/roles/user/`):**

| Vista | Archivo | Descripción |
|-------|---------|-------------|
| Home | `home/views/home_view.dart` | Vista principal con navegación entre módulos |
| Mapa | `map/views/map_view.dart` (80KB) | Mapa OSM con zonas DBSCAN, Safety Score FAB, geofencing, reportes en vivo |
| Mis Reportes | `reports/views/my_reports_view.dart` | Historial personal de reportes con estados |
| Noticias | `news/` | Feed de noticias de seguridad ciudadana |
| Notificaciones | `notifications/views/notifications_view.dart` | Historial de alertas FCM y geofencing |
| Perfil | `profile/` | Gestión del perfil del usuario |

**Módulo Policía (`lib/roles/police/`):**

| Vista | Archivo | Descripción |
|-------|---------|-------------|
| Home | `home/views/home_view.dart` | Vista principal táctica |
| Mapa Táctico | `map/views/map_view.dart` | Mapa con reportes pendientes filtrados por radio |
| Validaciones | `validations/views/validations_view.dart` | Lista de reportes pendientes con acciones confirmar/rechazar |
| Perfil | `profile/` | Gestión del perfil policial |

**Módulo Administrador (`lib/roles/admin/`):**

| Vista | Archivo | Descripción |
|-------|---------|-------------|
| Home | `home/views/home_view.dart` | Vista principal administrativa |
| Dashboard | `dashboard/views/dashboard_view.dart` | Estadísticas con `fl_chart` + predicción LinearRegression |
| Usuarios | `users/views/` | Gestión del inventario de cuentas del sistema |
| Perfil | `profile/` | Gestión del perfil administrativo |

**Core Services (`lib/core/services/`):**

| Servicio | Descripción |
|----------|-------------|
| `GeofenceService` | GPS continuo, detección zonas DBSCAN, cooldown 30min, alertas locales contextuales |
| `MapService` | Caché en memoria de zonas de riesgo y puntos del mapa |
| `PredictiveService` | Consumo de 5 endpoints `/api/predictive/*` con caché por TTL |
| `AuthService` | Login, registro, gestión de sesión con `SharedPreferences` |
| `ReportService` | CRUD de reportes ciudadanos contra `/api/reportes` |
| `NotificationsStorageService` | Persistencia local de notificaciones FCM con `SharedPreferences` |
| `TutorialService` | Control del tutorial inicial con `showcaseview 3.0.0` |

**Core Widgets (`lib/core/widgets/`):**

| Widget | Descripción |
|--------|-------------|
| `SafetyScoreGauge` | Gauge visual circular del Safety Score 0-100 con colores dinámicos |
| `SafetyScoreFAB` | Floating Action Button con Score en tiempo real y panel deslizable |
| `InsightsCard` | Tarjeta de insights contextuales con íconos y severidades coloreadas |
| `SafetyButton` | Botón de reporte rápido de emergencia |
| `SafetyCard` | Tarjeta informativa de zona de riesgo |
| `SafetyLayout` | Layout contenedor para vistas de seguridad |

### 5.2.2 Backend FastAPI — Endpoints Implementados

**Módulo de Autenticación (`/api/auth`):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/login` | Verificación de credenciales Bcrypt, retorna datos de usuario y rol |
| POST | `/api/auth/register` | Registro de nueva cuenta con validación de email único |

**Módulo de Reportes (`/api/reportes`):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/reportes` | Crear reporte con límite de 5 reportes diarios por usuario |
| GET | `/api/reportes/mis_reportes/{user_id}` | Historial de reportes del usuario autenticado |
| DELETE | `/api/reportes/{reporte_id}` | Eliminar reporte propio en estado pendiente |
| POST | `/api/reportes/confirmar/{reporte_id}` | Confirmar reporte (Policía) + push FCM + BackgroundTask DBSCAN |
| POST | `/api/reportes/rechazar/{reporte_id}` | Rechazar reporte como falsa alarma (Policía) |
| GET | `/api/reportes/policia` | Todos los reportes pendientes y confirmados para vista policial |

**Módulo de Mapas (`/api/map`):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/map/zonas_riesgo` | Zonas DBSCAN calculadas con caché de 60 segundos |
| GET | `/api/map/puntos_exactos` | Solo reportes confirmados por la Policía |
| GET | `/api/map/historial_puntos` | Historial completo ArcGIS + ciudadanos confirmados |
| POST | `/api/map/generar_zonas_ia` | Disparador manual del motor DBSCAN en BackgroundTask |

**Módulo Predictivo (`/api/predictive`):**

| Método | Endpoint | TTL Caché | Descripción |
|--------|----------|-----------|-------------|
| GET | `/api/predictive/safety_score` | 30 seg | Score 0-100 por lat/lng y hora |
| GET | `/api/predictive/temporal_analysis` | 5 min | Distribución por hora, día, turno y tendencia |
| GET | `/api/predictive/context_insights` | 1 min | Hasta 6 insights contextuales por ubicación |
| GET | `/api/predictive/risk_forecast` | 10 min | Tendencia y riesgo por turno por distrito |
| GET | `/api/predictive/safe_hours` | 10 min | Franjas horarias seguras estadísticas |

**Módulo Administrativo (`/api/admin`):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/admin/dashboard_stats` | Estadísticas de reportes (total, por estado, por tipo) con filtro temporal |
| GET | `/api/admin/sidpol_stats` | Top 5 distritos y tipos delictivos del historial SIDPOL |
| GET | `/api/admin/sidpol_predict` | Predicción LinearRegression: próximos 3 meses + distrito de mayor riesgo |

### 5.2.3 Motor de Inteligencia Artificial

**Motor Espacial DBSCAN (`motor_ia_zonas_riesgo.py`):**
- **Configuración:** `epsilon=0.15/6371.0` radianes (≈150m), `min_samples=5`, `algorithm='ball_tree'`, `metric='haversine'`.
- **Proceso:** Extrae todos los incidentes con coordenadas válidas de `historial_delitos`, aplica DBSCAN, calcula el centroide geométrico y el delito predominante por clúster, asigna nivel de riesgo según volumen (≥50=crítico, ≥25=alto, ≥10=medio, <10=bajo), calcula radio dinámico (150m–350m), determina tendencia real comparando últimos 3 meses vs 3 meses anteriores.
- **Ciclo de vida:** Se ejecuta en hilo daemon al arrancar el servidor y como `BackgroundTask` cada vez que un policía confirma un reporte.
- **Notificación:** Tras el recálculo, envía push FCM de tipo `update` al tópico `alertas_ciudadanos` para invalidar la caché de mapas en todos los clientes Flutter.

**Motor Predictivo Contextual (`predictive_context_engine.py`):**

| Clase | Método principal | Descripción |
|-------|-----------------|-------------|
| `SafetyScoreCalculator` | `calculate(db, lat, lng, hora)` | Score 0-100 con 4 factores multiplicativos |
| `TemporalAnalyzer` | `analyze_by_hour/day_of_week/turno/trend` | Análisis estadístico temporal sobre MongoDB |
| `InsightGenerator` | `generate(db, lat, lng, hora)` | Hasta 6 insights contextuales personalizados |
| `SafeHoursCalculator` | `calculate(db, distrito)` | Franjas horarias seguras por z-score estadístico |

**Motor Predictivo Administrativo (`analytics_service.py`):**
- Aplica `LinearRegression` de Scikit-Learn sobre el índice temporal (año×12+mes).
- Genera predicciones para los próximos 3 meses a nivel global.
- Identifica el distrito con mayor crecimiento proyectado de incidentes.

### 5.2.4 Base de Datos MongoDB Atlas

**Colecciones:**

| Colección | Índices | Descripción |
|-----------|---------|-------------|
| `usuarios` | `email` (único), `nombre` (único) | Cuentas de sistema con hash Bcrypt y rol RBAC |
| `reportes_ciudadano` | `ubicacion` (2dsphere), `creado_en` (-1) | Reportes ciudadanos con ciclo de vida (pendiente/confirmado/rechazado) |
| `historial_delitos` | `ubicacion` (2dsphere), `creado_en` (-1), `distrito` (asc) | Historial ArcGIS/SIDPOL 2018-2026 importado vía ETL |
| `zonas_riesgo` | `centroide` (2dsphere) | Hotspots calculados por DBSCAN con nivel y radio |

## 5.3 Metodología de Implementación

El proyecto SGEO fue desarrollado siguiendo la metodología **Scrum** con tres sprints iterativos y un equipo unipersonal (Solopreneur), adaptando las ceremonias ágiles al contexto académico-individual.

### Sprint 1: Fundación, GPS y Arquitectura Base (Completado)

**Objetivo:** Consolidar el entorno de desarrollo y establecer la arquitectura base del sistema.

**Actividades realizadas:**
- Configuración del entorno de desarrollo: Flutter SDK ^3.11.3, Python 3.11, MongoDB Atlas.
- Diseño e implementación del esquema de base de datos con validadores `$jsonSchema` via `setup_db.py`.
- Resolución de incompatibilidades nativas del plugin `geolocator` en Android (timeouts GPS).
- Implementación del pipeline de datos geoespaciales (GeoJSON Point, índices `2dsphere`).
- Implementación del ETL base: `extract_arcgis_data.py` e `import_arcgis_data.py`.

**Entregables:**
- Script `setup_db.py` con validadores y creación automática de índices.
- Pipeline ETL funcional con dataset `datos_historicos_tacna.json` (~3.4 MB) importado.
- Estructura de carpetas del proyecto definida y funcional.

### Sprint 2: Roles (RBAC), UI Táctica y Validaciones (Completado)

**Objetivo:** Desarrollar el sistema de autenticación seguro e implementar las interfaces diferenciadas por rol.

**Actividades realizadas:**
- Implementación del módulo de autenticación (`/api/auth/login`, `/api/auth/register`) con Bcrypt.
- Diseño e implementación del sistema visual "Premium Tactical Dark" con `google_fonts` y `flutter_animate`.
- Separación de carpetas `lib/roles/user`, `lib/roles/police`, `lib/roles/admin`.
- Implementación del enrutamiento dinámico basado en `rol` con `SharedPreferences`.
- Módulo de validación policial: `/api/reportes/confirmar/{id}` y `/api/reportes/rechazar/{id}`.
- Restricción de radio táctico de 3km para la vista policial.
- Sistema anti-spam: límite de 5 reportes diarios por usuario.

**Entregables:**
- Sistema de login funcional con RBAC estricto.
- Interfaces diferenciadas operativas para los tres roles.
- Módulo de creación y validación de reportes geoespaciales.

### Sprint 3: Machine Learning, Analítica y Despliegue (Completado)

**Objetivo:** Implementar la inteligencia artificial del sistema, los dashboards analíticos y preparar el despliegue en producción.

**Actividades realizadas:**
- Implementación del motor DBSCAN (`motor_ia_zonas_riesgo.py`) con parámetros geoespaciales reales.
- Desarrollo del motor predictivo contextual completo (`predictive_context_engine.py`) con las 4 clases especializadas.
- Implementación de los 5 endpoints REST del módulo predictivo (`/api/predictive/*`).
- Desarrollo del servicio `GeofenceService` con seguimiento GPS continuo y cooldown de 30 minutos.
- Implementación de los widgets de seguridad: `SafetyScoreGauge`, `SafetyScoreFAB`, `InsightsCard`.
- Dashboard administrativo con `fl_chart` y predicción LinearRegression a 3 meses.
- Integración completa de Firebase Cloud Messaging (push masivo, foreground/background/terminated).
- Servicio `NotificationsStorageService` para persistencia local del historial de alertas.
- Módulo de noticias de seguridad ciudadana en la interfaz del Ciudadano.
- Despliegue del backend en Railway PaaS con `Procfile` y variables de entorno.
- Redacción y actualización de documentación técnica universitaria (FD01–FD05).

**Entregables:**
- Motor DBSCAN funcional generando hotspots automáticamente.
- 5 endpoints predictivos con caché inteligente por TTL.
- Dashboard administrativo con predicción a 3 meses.
- Sistema de notificaciones push completo (FCM + geofencing local).
- Sistema desplegado en Railway PaaS listo para producción.

### Definición de Terminado (DoD - Definition of Done)

Una historia de usuario se considera completada cuando:
1. El código fuente está integrado en la rama principal del repositorio.
2. La funcionalidad es accesible desde la interfaz del rol correspondiente.
3. El endpoint REST asociado retorna respuestas con status 200 bajo datos válidos.
4. No existen errores en `flutter analyze` ni advertencias críticas de Pydantic v2.
5. La funcionalidad ha sido validada manualmente en emulador Android API 34.

## 5.4 Tecnologías Utilizadas

### Frontend (Aplicación Móvil)

| Tecnología | Versión | Uso en SGEO |
|-----------|---------|-------------|
| Flutter | SDK ^3.11.3 | Framework multiplataforma para Android/iOS |
| Dart | 3.x | Lenguaje de programación del frontend |
| flutter_map | ^8.2.2 | Renderización de mapas OpenStreetMap con capas vectoriales |
| geolocator | ^14.0.2 | Acceso al GPS nativo del dispositivo |
| firebase_core | ^4.7.0 | Inicialización del SDK de Firebase |
| firebase_messaging | ^16.2.0 | Recepción de notificaciones FCM en todos los estados |
| flutter_local_notifications | ^21.0.0 | Notificaciones locales (geofencing) con canal `sgeo_alertas_urgentes` |
| fl_chart | ^1.2.0 | Gráficas de barras y líneas en el dashboard administrativo |
| flutter_animate | ^4.5.2 | Micro-animaciones y transiciones de UI |
| google_fonts | ^8.1.0 | Tipografía del sistema visual "Premium Tactical Dark" |
| lottie | ^3.3.2 | Animaciones vectoriales en vistas de carga |
| shared_preferences | ^2.5.5 | Persistencia local de sesión, notificaciones y configuración |
| showcaseview | 3.0.0 | Tutorial interactivo de onboarding |
| sliding_up_panel | ^2.0.0+1 | Panel deslizable del Safety Score en el mapa |
| http | ^1.6.0 | Cliente HTTP para consumo de la API REST |
| latlong2 | ^0.9.1 | Tipos de datos geoespaciales (LatLng) |
| intl | ^0.20.2 | Formateo de fechas y números |

### Backend (API REST y Motor IA)

| Tecnología | Versión | Uso en SGEO |
|-----------|---------|-------------|
| Python | 3.11+ | Lenguaje de programación del backend |
| FastAPI | 0.104.1 | Framework web ASGI para la API REST |
| Uvicorn | 0.24.0 | Servidor ASGI de alto rendimiento |
| Pydantic | 2.5.2 | Validación y serialización de datos |
| PyMongo | 4.6.0 | Driver MongoDB para Python |
| Bcrypt | 4.1.1 | Hash seguro de contraseñas |
| Scikit-Learn | 1.3.2 | DBSCAN y LinearRegression |
| Pandas | 2.1.3 | Manipulación de DataFrames para análisis |
| NumPy | 1.26.2 | Operaciones matriciales y estadísticas |
| firebase-admin | 6.3.0 | Firebase Admin SDK para envío de push FCM |
| python-dotenv | 1.0.0 | Gestión de variables de entorno |
| pytz | 2023.3.post1 | Manejo de zonas horarias |

### Infraestructura y Servicios

| Servicio | Plan/Versión | Uso en SGEO |
|---------|-------------|-------------|
| MongoDB Atlas | Cluster con Replica Set | Base de datos `geocrimen_tacna` con 4 colecciones e índices `2dsphere` |
| Railway PaaS | Hobby/Pro | Hosting del backend FastAPI con inicio vía `Procfile` |
| Firebase Cloud Messaging | API V1 | Notificaciones push masivas a `alertas_ciudadanos` |
| OpenStreetMap (OSM) | Tiles gratuitos | Cartografía base del mapa interactivo |
| ArcGIS Open Data | Datos abiertos | Fuente de datos históricos criminológicos de Tacna |

## 5.5 Resultados Obtenidos

### Resultados Técnicos

| Componente | Resultado |
|-----------|-----------|
| Motor DBSCAN | Genera hotspots automáticamente sobre el historial SIDPOL 2018-2026 con clasificación por nivel (bajo/medio/alto/crítico) y radio dinámico |
| Safety Score | Endpoint `/api/predictive/safety_score` retorna score 0-100 con latencia <250ms gracias a índices `2dsphere` |
| Endpoints predictivos | 5 endpoints funcionales con caché por TTL (30s a 10min) para optimización de consultas |
| Geofencing | `GeofenceService` detecta ingreso a zonas de riesgo con `distanceFilter=50m` y emite alertas contextuales por turno horario |
| Notificaciones FCM | Pipeline completo: backend confirma reporte → push FCM → cliente Flutter recibe en cualquier estado → almacena en historial local |
| Interfaces RBAC | Tres interfaces nativas completamente diferenciadas y funcionales para Ciudadano, Policía y Administrador |
| Dashboard Admin | Visualización de estadísticas en tiempo real y predicción de incidentes a 3 meses por distrito |

### Resultados Funcionales por Rol

**Ciudadano:**
- Registro y autenticación con validación de email único.
- Visualización del mapa con zonas de riesgo DBSCAN coloreadas por nivel.
- Safety Score dinámico visible en el mapa mediante FAB deslizable.
- Creación de reportes geolocalizados con categorización de delito (límite: 5 diarios).
- Consulta del historial propio de reportes con estados.
- Recepción de alertas FCM por incidentes confirmados y actualizaciones del mapa.
- Alertas automáticas de geofencing al ingresar a zonas de riesgo.
- Acceso al feed de noticias de seguridad ciudadana.
- Historial persistente de notificaciones recibidas.

**Policía:**
- Visualización del mapa táctico con reportes pendientes filtrados a 3km.
- Acciones de confirmación y rechazo de reportes con feedback visual.
- Vista de todos los reportes (pendientes y confirmados) en el mapa.
- Perfil con información del agente.

**Administrador:**
- Dashboard con métricas en tiempo real: total de reportes, distribución por estado (pendiente/confirmado/rechazado) y por tipo de delito.
- Estadísticas del historial SIDPOL: top 5 distritos y tipos delictivos más frecuentes.
- Predicción de incidentes a 3 meses a nivel global y por distrito (LinearRegression).
- Identificación automática del distrito con mayor riesgo proyectado.
- Gestión del inventario de usuarios del sistema.

### Métricas de Rendimiento Estimadas

| Métrica | Valor Estimado | Base |
|--------|---------------|------|
| Latencia API (endpoints simples) | ≤80ms | Consultas GET sobre índices MongoDB |
| Latencia consultas geoespaciales | ≤250ms | `$nearSphere` con índices `2dsphere` |
| Latencia Safety Score | ≤250ms | 4 factores sobre `$nearSphere` |
| Throughput Uvicorn (2 núcleos) | ~300 RPS | Bajo carga concurrente moderada |
| Procesamiento ETL SIDPOL (~3.4MB) | 8–15 seg | Pandas.read_json() en CPU ordinario |
| Cooldown geofencing | 30 minutos | Para evitar saturación de alertas locales |
| Distancia GPS para activar geofencing | 50 metros | `distanceFilter` del plugin `geolocator` |

---

# 6. Cronograma

El proyecto se desarrolló durante el primer semestre académico de 2026, organizado en tres sprints iterativos bajo la metodología Scrum:

| Fase | Período | Actividades | Estado |
|------|---------|-------------|--------|
| Planificación y análisis | Semana 1-2 (Marzo 2026) | Levantamiento de requerimientos, diseño de arquitectura, selección de pila tecnológica, análisis de factibilidad | ✅ Completado |
| Sprint 1: Fundación | Semana 3-5 (Marzo 2026) | Entorno de desarrollo, esquema MongoDB, pipeline ETL, importación SIDPOL | ✅ Completado |
| Sprint 2: RBAC y UI | Semana 6-9 (Abril 2026) | Autenticación, interfaces por rol, validación policial, sistema anti-spam | ✅ Completado |
| Sprint 3: IA y Despliegue | Semana 10-14 (Mayo-Junio 2026) | DBSCAN, Motor Predictivo, Geofencing, FCM, Dashboards, Despliegue Railway | ✅ Completado |
| Documentación final | Semana 15-16 (Junio 2026) | Redacción y actualización de FD01-FD05 | ✅ Completado |

**Duración total del proyecto:** 16 semanas (4 meses)

---

# 7. Presupuesto

La inversión total del proyecto SGEO asciende a **S/ 23,540**, financiada íntegramente por el desarrollador bajo el modelo Solopreneur. La distribución de costos se detalla a continuación:

### 7.1 Costos Generales

| Concepto | Cantidad | Costo Unitario (S/) | Total (S/) |
|----------|----------|---------------------|------------|
| Cuenta Developer de Google Play (Lifetime) | 1 | 100 | 100 |
| Cuenta Apple Developer Program (Anual) | 1 | 390 | 390 |
| Material de oficina y periféricos | 1 paquete | 250 | 250 |
| **Total** | - | - | **740** |

### 7.2 Costos Operativos (12 meses)

| Concepto | Mensual (S/) | 12 Meses (S/) |
|----------|--------------|---------------|
| Internet fibra óptica empresarial | 120 | 1,440 |
| Electricidad adicional de equipos | 60 | 720 |
| Comunicaciones y viáticos | 50 | 600 |
| **Total** | **230** | **2,760** |

### 7.3 Costos del Ambiente (Infraestructura Cloud, 12 meses)

| Concepto | Mensual (S/) | 12 Meses (S/) |
|----------|--------------|---------------|
| Hosting Backend — Railway PaaS | 60 | 720 |
| Base de Datos — MongoDB Atlas | 80 | 960 |
| Servicios Firebase FCM y Admin SDK | 10 | 120 |
| Dominios, SSL y Tiles OSM | 20 | 240 |
| **Total** | **170** | **2,040** |

### 7.4 Costos de Personal

| Rol | Personas | Dedicación | Monto Total (S/) |
|-----|----------|------------|------------------|
| Desarrollador Full-Stack/IA (Piero Paja) | 1 | 12 meses part-time | 18,000 |
| **Total Costos Personal** | - | - | **18,000** |

### 7.5 Resumen Total

| Categoría | Monto (S/) | % |
|-----------|------------|---|
| Costos Generales | 740 | 3% |
| Costos Operativos | 2,760 | 12% |
| Costos del Ambiente | 2,040 | 9% |
| Costos de Personal | 18,000 | 76% |
| **Total Proyecto** | **23,540** | **100%** |

### 7.6 Análisis de Retorno de Inversión

| Indicador | Valor |
|-----------|-------|
| Beneficios tangibles anuales (ahorro combustible + reducción burocracia) | S/ 26,700 |
| Inversión inicial | S/ 23,540 |
| Valor Actual Neto (VAN) | S/ 1,501 (positivo) |
| Relación Beneficio/Costo (B/C) | 1.06 |
| Tasa Interna de Retorno (TIR) | >13% |

---

# 8. Conclusiones

1. **Viabilidad técnica demostrada:** El proyecto SGEO ha demostrado que es técnicamente viable implementar un sistema de geolocalización criminal con Machine Learning sobre la pila tecnológica open-source seleccionada (Flutter, FastAPI, MongoDB, Scikit-Learn, Firebase). Todos los componentes han sido implementados y validados con datos reales del SIDPOL de la región de Tacna.

2. **Efectividad del Motor DBSCAN:** El algoritmo DBSCAN con parámetros geoespaciales (`epsilon=150m`, `min_samples=5`, `metric='haversine'`) ha demostrado ser capaz de identificar automáticamente hotspots delictivos reales sobre el historial criminológico 2018-2026, sin requerir conocimiento previo del número de zonas de riesgo ni de los límites distritales.

3. **Innovación del Motor Predictivo Contextual:** La implementación de `predictive_context_engine.py` con sus cuatro clases especializadas (`SafetyScoreCalculator`, `TemporalAnalyzer`, `InsightGenerator`, `SafeHoursCalculator`) constituye una contribución técnica significativa que supera el objetivo inicial de una única predicción por Regresión Lineal, ofreciendo análisis multidimensional en tiempo real accesible vía 5 endpoints REST.

4. **Robustez del Sistema de Notificaciones:** La integración completa de Firebase Cloud Messaging con manejo de los tres estados de la aplicación Flutter (foreground, background, terminated), combinada con el sistema de geofencing local con cooldown inteligente, garantiza que los ciudadanos reciban alertas preventivas oportunas sin saturación de notificaciones.

5. **Validez del Modelo RBAC:** La separación estricta de interfaces y endpoints por rol (Ciudadano, Policía, Administrador) mediante `SharedPreferences` en el cliente y Bcrypt en el servidor ha demostrado ser una estrategia efectiva para garantizar la integridad del proceso de validación policial y prevenir la contaminación del historial analítico por reportes no verificados.

6. **Retorno de inversión positivo:** El análisis financiero confirma un VAN positivo de S/ 1,501 y una relación B/C de 1.06, validando la rentabilidad económica del proyecto frente a los beneficios tangibles en optimización logística policial y reducción de costos operativos.

---

# 9. Recomendaciones

1. **Restricción de CORS en producción:** El sistema actualmente tiene CORS irrestricto (`allow_origins=["*"]`). Se recomienda configurar la lista blanca de dominios permitidos antes del despliegue en entorno productivo institucional para prevenir ataques CSRF.

2. **Migración a caché distribuido (Redis):** Los módulos de mapas y predictivo utilizan caché en memoria Python (`_cache_store`). Para un entorno multi-worker o multi-instancia en Railway, se recomienda migrar a Redis para garantizar consistencia de caché entre instancias.

3. **Implementación de autenticación JWT formal:** El sistema actual usa `SharedPreferences` para persistencia de sesión sin tokens firmados en tránsito. Se recomienda implementar JSON Web Tokens (JWT) con expiración en 24 horas para fortalecer la seguridad de las sesiones, especialmente considerando las rutas policiales y administrativas.

4. **Pruebas de carga y stress testing:** Se recomienda realizar pruebas de carga con herramientas como Locust o k6 para validar el comportamiento del sistema bajo la carga concurrente de múltiples usuarios simultáneos, especialmente sobre los endpoints de consulta geoespacial `$nearSphere`.

5. **Reentrenamiento periódico del modelo DBSCAN:** El motor DBSCAN se ejecuta en el arranque del servidor y tras cada confirmación policial. Se recomienda implementar una tarea cron semanal que fuerce el recálculo con los datos más recientes del SIDPOL para mantener la vigencia de los hotspots.

6. **Formalización del contacto con entidades gubernamentales:** Se recomienda iniciar gestiones oficiales con la Policía Nacional del Perú (PNP) — Región Tacna y la Municipalidad Provincial de Tacna para obtener acceso a la API oficial del SIDPOL, eliminando la dependencia de scripts ETL manuales y garantizando la actualización continua del historial criminológico.

7. **Expansión a iOS:** El proyecto ha sido desarrollado principalmente para Android (API 26+). Se recomienda realizar las pruebas de compatibilidad en iOS (Xcode, Apple Developer Program) y publicar en Apple App Store para maximizar el alcance ciudadano.

8. **Implementación de registro de auditoría:** Se recomienda agregar una colección `audit_log` en MongoDB que registre todas las acciones críticas (confirmaciones, rechazos, cambios de rol) con timestamp y usuario responsable, para cumplimiento de la Ley N° 29733 de Protección de Datos Personales.

---

# 10. Bibliografía

1. Ester, M., Kriegel, H. P., Sander, J., & Xu, X. (1996). A density-based algorithm for discovering clusters in large spatial databases with noise. *Proceedings of the Second International Conference on Knowledge Discovery and Data Mining (KDD-96)*, 226–231.

2. Pedregosa, F., et al. (2011). Scikit-learn: Machine Learning in Python. *Journal of Machine Learning Research*, 12, 2825–2830.

3. Kruchten, P. (1995). The 4+1 View Model of Architecture. *IEEE Software*, 12(6), 42–50.

4. Sommerville, I. (2016). *Software Engineering* (10th ed.). Pearson.

5. Pressman, R. S. (2014). *Software Engineering: A Practitioner's Approach* (8th ed.). McGraw-Hill.

6. IEEE. (2018). *IEEE Standard for Software and Systems Engineering — Life Cycle Processes — Requirements Engineering*. IEEE Std 29148-2018.

7. IEEE. (2011). *Systems and software engineering — Architecture description*. IEEE Std 42010-2011.

8. MongoDB, Inc. (2024). *Geospatial Queries in MongoDB*. Recuperado de https://www.mongodb.com/docs/manual/geospatial-queries/

9. FastAPI. (2024). *FastAPI — Modern, fast web framework for building APIs with Python*. Recuperado de https://fastapi.tiangolo.com/

10. Flutter Team. (2025). *Flutter — Build apps for any screen*. Recuperado de https://flutter.dev/

11. Google Firebase. (2024). *Firebase Cloud Messaging Documentation*. Recuperado de https://firebase.google.com/docs/cloud-messaging

12. Ministerio del Interior del Perú. (2024). *Sistema de Información Policial (SIDPOL)*. Recuperado de https://www.mininter.gob.pe/

13. Congreso de la República del Perú. (2011). *Ley N° 29733 — Ley de Protección de Datos Personales*. El Peruano.

14. Hunter, J. D. (2007). Matplotlib: A 2D Graphics Environment. *Computing in Science & Engineering*, 9(3), 90–95.

15. McKinney, W. (2010). Data Structures for Statistical Computing in Python. *Proceedings of the 9th Python in Science Conference*, 51–56.
