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

**Documento Informe de Propuesta de Proyecto**  
**Versión:** 1.0  

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha      | Motivo           |
|---------|-----------|--------------|--------------|------------|------------------|
| 1.0     | PP        | PP           | AF           | 04/07/2026 | Versión Original |

---

## TABLA DE CONTENIDO

1. [Introducción](#1-introducción)
2. [Resumen Ejecutivo](#2-resumen-ejecutivo)
   - 2.1 [Nombre del Proyecto](#21-nombre-del-proyecto)
   - 2.2 [Descripción General](#22-descripción-general)
   - 2.3 [Objetivos](#23-objetivos)
   - 2.4 [Alcance](#24-alcance)
   - 2.5 [Beneficiarios](#25-beneficiarios)
   - 2.6 [Tecnologías Utilizadas](#26-tecnologías-utilizadas)
   - 2.7 [Funcionalidades Principales](#27-funcionalidades-principales)
3. [Documentación Técnica](#3-documentación-técnica)
   - 3.1 [Documento Principal (README)](#31-documento-principal-readme)
   - 3.2 [Documentación de API](#32-documentación-de-api)
   - 3.3 [Guía de Desarrollo](#33-guía-de-desarrollo)
   - 3.4 [Arquitectura del Sistema](#34-arquitectura-del-sistema)
4. [Configuración del Proyecto](#4-configuración-del-proyecto)
   - 4.1 [Variables de Entorno](#41-variables-de-entorno)
   - 4.2 [Scripts de Instalación y Despliegue](#42-scripts-de-instalación-y-despliegue)
   - 4.3 [Integración Continua (CI/CD)](#43-integración-continua-cicd)
5. [Documentación de Módulos](#5-documentación-de-módulos)
   - 5.1 [Módulo 1: Autenticación y Gestión de Identidad](#51-módulo-1-autenticación-y-gestión-de-identidad)
   - 5.2 [Módulo 2: Reportes Geoespaciales y Validación Policial](#52-módulo-2-reportes-geoespaciales-y-validación-policial)
   - 5.3 [Módulo 3: Motor de Inteligencia Artificial](#53-módulo-3-motor-de-inteligencia-artificial)
   - 5.4 [Módulo 4: Notificaciones, Geofencing y Administración](#54-módulo-4-notificaciones-geofencing-y-administración)
6. [Testing](#6-testing)
   - 6.1 [Estrategia de Pruebas](#61-estrategia-de-pruebas)
   - 6.2 [Resumen de Pruebas](#62-resumen-de-pruebas)
   - 6.3 [Casos de Prueba](#63-casos-de-prueba)
7. [Documentación Complementaria](#7-documentación-complementaria)
   - 7.1 [Guía de Despliegue](#71-guía-de-despliegue)
   - 7.2 [Manual Técnico](#72-manual-técnico)
   - 7.3 [Manual de Usuario](#73-manual-de-usuario)
   - 7.4 [Funcionalidades Especiales](#74-funcionalidades-especiales)
8. [Organización del Proyecto](#8-organización-del-proyecto)
   - 8.1 [Estructura de Carpetas](#81-estructura-de-carpetas)
   - 8.2 [Organización de la Documentación](#82-organización-de-la-documentación)
9. [Guía de Uso](#9-guía-de-uso)
   - 9.1 [Flujo de Lectura](#91-flujo-de-lectura)
   - 9.2 [Referencias Rápidas](#92-referencias-rápidas)
   - 9.3 [Mantenimiento de la Documentación](#93-mantenimiento-de-la-documentación)
10. [Conclusiones](#10-conclusiones)

[Anexos](#anexos)

---

# 1. Introducción

El presente Informe de Propuesta de Proyecto consolida, en un único documento navegable, la propuesta integral del sistema SGEO y el mapa completo de su documentación técnica y funcional. Actúa como el punto de entrada oficial al ecosistema documental del proyecto: quien lea este informe conocerá qué es SGEO, qué problema resuelve, cómo está construido, dónde se encuentra cada pieza de documentación (FD01–FD05, Plan e Informe de Pruebas, README del repositorio) y cómo instalar, desplegar, probar y mantener el sistema.

El documento está dirigido a tres audiencias: (1) el evaluador académico, que necesita una vista panorámica verificable del trabajo realizado; (2) un desarrollador nuevo, que necesita poner en marcha el entorno y ubicar el código de cada módulo; y (3) un interesado institucional (PNP, Municipalidad), que necesita entender las capacidades del producto sin tecnicismos.

---

# 2. Resumen Ejecutivo

## 2.1 Nombre del Proyecto

**SGEO — Sistema de Geolocalización de Inseguridad Ciudadana con Machine Learning Predictivo y Espacial.**

## 2.2 Descripción General

SGEO es una aplicación móvil multiplataforma (Flutter) con backend inteligente (FastAPI + MongoDB Atlas) que registra, visualiza, predice y alerta sobre zonas de inseguridad en la provincia de Tacna, Perú. Combina tres fuentes de verdad: reportes ciudadanos geolocalizados en tiempo real, la validación oficial del rol policial, y los datos criminológicos oficiales del servicio ArcGIS REST `SIDPOL_DELITOS_TOTAL` del MININTER (filtrados por provincia de Tacna, delitos contra el patrimonio y año vigente).

Sobre esos datos operan dos motores de Inteligencia Artificial: un **motor espacial DBSCAN** que delimita hotspots delictivos usando exclusivamente el mes más reciente de datos disponibles (evitando zonas obsoletas), y un **motor predictivo contextual** que calcula un Safety Score 0-100, análisis temporal, insights personalizados y franjas horarias seguras.

## 2.3 Objetivos

- **General:** Reducir los tiempos de respuesta policial y aumentar la prevención civil en Tacna mediante geolocalización colaborativa e inteligencia artificial espacial y predictiva.
- **Específicos:**
  1. Delimitar automáticamente zonas de riesgo actuales con DBSCAN (`eps=150m`, `min_samples=5`, métrica haversine) sobre el mes más reciente de datos oficiales.
  2. Proveer métricas predictivas en tiempo real (Safety Score, insights, safe hours, forecast) vía 5 endpoints REST.
  3. Garantizar la integridad del dato mediante validación policial obligatoria (radio de patrullaje de 1 km), límite antispam de 5 reportes/día y agrupación de duplicados en 500 m.
  4. Alertar proactivamente al ciudadano vía geofencing local (cooldown 30 min) y push masivo FCM (cooldown 24 h para actualizaciones de mapa).
  5. Asegurar la calidad con una suite automatizada de 82 pruebas y análisis estático en cero issues.

## 2.4 Alcance

Tres interfaces móviles nativas por rol (Ciudadano, Policía, Administrador) bajo el sistema visual "Premium Tactical Dark"; backend de 6 routers REST; motor IA espacial y predictivo; pipeline ETL de datos oficiales; sistema de notificaciones push y geofencing; y suite de pruebas automatizadas. Quedan fuera del alcance (roadmap): autenticación JWT con middleware, recuperación de contraseña, panel web independiente, integración de videocámaras y Deep Learning.

## 2.5 Beneficiarios

| Beneficiario | Beneficio directo |
|---|---|
| Ciudadanía de Tacna | Mapa de riesgo vigente, alertas preventivas automáticas, canal de reporte en 3 toques |
| PNP — Región Tacna | Validación táctica en campo, mapa sonar de patrullaje, priorización basada en datos |
| Administración / Inteligencia | Dashboards analíticos, predicción a 3 meses por distrito, gestión y aprobación de cuentas |
| Municipalidad Provincial | Métricas objetivas para presupuesto de seguridad y optimización de serenazgo |

## 2.6 Tecnologías Utilizadas

| Capa | Tecnología |
|---|---|
| Frontend móvil | Flutter SDK ^3.11.3 (Dart 3), flutter_map 8.2.2, geolocator 14.0.2, firebase_messaging 16.2.0, fl_chart 1.2.0, flutter_animate 4.5.2 |
| Backend API | Python 3.11+, FastAPI 0.104.1, Uvicorn 0.24.0, Pydantic 2.5.2, bcrypt 4.1.1 |
| Inteligencia Artificial | scikit-learn 1.3.2 (DBSCAN, LinearRegression), pandas 2.1.3, numpy 1.26.2 |
| Base de datos | MongoDB Atlas (`geocrimen_tacna`), índices 2dsphere, validadores `$jsonSchema` |
| Mensajería push | Firebase Cloud Messaging (firebase-admin 6.3.0), tópico `alertas_ciudadanos` |
| Correo transaccional | Resend API (flujo de acreditación policial) |
| Infraestructura | Railway PaaS (Procfile + uvicorn), tiles OSM/CartoDB |
| Testing | pytest 9.x + mongomock + TestClient (backend), flutter_test (frontend) |

## 2.7 Funcionalidades Principales

1. **Mapa ciudadano** con zonas de riesgo del periodo vigente, alertas confirmadas (últimos 60 días), historial SIDPOL por zoom, chips de capas y filtro de periodo.
2. **Botón REPORTAR** centrado en zona de pulgar, con formulario geolocalizado y límite diario.
3. **Safety Score FAB** con panel de insights contextuales del motor predictivo.
4. **Mapa policial táctico** con radar sonar animado (1 km), contador de pendientes y auto-refresh de 30 s.
5. **Validación policial** (confirmar/rechazar) con agrupación de duplicados y efectos en cascada (historial + push + IA).
6. **Geofencing** con alertas locales contextuales por turno horario.
7. **Notificaciones push** con navegación contextual al tocar (foreground/background/terminated).
8. **Dashboard administrativo** con estadísticas, Big Data SIDPOL y predicción LinearRegression a 3 meses.
9. **Aprobación de cuentas policiales** con correo de acreditación y motivo de rechazo.
10. **Tutorial interactivo** de onboarding (showcaseview) y feed de noticias de seguridad.

---

# 3. Documentación Técnica

## 3.1 Documento Principal (README)

El archivo [`README.md`](../README.md) en la raíz del repositorio es la carta de presentación técnica: describe el sistema de diseño "Premium Tactical Dark", la arquitectura completa del repositorio (árbol comentado de `lib/` y `backend/`), y el propósito de cada módulo. Es el primer documento que debe leer un desarrollador nuevo.

## 3.2 Documentación de API

La API se documenta en tres niveles complementarios:

1. **Swagger/OpenAPI automático:** FastAPI expone la documentación interactiva en `{baseUrl}/docs` (Swagger UI) y `{baseUrl}/redoc`, generada desde los esquemas Pydantic — siempre sincronizada con el código.
2. **Catálogo de endpoints:** El FD05 (§5.2.2) tabula los 25+ endpoints por módulo con método, ruta y descripción; el FD03 (§IV.c) los vincula a los requerimientos funcionales RF-*.
3. **Cliente tipado:** `lib/core/config/api_config.dart` centraliza todas las URLs consumidas por la app (target de producción: `https://sgeo-backend-production.up.railway.app`), sirviendo de contrato vivo entre frontend y backend.

## 3.3 Guía de Desarrollo

**Puesta en marcha local:**

```bash
# Backend
cd backend
pip install -r requirements.txt
cp .env.example .env        # completar MONGO_URL y credenciales
python scripts_iniciales/setup_db.py   # colecciones, validadores, usuarios semilla
uvicorn main:app --reload

# Frontend
flutter pub get
flutter run                 # apuntar ApiConfig.baseUrl a la URL local si se desea
```

**Convenciones del proyecto:**
- Dart: arquitectura por roles (`lib/roles/{user,police,admin}`), servicios en `lib/core/services/`, cero issues en `flutter analyze`.
- Python: routers delgados en `routes/`, lógica de negocio en `services/`, utilitarios puros en `utils/`, esquemas en `models/`.
- No editar archivos Dart con herramientas de reescritura de texto de shell (riesgo de corrupción de caracteres en español).

## 3.4 Arquitectura del Sistema

La arquitectura completa está especificada en el **FD04 (SAD)** bajo el modelo 4+1 de Kruchten: vista lógica (capas Flutter → FastAPI → MongoDB), vista de implementación (estructura de directorios), vista de procesos (RBAC en dos niveles y BackgroundTasks), vista de despliegue (Railway + Atlas + FCM) y decisiones arquitectónicas justificadas. Diagramas complementarios en `docs/DIAGRAMAS.md` y `docs/example/*.puml`.

---

# 4. Configuración del Proyecto

## 4.1 Variables de Entorno

Definidas en `backend/.env.example` (nunca versionar el `.env` real):

| Variable | Propósito |
|---|---|
| `MONGO_URL` | URI de conexión a MongoDB Atlas (obligatoria) |
| `SECRET_KEY` | Declarada y reservada para la futura firma de JWT (sin uso actual) |
| `FIREBASE_CREDENTIALS_JSON` | Credenciales Firebase Admin SDK en Railway (en local se usa `sgeo-firebase-adminsdk.json`) |
| `PORT` | Puerto del servidor (default 8000; Railway lo inyecta) |
| `ENV` | `development` habilita CORS abierto; cualquier otro valor usa la lista restringida de orígenes |
| `RESEND_API_KEY` | API key del servicio de correo Resend |
| `RESEND_FROM_EMAIL` | Remitente verificado del dominio en Resend |
| `ADMIN_EMAIL` | Correo del administrador que recibe las acreditaciones policiales |

## 4.2 Scripts de Instalación y Despliegue

| Script | Función |
|---|---|
| `backend/scripts_iniciales/setup_db.py` | Crea las 4 colecciones con validadores `$jsonSchema`, índices 2dsphere y usuarios semilla (admin/policía/ciudadano de prueba) |
| `backend/scripts_iniciales/extract_arcgis_data.py` | Extrae del servicio ArcGIS REST del MININTER los delitos patrimoniales del año vigente (provincia de Tacna), con paginación de 2000 y reporte de distribución mensual |
| `backend/scripts_iniciales/import_arcgis_data.py` | Importa el JSON extraído a `historial_delitos`, reemplazando solo los registros `fuente="arcgis_sidpol"` (nunca toca reportes ciudadanos) |
| `backend/Procfile` | Arranque en Railway: `web: uvicorn main:app --host 0.0.0.0 --port $PORT` |
| `backend/motor_ia_zonas_riesgo.py` | Ejecutable directamente (`python motor_ia_zonas_riesgo.py`) para regenerar zonas manualmente |

## 4.3 Integración Continua (CI/CD)

**Estado actual:** el despliegue es continuo vía Railway (cada push a `main` redeploya el backend automáticamente). No existe aún un pipeline de CI que ejecute las suites de prueba antes del merge; las suites se ejecutan localmente (`pytest` + `flutter test`) como parte del Definition of Done.

**Propuesta de pipeline (GitHub Actions), lista para adoptar:**

```yaml
# .github/workflows/ci.yml (propuesto)
name: CI
on: [push, pull_request]
jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - run: pip install -r backend/requirements.txt pytest mongomock httpx
      - run: cd backend && python -m pytest tests/ -q
  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

Las 82 pruebas corren contra mongomock y dobles de prueba, por lo que el pipeline no necesita secretos ni servicios externos.

---

# 5. Documentación de Módulos

## 5.1 Módulo 1: Autenticación y Gestión de Identidad

- **Backend:** `routes/auth.py` (login/registro), `utils/crypto.py` (bcrypt), `services/email_service.py` (correo de acreditación vía Resend).
- **Frontend:** `lib/features/auth/views/` (login, registro, splash), `AuthService`, persistencia de sesión en `SharedPreferences`.
- **Reglas clave:** hash bcrypt con salt (nunca texto plano), mensaje de error único anti-enumeración, unicidad de email y nombre, y **gate de aprobación policial**: las cuentas con rol `policia` nacen desactivadas (`aprobacion_pendiente`) hasta la decisión del Administrador; el rechazo comunica su motivo en el siguiente login (HTTP 403).
- **Referencias:** FD03 §Módulo 1 (RF-AUT-01..05, RN-07), FD04 §5.3.1.

## 5.2 Módulo 2: Reportes Geoespaciales y Validación Policial

- **Backend:** `routes/reports.py` + `services/report_service.py`.
- **Frontend:** mapa ciudadano (`lib/roles/user/map/`), Mis Reportes, mapa táctico y pestaña Validar del policía (`lib/roles/police/`).
- **Ciclo de vida del reporte:** `pendiente → confirmado | rechazado | agrupado`. La confirmación ejecuta la cascada: copia a `historial_delitos` (`fuente="ciudadano"`, atómica — si falla, se aborta), agrupación de pendientes duplicados (500 m, mismo subtipo), push FCM `incident` con coordenadas exactas y recalculo DBSCAN en background.
- **Protecciones:** límite 5 reportes/día (HTTP 429), eliminación solo de pendientes propios, validación Pydantic (HTTP 422).
- **UX policial:** radar sonar animado de 1 km, marcadores ámbar/verde por estado, auto-refresh silencioso cada 30 s.
- **Referencias:** FD03 §Módulos 2-3 (RF-REP, RF-TAC, RN-01..RN-04), FD04 §5.3.2.

## 5.3 Módulo 3: Motor de Inteligencia Artificial

- **Motor espacial** (`motor_ia_zonas_riesgo.py`): detecta el mes más reciente con datos SIDPOL (`$max fecha_hecho`), toma esos incidentes más los reportes ciudadanos confirmados de los últimos 60 días (provincia de Tacna, con coordenadas), aplica DBSCAN y persiste zonas con nivel de riesgo, radio dinámico (150–350 m), tendencia y periodo fuente (`anio_periodo`/`mes_periodo`). Guardado atómico y notificación `update` con cooldown de 24 h.
- **Motor predictivo** (`predictive_context_engine.py`): `SafetyScoreCalculator` (4 factores), `TemporalAnalyzer`, `InsightGenerator` (hasta 6 insights), `SafeHoursCalculator`; expuesto por los 5 endpoints de `routes/predictive.py` con caché por TTL.
- **Analítica administrativa** (`services/analytics_service.py`): LinearRegression sobre índice temporal para proyectar 3 meses y detectar el distrito de mayor riesgo.
- **Referencias:** FD03 §Módulo 5 (RF-MAP, RN-05), FD04 §5.3.2, FD05 §5.2.3 y §4 (marco teórico).

## 5.4 Módulo 4: Notificaciones, Geofencing y Administración

- **Push FCM** (`firebase_service.py` + `lib/main.dart`): tópico `alertas_ciudadanos`; tipos `incident` (centra el mapa en el hecho), `update` (limpia caché y abre alertas) y `risk_zone`; manejo de tap en los tres estados de la app con guard de sesión; historial local persistente (`NotificationsStorageService`).
- **Geofencing** (`GeofenceService`): rastreo GPS con `distanceFilter=50m`, alerta local contextual al ingresar a zona DBSCAN, cooldown de 30 minutos.
- **Administración** (`routes/admin.py` + `lib/roles/admin/`): dashboard con fl_chart y filtro temporal, estadísticas SIDPOL, predicción a 3 meses, gestión de usuarios (suspender/eliminar/filtrar) y módulo de Aprobaciones policiales.
- **Referencias:** FD03 §Módulos 4, 6-8 (RF-ADM, RF-NOT, RF-HIST, RN-08), FD05 §5.2.

---

# 6. Testing

## 6.1 Estrategia de Pruebas

Definida formalmente en [`docs/Plan_de_Pruebas.md`](Plan_de_Pruebas.md) (ISO/IEC/IEEE 29119-3 + SWEBOK): paradigma Shift-Left, niveles unitario/integración/sistema/aceptación, técnicas de partición de equivalencias y análisis de valores límite (BVA), y automatización por criterio de ROI (los flujos de negocio se automatizan; la interacción visual del mapa y el geofencing físico se validan manualmente en dispositivo).

Principio de aislamiento: toda la suite corre contra **mongomock** (BD en memoria) con dobles de prueba para Firebase, Resend y el motor IA — cero dependencia de servicios reales, apta para CI.

## 6.2 Resumen de Pruebas

Resultados completos en [`docs/Informe_de_Pruebas.md`](Informe_de_Pruebas.md):

| Indicador | Valor |
|---|---|
| Total de pruebas automatizadas | **82** (68 backend + 14 frontend) |
| Resultado | **100 % PASSED** |
| Análisis estático (`flutter analyze`) | 0 issues |
| Defectos detectados y corregidos en la iteración | 8 (D-01 crítico a D-08, todos cerrados) |
| Deuda técnica documentada | Autorización por token pendiente (CP-RF-005) |

## 6.3 Casos de Prueba

Las 7 suites y su correspondencia con los casos CP-RF del Plan:

| Suite | Pruebas | Cubre |
|---|---|---|
| `backend/tests/test_utils.py` | 24 | Turnos horarios (BVA), distritos fuzzy, bcrypt |
| `backend/tests/test_report_service.py` | 12 | Metadatos, límite diario, confirmar/rechazar + **regresión D-01** |
| `backend/tests/test_reports.py` | 5 | CP-RF-002, CP-RF-006, CP-RF-008, CP-RF-010 |
| `backend/tests/test_reports_policia.py` | 5 | CP-RF-003 (flujo HTTP), push con coordenadas, estados |
| `backend/tests/test_auth_api.py` | 9 | CP-RF-001, aprobación policial, anti-enumeración |
| `backend/tests/test_motor_ia.py` | 8 | Periodo mensual, filtros, atomicidad, cooldown 24 h |
| `backend/tests/test_maps_api.py` | 5 | Serialización, caché 60 s, ventana 60 días, SIN COORDENADA |
| `test/*.dart` (Flutter) | 14 | Smoke de arranque, SafetyButton, almacenamiento de notificaciones |

---

# 7. Documentación Complementaria

## 7.1 Guía de Despliegue

Documentada en `docs/Plan_Despliegue_Arquitectura.md` y resumida aquí:

1. **Backend (Railway):** conectar el repositorio → Railway detecta el `Procfile` → configurar las variables de entorno (§4.1) → cada push a `main` redeploya. Verificar el arranque en los logs (`Conexión a MongoDB inicializada`, primer cálculo DBSCAN).
2. **Datos oficiales:** ejecutar `extract_arcgis_data.py` + `import_arcgis_data.py` (periodicidad recomendada: mensual) y disparar `POST /api/map/generar_zonas_ia` o esperar la siguiente confirmación policial.
3. **App móvil:** `flutter build apk --release` (Android API 26+); el `ApiConfig.baseUrl` ya apunta a producción.
4. **Cachés a considerar:** backend 60 s por endpoint de mapa; app 15 min para zonas de riesgo.

## 7.2 Manual Técnico

El conocimiento técnico está distribuido así: arquitectura y decisiones → **FD04**; requerimientos y reglas de negocio → **FD03**; implementación, endpoints y métricas → **FD05**; calidad → **Plan e Informe de Pruebas**; árbol del código → **README**. El presente FD06 §5 resume cada módulo con sus archivos fuente y referencias cruzadas.

## 7.3 Manual de Usuario

Guía operativa por rol (apoyada por el tutorial interactivo integrado en la app):

- **Ciudadano:** iniciar sesión → el mapa muestra su posición, las zonas de riesgo del mes vigente y las alertas confirmadas; usar los chips para alternar capas y el chip de período para el historial; pulsar **REPORTAR** ante un incidente (máx. 5/día); revisar el estado en *Reportes* y las alertas en *Alertas*.
- **Policía:** registrarse con datos de acreditación → esperar la aprobación del administrador → patrullar con el mapa sonar (los reportes en su zona de 1 km aparecen en ámbar) → validar o rechazar desde la pestaña *Validar* (se actualiza sola cada 30 s).
- **Administrador:** revisar *Aprobaciones* para las solicitudes policiales; monitorear el *Dashboard* (estadísticas en vivo, Big Data SIDPOL, predicción a 3 meses); gestionar usuarios (suspender/eliminar).

## 7.4 Funcionalidades Especiales

- **Radar sonar policial:** tres ondas sincronizadas por un solo `AnimationController` con desfases de ⅓ de ciclo — 60 fps sin recrear controladores (claves estables en los `Marker`).
- **Auto-filtrado por periodo:** las zonas llevan `anio_periodo`/`mes_periodo` y el mapa ciudadano ajusta su filtro automáticamente al periodo calculado por la IA.
- **Refresh en tiempo real sin parpadeo:** notifier en el mismo dispositivo + timers silenciosos entre dispositivos (30 s policía / 60 s ciudadano).
- **Cooldowns inteligentes:** 30 min geofencing local, 24 h notificación de mapa (persistido en `db.config`).
- **Modo simulación GPS:** joystick de pruebas integrado en el mapa ciudadano para QA de geofencing sin desplazamiento físico.

---

# 8. Organización del Proyecto

## 8.1 Estructura de Carpetas

```text
sgeo_pp/
├── lib/                    # Frontend Flutter
│   ├── core/               # config (ApiConfig), services (7), theme, widgets del design system
│   ├── features/auth/      # Login, registro, splash
│   └── roles/              # user/ (6 módulos) · police/ (4) · admin/ (5, incl. aprobaciones)
├── backend/                # API FastAPI + IA
│   ├── routes/             # 6 routers REST
│   ├── services/           # report, analytics, email
│   ├── models/ · utils/ · config/
│   ├── scripts_iniciales/  # setup_db + ETL ArcGIS
│   ├── tests/              # 68 pruebas pytest
│   ├── motor_ia_zonas_riesgo.py · predictive_context_engine.py · firebase_service.py
│   └── main.py · Procfile · requirements.txt · .env.example
├── test/                   # 14 pruebas flutter_test
├── docs/                   # Toda la documentación (ver §8.2)
├── android/ · ios/         # Plataformas nativas
└── README.md · pubspec.yaml
```

(El árbol comentado completo está en el README y en FD04 §6.2.)

## 8.2 Organización de la Documentación

| Documento | Contenido | Cuándo consultarlo |
|---|---|---|
| `FD01` Factibilidad | Riesgos, factibilidades, análisis financiero (VAN/TIR/B-C) | Justificación económica y de viabilidad |
| `FD02` Visión | Posicionamiento, stakeholders, capacidades, prioridades | Entender el "por qué" y el "para quién" |
| `FD03` SRS | Requerimientos funcionales/no funcionales, reglas de negocio RN-01..08, casos de uso | Contrato de comportamiento del sistema |
| `FD04` SAD | Arquitectura 4+1, diagramas de secuencia, decisiones técnicas, deuda documentada | Diseño y estructura interna |
| `FD05` Proyecto Final | Implementación completa, endpoints, sprints, resultados, presupuesto | Estado real de lo construido |
| `FD06` Propuesta (este documento) | Índice maestro y propuesta consolidada | Punto de entrada |
| `Plan_de_Pruebas.md` | Estrategia QA ISO 29119-3, casos CP-RF | Antes de probar |
| `Informe_de_Pruebas.md` | Ejecución: 82 pruebas, defectos D-01..08, trazabilidad | Evidencia de calidad |
| `Plan_Despliegue_Arquitectura.md` | Despliegue en Railway/Atlas | Operaciones |
| `DIAGRAMAS.md` + `example/*.puml` | Diagramas PlantUML fuente | Material visual |
| `SCRUM.md` / `PRESENTACION.md` / `SQA_*` | Gestión ágil, exposición y calidad de iteración | Contexto académico |

---

# 9. Guía de Uso

## 9.1 Flujo de Lectura

- **Evaluador académico:** FD06 (este) → FD01 → FD02 → FD03 → FD04 → FD05 → Informe de Pruebas.
- **Desarrollador nuevo:** README → FD04 (§6.2 estructura) → FD06 §3.3 (puesta en marcha) → FD03 (reglas de negocio) → suites de tests como documentación ejecutable.
- **Interesado institucional:** FD06 §2 (resumen ejecutivo) → FD02 (visión) → FD05 §5.5 (resultados) → §7.3 (manual de usuario).

## 9.2 Referencias Rápidas

| Necesito... | Ir a |
|---|---|
| URL base de la API y endpoints | `lib/core/config/api_config.dart` / Swagger `{baseUrl}/docs` |
| Reglas de negocio vigentes | FD03 §IV.d (RN-01 a RN-08) |
| Parámetros del motor IA | FD05 §5.2.3 / `backend/motor_ia_zonas_riesgo.py` |
| Variables de entorno | `backend/.env.example` / FD06 §4.1 |
| Correr las pruebas | FD06 §4.3 / Informe de Pruebas §7 |
| Regenerar datos oficiales | FD06 §4.2 (scripts ETL) |
| Defectos históricos y su corrección | Informe de Pruebas §5 |
| Deuda técnica conocida | FD04 §7.1 (nota) / Informe de Pruebas §8.4 |

## 9.3 Mantenimiento de la Documentación

1. **Regla de sincronía:** todo cambio de comportamiento (regla de negocio, endpoint, parámetro del motor) debe reflejarse en el FD03/FD05 en el mismo pull request que el código.
2. **Control de versiones documental:** cada FD lleva su tabla de Control de Versiones; las revisiones agregan una fila nueva sin reescribir el historial.
3. **Pruebas como documentación viva:** las suites (`backend/tests/`, `test/`) son la especificación ejecutable de las reglas de negocio — un cambio de regla debe romper una prueba antes de romper producción.
4. **Cadencia recomendada:** revisión documental al cierre de cada sprint; re-ejecución del ETL y verificación del Informe de Pruebas antes de cada release.

---

# 10. Conclusiones

1. SGEO se presenta como una propuesta integral y verificable: cada afirmación de este informe está respaldada por código en el repositorio, por una prueba automatizada o por un documento FD trazable.
2. El ecosistema documental (FD01–FD06 + Plan/Informe de Pruebas + README) cubre el ciclo completo de ingeniería: factibilidad → visión → requerimientos → arquitectura → implementación → calidad → propuesta consolidada.
3. La calidad del producto está evidenciada objetivamente: 82 pruebas automatizadas en verde, análisis estático limpio, 8 defectos detectados y cerrados con regresión permanente del más crítico, y la deuda técnica restante documentada con plan de acción — no oculta.
4. La propuesta es operable desde hoy: el sistema está desplegado en Railway con datos oficiales del año vigente, y este documento deja instaladas las guías de despliegue, uso y mantenimiento para que un tercero (académico o institucional) pueda adoptarlo sin dependencia del autor.

---

# Anexos

- **Anexo A — Documentos del ciclo de vida:** FD01, FD02, FD03, FD04, FD05 (en `docs/`).
- **Anexo B — Evidencia de calidad:** `Plan_de_Pruebas.md`, `Informe_de_Pruebas.md`, suites `backend/tests/` y `test/`.
- **Anexo C — Diagramas fuente:** `DIAGRAMAS.md`, `example/arquitectura.puml`, `example/clases.puml`, `example/entidad_relacion.puml`.
- **Anexo D — Gestión y despliegue:** `SCRUM.md`, `Plan_Despliegue_Arquitectura.md`, `SQA_Informe_Iteracion.md`, `Arbol_Decision_Calidad.md`, `PRESENTACION.md`.
- **Anexo E — Datos y configuración:** `backend/.env.example`, `backend/scripts_iniciales/` (setup + ETL), `datos_historicos_tacna.json` (1,286 registros, enero–mayo 2026).
