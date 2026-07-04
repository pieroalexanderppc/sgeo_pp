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

**Documento Informe Ágil SCRUM de Proyecto**  
**Versión:** 1.0  

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha      | Motivo           |
|---------|-----------|--------------|--------------|------------|------------------|
| 1.0     | PP        | PP           | AF           | 04/07/2026 | Versión Original |

---

## ÍNDICE GENERAL

- [Objetivos](#objetivos)
- [1. Introducción](#1-introducción)
  - [1.1. Propósito del documento](#11-propósito-del-documento)
  - [1.2. Alcance del proyecto](#12-alcance-del-proyecto)
  - [1.3. Audiencia](#13-audiencia)
  - [1.4. Estructura del documento](#14-estructura-del-documento)
- [2. Visión](#2-visión)
  - [2.1. Resumen del producto](#21-resumen-del-producto)
  - [2.2. Principales características del producto](#22-principales-características-del-producto)
  - [2.3. Objetivos del negocio](#23-objetivos-del-negocio)
- [3. Organización y roles](#3-organización-y-roles)
  - [3.1. Equipo SCRUM](#31-equipo-scrum)
  - [3.2. Stakeholders](#32-stakeholders)
- [4. Backlog del Producto](#4-backlog-del-producto)
  - [4.1. Definición del Product Backlog](#41-definición-del-product-backlog)
  - [4.2. Historias de usuario clave](#42-historias-de-usuario-clave)
  - [4.3. Priorización de las historias de usuario](#43-priorización-de-las-historias-de-usuario)
- [5. Planificación de Sprints](#5-planificación-de-sprints)
  - [5.1. Ciclo de vida de los sprints](#51-ciclo-de-vida-de-los-sprints)
  - [5.2. Objetivos de Sprint](#52-objetivos-de-sprint)
  - [5.3. Sprint Backlog](#53-sprint-backlog)
  - [5.4. Reuniones clave del sprint](#54-reuniones-clave-del-sprint)
- [6. Definición de "Hecho" (Definition of Done - DoD)](#6-definición-de-hecho-definition-of-done---dod)
  - [6.1. Criterios de aceptación](#61-criterios-de-aceptación)
  - [6.2. Requisitos de calidad](#62-requisitos-de-calidad)
- [7. Gestión de Impedimentos](#7-gestión-de-impedimentos)
  - [7.1. Proceso para identificar y resolver impedimentos](#71-proceso-para-identificar-y-resolver-impedimentos)
  - [7.2. Escalación de problemas](#72-escalación-de-problemas)
- [8. Iteraciones](#8-iteraciones)
  - [8.2. Revisión de entregas](#82-revisión-de-entregas)
- [9. Métricas y seguimiento de progreso](#9-métricas-y-seguimiento-de-progreso)
  - [9.1. Burndown Chart](#91-burndown-chart)
  - [9.2. Velocidad del equipo](#92-velocidad-del-equipo)
  - [9.3. Revisión de progreso](#93-revisión-de-progreso)
- [10. Plan de Pruebas y control de calidad](#10-plan-de-pruebas-y-control-de-calidad)
  - [10.1. Pruebas en el marco de SCRUM](#101-pruebas-en-el-marco-de-scrum)
  - [10.2. Automatización de pruebas](#102-automatización-de-pruebas)
  - [10.3. Criterios de aceptación de historias](#103-criterios-de-aceptación-de-historias)
- [11. Riesgos y Gestión de cambios](#11-riesgos-y-gestión-de-cambios)
  - [11.1. Riesgos del proyecto](#111-riesgos-del-proyecto)
  - [11.2. Gestión del cambio](#112-gestión-del-cambio)
- [12. Conclusiones](#12-conclusiones)
  - [12.1. Reflexiones finales](#121-reflexiones-finales)
  - [12.2. Próximos pasos](#122-próximos-pasos)

---

# Objetivos

Este informe persigue los siguientes objetivos:

1. Documentar formalmente la adaptación del marco de trabajo SCRUM al desarrollo del sistema SGEO bajo un modelo de equipo unipersonal (Solopreneur), evidenciando que las prácticas ágiles son aplicables y verificables incluso sin un equipo múltiple.
2. Registrar el Product Backlog completo, las historias de usuario con sus criterios de aceptación y su priorización por valor de negocio.
3. Trazar los cuatro sprints ejecutados — objetivos, backlog, entregables y revisión — contra el estado real del repositorio.
4. Establecer la Definición de Hecho (DoD), las métricas de seguimiento y el proceso de gestión de impedimentos usados durante el proyecto, con los impedimentos reales encontrados y su resolución.
5. Vincular la gestión ágil con el aseguramiento de calidad (Plan de Pruebas ISO 29119-3 y suite de 82 pruebas automatizadas).

---

# 1. Introducción

## 1.1. Propósito del documento

Este documento describe cómo se aplicó el marco ágil SCRUM a lo largo del ciclo de vida del proyecto SGEO: la organización del equipo y sus roles, la construcción y priorización del Product Backlog, la planificación y ejecución de los sprints, la Definición de Hecho, las métricas de progreso y la gestión de impedimentos, riesgos y cambios. Complementa la documentación de ingeniería (FD01–FD06) con la perspectiva de **gestión del proceso**.

## 1.2. Alcance del proyecto

El alcance gestionado bajo SCRUM abarca el producto completo descrito en el FD05: aplicación móvil Flutter con tres interfaces por rol, backend FastAPI con motor de IA espacial (DBSCAN) y predictivo (LinearRegression + motor contextual), pipeline ETL de datos oficiales SIDPOL, sistema de notificaciones push/geofencing, y la suite de pruebas automatizadas. El periodo gestionado corre de marzo a julio de 2026.

## 1.3. Audiencia

- **Evaluador académico:** verifica la aplicación metodológica del marco ágil.
- **Desarrollador/mantenedor futuro:** entiende cómo se organizó el trabajo, dónde está el backlog y cómo continuar iterando.
- **Stakeholders institucionales (PNP, Municipalidad):** conocen el proceso de entrega incremental y los mecanismos de retroalimentación.

## 1.4. Estructura del documento

Las secciones 2–4 cubren la visión, la organización y el backlog; las secciones 5–8 la mecánica de sprints y la definición de terminado; las secciones 9–11 las métricas, la calidad y los riesgos; la sección 12 cierra con reflexiones y próximos pasos.

---

# 2. Visión

## 2.1. Resumen del producto

SGEO es una plataforma móvil táctica que previene el crimen en la provincia de Tacna mediante la combinación de reportes ciudadanos geolocalizados, validación policial en campo y dos motores de inteligencia artificial que operan sobre los datos oficiales vigentes del SIDPOL (servicio ArcGIS REST del MININTER). El ciudadano ve un mapa de riesgo actual y recibe alertas preventivas; el policía valida incidentes dentro de su radio de patrullaje de 1 km; el administrador supervisa métricas, predicciones y aprueba las cuentas policiales.

## 2.2. Principales características del producto

- Mapa de zonas de riesgo calculadas por DBSCAN **exclusivamente con el mes más reciente de datos** (nunca acumulados históricos ambiguos).
- Reportes ciudadanos en 3 toques con límite antispam de 5/día y agrupación de duplicados en 500 m.
- Validación policial con radar sonar de 1 km, auto-refresh de 30 s y cascada de confirmación (historial + push + recalculo IA).
- Safety Score 0-100, insights contextuales y franjas horarias seguras vía 5 endpoints predictivos.
- Notificaciones push FCM con navegación contextual y cooldowns inteligentes (30 min geofencing, 24 h mapa).
- Dashboard administrativo con Big Data SIDPOL y predicción a 3 meses por distrito.

## 2.3. Objetivos del negocio

| Objetivo | Métrica asociada |
|---|---|
| Reducir el tiempo de recolección y validación de incidentes en 40% | Tiempo reporte→validación (app vs. canal telefónico 105) |
| Optimizar el patrullaje preventivo | Ahorro proyectado S/ 16,500/año en combustible (FD01 §5) |
| Elevar la prevención civil | Usuarios activos recibiendo alertas de geofencing |
| Depurar falsas alarmas | Tasa de reportes rechazados/agrupados por la validación policial |

---

# 3. Organización y roles

## 3.1. Equipo SCRUM

El proyecto se ejecutó bajo el modelo **Solopreneur**: una sola persona (Piero Alexander Paja de la Cruz) asumió los tres roles SCRUM de forma explícita y separada en el tiempo, con el docente del curso actuando como validador externo del incremento. Esta adaptación es una práctica reconocida para proyectos académicos y MVPs unipersonales: los roles no se eliminan, se **calendarizan** (por ejemplo, la revisión de backlog se hace con "sombrero de Product Owner" al inicio de cada sprint, nunca mientras se codifica).

### 3.1.1. Product Owner

**Rol asumido por:** P. Paja (sombrero de negocio) con retroalimentación del docente A. Flor.
**Responsabilidades ejercidas:** definir y priorizar el Product Backlog por valor de negocio (seguridad ciudadana primero, analítica después), aceptar o rechazar incrementos contra los criterios de aceptación, y decidir los cambios de alcance (p. ej., reemplazar el filtro histórico acumulado por la ventana mensual de zonas — decisión de producto tomada al detectar que las zonas con datos antiguos daban "información ambigua al usuario").

### 3.1.2. Scrum Master

**Rol asumido por:** P. Paja (sombrero de proceso).
**Responsabilidades ejercidas:** velar por el cumplimiento del DoD antes de cerrar historias, registrar y resolver impedimentos (ver §7), proteger el sprint de cambios de alcance intermedios (los pedidos nuevos entran al backlog, no al sprint en curso, salvo defectos bloqueantes), y conducir las retrospectivas al cierre de cada sprint.

### 3.1.3. Equipo de Desarrollo

**Rol asumido por:** P. Paja (sombrero técnico), cubriendo las cuatro disciplinas del stack:
- **Mobile:** Flutter/Dart (3 interfaces por rol, design system Premium Tactical Dark).
- **Backend:** Python/FastAPI (6 routers, servicios, validación Pydantic).
- **Data/IA:** scikit-learn (DBSCAN, LinearRegression), pandas, pipeline ETL ArcGIS.
- **DevOps/QA:** Railway, MongoDB Atlas, Firebase, pytest + flutter_test.

## 3.2. Stakeholders

| Stakeholder | Interés | Participación en el proceso |
|---|---|---|
| Docente del curso (Msc. A. Flor) | Rigor metodológico y calidad del producto | Sprint Review académica; aprueba los FD |
| Ciudadanía de Tacna | Mapa vigente, alertas útiles, reporte sin fricción | Usuarios finales del incremento; feedback de UX |
| PNP — Región Tacna | Validación confiable, patrullaje dirigido | Rol Policía; su flujo definió el sonar de 1 km |
| Municipalidad Provincial | Métricas para presupuesto de seguridad | Consumidor del dashboard administrativo |
| MININTER (proveedor de datos) | Uso correcto de datos abiertos | Fuente ArcGIS REST `SIDPOL_DELITOS_TOTAL` |

---

# 4. Backlog del Producto

## 4.1. Definición del Product Backlog

El Product Backlog se organizó en **6 épicas** ordenadas por valor. Su versión operativa vive en `docs/SCRUM.md` (checklist) y su especificación formal en el FD03 (requerimientos RF-* y reglas RN-*); este informe consolida el estado final:

| Épica | Descripción | Estado |
|---|---|---|
| E1. Autenticación y RBAC | Registro/login bcrypt, 3 roles, enrutamiento aislado, aprobación policial con correo | ✅ Completada |
| E2. UX Táctica y Reportes | Design system, captura GPS, creación de reportes con límite diario | ✅ Completada |
| E3. Validación Policial y Zonas | Confirmar/rechazar, radio 1 km con sonar, agrupación 500 m, cascada de confirmación | ✅ Completada |
| E4. IA y Dashboards | DBSCAN mensual, motor predictivo contextual, ETL SIDPOL, fl_chart + forecast | ✅ Completada |
| E5. Notificaciones y Geofencing | FCM por tópico, navegación contextual, geofencing local, historial persistente, cooldowns | ✅ Completada |
| E6. Calidad y Documentación | Suite de 82 pruebas, Plan/Informe de Pruebas, FD01–FD07 | ✅ Completada |

## 4.2. Historias de usuario clave

Formato: *Como [rol] quiero [acción] para [beneficio]*, con criterios de aceptación verificables (los criterios marcados 🧪 tienen prueba automatizada asociada).

### 4.2.1. Historia de usuario 1

> **HU-01 — Reportar un incidente georreferenciado**
> **Como** ciudadano, **quiero** reportar un hurto o robo desde mi ubicación actual en pocos toques, **para** alertar a la policía y a mi comunidad sin trámites burocráticos.

**Criterios de aceptación:**
1. 🧪 El reporte se persiste con estado `pendiente`, coordenadas GeoJSON `[lng, lat]`, turno horario y día de semana derivados de la hora de Lima.
2. 🧪 A partir del sexto reporte del día, el sistema responde HTTP 429 con mensaje claro.
3. 🧪 Un payload sin coordenadas es rechazado con HTTP 422 antes de tocar la base de datos.
4. El botón REPORTAR está siempre visible en la zona del pulgar; sin señal GPS muestra "Esperando tu ubicación GPS…".
5. El reporte aparece en "Mis Aportes" del mapa y en la pestaña Reportes con su estado.

*(Cobertura: `test_reports.py`, `test_report_service.py`; RF-REP-01, RN-04.)*

### 4.2.2. Historia de usuario 2

> **HU-02 — Validar reportes en mi zona de patrullaje**
> **Como** policía, **quiero** ver en tiempo real los reportes pendientes dentro de mi radio de patrullaje y confirmarlos o rechazarlos, **para** que solo los incidentes verificados alimenten el mapa público y la IA.

**Criterios de aceptación:**
1. El mapa táctico resalta el radio de 1 km con efecto sonar y muestra un contador de pendientes en zona; los datos se refrescan solos cada 30 s sin parpadeo.
2. 🧪 Confirmar ejecuta la cascada completa: copia al historial (`fuente="ciudadano"`), agrupación de duplicados en 500 m, push `incident` con coordenadas exactas y recalculo DBSCAN en background.
3. 🧪 Si la copia al historial falla, la confirmación se aborta (atomicidad) — regresión permanente del defecto D-01.
4. 🧪 Rechazar no dispara push ni IA, y el reporte rechazado jamás alimenta el historial analítico.
5. 🧪 Mi cuenta solo funciona tras la aprobación del administrador (403 con motivo si fue rechazada).

*(Cobertura: `test_reports_policia.py`, `test_report_service.py`, `test_auth_api.py`; RF-TAC-01..03, RN-01, RN-02, RN-07.)*

**Otras historias representativas del backlog:**

| ID | Historia (resumen) | Épica |
|---|---|---|
| HU-03 | Como ciudadano quiero ver las zonas de riesgo del mes vigente para decidir mis rutas | E4 |
| HU-04 | Como ciudadano quiero recibir una alerta automática al entrar a una zona de riesgo | E5 |
| HU-05 | Como ciudadano quiero que tocar una notificación me lleve al lugar del incidente | E5 |
| HU-06 | Como administrador quiero aprobar o rechazar (con motivo) las cuentas policiales | E1 |
| HU-07 | Como administrador quiero ver la predicción de incidentes a 3 meses por distrito | E4 |
| HU-08 | Como sistema quiero recalcular las zonas solo con el último mes de datos para no mostrar información obsoleta | E4 |
| HU-09 | Como ciudadano no quiero recibir "mapa actualizado" a cada rato (máx. 1 vez/día) | E5 |
| HU-10 | Como equipo quiero una suite de pruebas sin dependencias externas para validar cada cambio | E6 |

## 4.3. Priorización de las historias de usuario

Se aplicó **MoSCoW** combinado con valor/riesgo: primero lo que habilita el flujo núcleo (reportar→validar→alertar), luego la inteligencia, al final el pulido.

| Prioridad | Historias | Justificación |
|---|---|---|
| Must have | HU-01, HU-02, HU-03, E1 completa | Sin el ciclo reportar→validar→zonas no hay producto |
| Should have | HU-04, HU-05, HU-07 | Multiplican el valor preventivo y gerencial |
| Could have | HU-08, HU-09, tutorial, noticias | Calidad de la información y UX |
| Won't have (esta versión) | JWT middleware, recuperación de contraseña, panel web, Deep Learning | Roadmap documentado en FD03/FD06 |

---

# 5. Planificación de Sprints

## 5.1. Ciclo de vida de los sprints

Sprints de **3–5 semanas** (adaptados al calendario académico), cada uno con: Sprint Planning (selección del backlog y definición del objetivo) → ejecución con seguimiento diario → Sprint Review (demo del incremento en dispositivo real) → Retrospective (registro de lecciones en el repositorio). El incremento de cada sprint quedó integrado en `main` y desplegado en Railway.

## 5.2. Objetivos de Sprint

| Sprint | Periodo | Objetivo (Sprint Goal) |
|---|---|---|
| S1 — Fundación | Mar 2026 (sem. 3-5) | Entorno reproducible, esquema NoSQL validado y pipeline ETL de datos oficiales operativo |
| S2 — RBAC y UI Táctica | Abr 2026 (sem. 6-9) | Autenticación segura, tres interfaces aisladas por rol y flujo de validación policial completo |
| S3 — IA y Despliegue | May-Jun 2026 (sem. 10-14) | Motores DBSCAN y predictivo en producción, geofencing, FCM y dashboards |
| S4 — Estabilización y Calidad | Jun-Jul 2026 (sem. 15-17) | Rediseño UX por rol, vigencia mensual de zonas, corrección de defectos, suite de pruebas y cierre documental |

## 5.3. Sprint Backlog

Detalle de los ítems comprometidos y completados por sprint (trazable contra el historial git y FD05 §5.3):

**Sprint 1:** setup_db con validadores `$jsonSchema`; índices 2dsphere; solución a timeouts de `geolocator`; captura por coordenadas (sin dirección manual); ETL `extract/import_arcgis_data.py`.

**Sprint 2:** login/registro bcrypt; separación `lib/roles/{user,police,admin}`; design system Premium Tactical Dark; endpoints confirmar/rechazar; límite 5 reportes/día; flujo de aprobación policial con correo (Resend).

**Sprint 3:** motor DBSCAN con BackgroundTasks; motor predictivo contextual (4 clases, 5 endpoints con TTL); GeofenceService (50 m, cooldown 30 min); FCM en 3 estados de app; dashboards fl_chart + LinearRegression; despliegue Railway.

**Sprint 4:** rediseño del mapa policial (sonar 1 km, sin joystick, HUD, auto-refresh 30 s); rediseño del HUD ciudadano (REPORTAR central, chips, panel de periodo); vigencia mensual del motor + `anio_periodo`/`mes_periodo` + cooldown 24 h; ETL migrado a `SIDPOL_DELITOS_TOTAL` (provincia + patrimonio + año vigente); corrección de los defectos D-01..D-08; suite de 82 pruebas; Informe de Pruebas; actualización FD01–FD07.

## 5.4. Reuniones clave del sprint

### 5.4.1. Planificación del Sprint (Sprint Planning)

Al inicio de cada sprint (sombrero PO + Dev): se seleccionaron ítems del Product Backlog según el objetivo del sprint, se descompusieron en tareas técnicas y se estimaron en puntos de historia (Fibonacci 1-2-3-5-8). Salida: Sprint Backlog comprometido y Sprint Goal escrito.

### 5.4.2. Daily Standup (Daily Scrum)

Adaptación solo-dev: **bitácora diaria de 10 minutos** al iniciar la jornada respondiendo las tres preguntas clásicas (¿qué hice?, ¿qué haré?, ¿qué me bloquea?) sobre el tablero de tareas. Los bloqueos detectados se registraron como impedimentos (§7). El historial de commits de git actúa como evidencia del avance diario.

### 5.4.3. Revisión del Sprint (Sprint Review)

Demo del incremento **en dispositivo Android físico** contra los criterios de aceptación: en S2/S3 con los tres roles en paralelo (dos dispositivos para validar el flujo reporta→valida→alerta entre equipos); en S4 la revisión incluyó al docente (revisión académica) y la evidencia de la suite de pruebas en verde.

### 5.4.4. Retrospectiva del Sprint (Sprint Retrospective)

Formato *keep / drop / try*. Acuerdos que cambiaron el proceso:
- **S1 → S2:** dejar de editar archivos Dart con herramientas de reescritura de texto de shell (corrupción de caracteres en español); usar solo ediciones estructuradas.
- **S2 → S3:** los cálculos pesados jamás en el request handler → todo a `BackgroundTasks`.
- **S3 → S4:** "si no hay prueba, no está hecho": el defecto D-01 (validación de esquema en producción) evidenció que la validación manual no basta; se incorporó la suite automatizada al DoD.

---

# 6. Definición de "Hecho" (Definition of Done - DoD)

## 6.1. Criterios de aceptación

Una historia se considera **Hecha** únicamente cuando:

1. El código está integrado en la rama `main` del repositorio.
2. La funcionalidad es accesible desde la interfaz del rol correspondiente.
3. Los endpoints asociados responden correctamente ante datos válidos e inválidos (códigos 2xx/4xx del contrato).
4. `flutter analyze` reporta **cero issues** y los esquemas Pydantic validan sin advertencias.
5. Fue validada manualmente en emulador Android API 34 o dispositivo físico.
6. Las suites `pytest` (68) y `flutter test` (14) corren íntegramente en verde.
7. Si la historia cambió una regla de negocio, la documentación afectada (FD03/FD05) fue actualizada en el mismo ciclo.

## 6.2. Requisitos de calidad

- **Regresión bloqueada:** todo defecto corregido de severidad alta/crítica deja una prueba de regresión permanente (ejemplo: `test_regresion_confirmar_copia_historial_con_campos_del_schema` para D-01).
- **Sin fugas de recursos:** todo `Timer`, listener y `AnimationController` debe cancelarse/liberarse en `dispose()` (auditado en S4).
- **Aislamiento de pruebas:** ninguna prueba puede tocar servicios reales (MongoDB Atlas, FCM, Resend) — mongomock y dobles de prueba obligatorios.
- **UX sin bloqueos:** el hilo principal de la app no debe congelarse (claves estables en marcadores del mapa, refresh silencioso sin spinners intrusivos).

---

# 7. Gestión de Impedimentos

## 7.1. Proceso para identificar y resolver impedimentos

Los impedimentos se detectaron en la bitácora diaria o durante las pruebas en dispositivo, se registraron con causa raíz y se resolvieron priorizando los bloqueantes del Sprint Goal. Registro real del proyecto:

| Impedimento | Sprint | Causa raíz | Resolución |
|---|---|---|---|
| Timeouts del plugin `geolocator` en Android | S1 | Configuración nativa y espera indefinida del fix GPS | Ajuste de precisión/timeouts y flujo de espera explícito en UI |
| Corrupción de caracteres (mojibake) al editar Dart con scripts de shell | S2 | Reescritura de texto sin respetar UTF-8 | Prohibido en retrospectiva; solo ediciones estructuradas |
| ANR en el mapa policial con muchos marcadores | S4 | `AnimationController` recreado en cada `setState` por falta de keys estables | `ValueKey` por marcador + un solo controller compartido para el sonar |
| "Document failed validation" al confirmar reportes (D-01) | S4 | Campos sin sufijo `_hecho` y `fuente` fuera del enum del `$jsonSchema` | Corrección en `report_service.py` + prueba de regresión |
| Query ArcGIS retornaba 400 | S4 | El campo `ESTADO_COORD` no existe en `SIDPOL_DELITOS_TOTAL` | Depuración incremental del WHERE/outFields; campo derivado en el import |
| Botones ocultos tras la barra de navegación | S4 | El body del `SlidingUpPanel` usa la altura completa de pantalla | Reposicionamiento de los overlays (`bottom: 104/156`) |

## 7.2. Escalación de problemas

Ruta de escalación adaptada: (1) investigación técnica propia con time-box de medio día; (2) consulta de documentación oficial/issues del paquete; (3) decisión de producto — si el impedimento compromete el Sprint Goal, el PO decide recortar alcance o reemplazar la solución (ejemplo: al no existir datos SIDPOL del mes corriente, se adoptó la detección automática del "último mes con datos" en lugar de un filtro fijo por año); (4) para asuntos académicos o de alcance, escalación al docente en la revisión de sprint.

---

# 8. Iteraciones

El producto se construyó en cuatro iteraciones incrementales; cada una entregó un incremento funcional desplegable (no prototipos):

| Iteración | Incremento entregado |
|---|---|
| S1 | Base de datos validada + ETL con datos oficiales importados |
| S2 | App con login, tres roles aislados y ciclo reportar→validar operativo |
| S3 | IA espacial/predictiva en producción + alertas push/geofencing + dashboards |
| S4 | Producto estabilizado: UX final, zonas vigentes al mes, 8 defectos cerrados, 82 pruebas, documentación completa |

## 8.2. Revisión de entregas

Cada incremento se revisó contra su Sprint Goal en dispositivo real y quedó evidenciado en: el historial de commits de `main`, el despliegue activo en Railway, el `docs/SQA_Informe_Iteracion.md` (calidad por iteración), y — para S4 — el `docs/Informe_de_Pruebas.md` con el dictamen APROBADO. Las observaciones de cada revisión (p. ej., "los puntos SIDPOL no deben verse en el mapa policial", "el buscador del mapa no aporta valor") entraron al backlog y se resolvieron en la iteración siguiente o en la misma si eran defectos.

---

# 9. Métricas y seguimiento de progreso

## 9.1. Burndown Chart

Seguimiento por puntos de historia restantes al cierre de cada semana del sprint (registro del tablero). Patrón observado y lección:

```
S2 (30 pts):  30 → 26 → 18 → 9 → 0     (quema estable)
S3 (42 pts):  42 → 40 → 35 → 22 → 8 → 0 (arranque lento por curva DBSCAN/FCM)
S4 (34 pts):  34 → 24 → 15 → 6 → 0     (quema rápida: deuda de UX bien acotada)
```

La meseta inicial de S3 (investigación de FCM en 3 estados y parámetros haversine) motivó el acuerdo de retrospectiva de reservar *spikes* de investigación explícitos al planificar historias con tecnología nueva.

## 9.2. Velocidad del equipo

| Sprint | Puntos comprometidos | Puntos completados | Velocidad |
|---|---|---|---|
| S1 | 24 | 22 | 22 |
| S2 | 30 | 30 | 30 |
| S3 | 42 | 40 | 40 |
| S4 | 34 | 34 | 34 |

Velocidad promedio: **~31 pts/sprint**, con tendencia estable tras S2 — útil como referencia de capacidad para planificar el roadmap (JWT, recuperación de contraseña) en sprints futuros.

## 9.3. Revisión de progreso

Indicadores objetivos al cierre del proyecto:

| Indicador | Valor |
|---|---|
| Épicas completadas | 6/6 |
| Historias Must/Should completadas | 100 % |
| Defectos abiertos de severidad alta/crítica | 0 (8 detectados y cerrados en S4) |
| Pruebas automatizadas | 82/82 en verde |
| Análisis estático | 0 issues |
| Incremento desplegado | Backend en Railway + APK instalable |

---

# 10. Plan de Pruebas y control de calidad

## 10.1. Pruebas en el marco de SCRUM

La calidad se integró al flujo ágil bajo el paradigma **Shift-Left** (Plan de Pruebas §2.1): la validación de contratos Pydantic y esquemas `$jsonSchema` ocurre desde el diseño; cada historia incorpora sus pruebas en el mismo sprint (DoD §6.1.6); y la Sprint Review exige la demo sobre el incremento real, no sobre mocks. El detalle normativo completo (niveles, técnicas BVA/particiones, criterios de parada) está en `docs/Plan_de_Pruebas.md` (ISO/IEC/IEEE 29119-3).

## 10.2. Automatización de pruebas

- **Backend (68 pruebas, pytest):** unitarias de utilitarios y servicios + integración HTTP con `TestClient` sobre mongomock; Firebase/Resend/motor IA reemplazados por dobles — la suite corre en ~4 s sin credenciales, apta para el pipeline CI propuesto en FD06 §4.3.
- **Frontend (14 pruebas, flutter_test):** smoke de arranque, widget del design system y persistencia local de notificaciones.
- **Estático:** `flutter analyze` en cero issues como gate del DoD.
- **Manual acotado por ROI:** geofencing físico, render de gráficas e interacción táctil del mapa se validan en dispositivo (documentado como PARCIAL/MANUAL en la trazabilidad del Informe de Pruebas).

## 10.3. Criterios de aceptación de historias

Cada historia define criterios verificables (ver HU-01/HU-02 en §4.2) y su aceptación sigue la regla: **criterio de negocio → prueba automatizada nombrada → PASSED**. La matriz completa de trazabilidad historia↔CP-RF↔prueba está en `docs/Informe_de_Pruebas.md` §4; los 10 casos CP-RF del plan quedaron 6 PASSED automatizados, 2 parciales (parte física manual) y 1 pendiente por deuda técnica de autorización (CP-RF-005), decisión registrada y priorizada en el backlog.

---

# 11. Riesgos y Gestión de cambios

## 11.1. Riesgos del proyecto

Riesgos gestionados durante los sprints (detalle económico/técnico en FD01 §2):

| Riesgo | Prob. | Impacto | Mitigación aplicada |
|---|---|---|---|
| Cambio del servicio ArcGIS del MININTER | Media | Alto | Extractor con validación de distribución mensual y reporte de errores por corrida |
| Reportes falsos (trolleo) | Alta | Medio | Triple barrera: 5/día + validación policial 1 km + agrupación 500 m |
| Zonas de riesgo obsoletas que desinforman | Media | Alto | Ventana de vigencia mensual del motor (HU-08) |
| Saturación de notificaciones (fatiga de alertas) | Alta | Medio | Cooldowns 30 min / 24 h (HU-09) |
| Regresiones al refactorizar | Media | Alto | Suite de 82 pruebas + regresión obligatoria por defecto crítico |
| Deuda de autorización por token | — | Alto (en despliegue masivo) | Documentada en FD03/FD04/FD06; primera prioridad del roadmap |

## 11.2. Gestión del cambio

- **Cambios de alcance:** entran por el Product Backlog y se priorizan en el siguiente Sprint Planning; nunca interrumpen el sprint en curso salvo defectos bloqueantes (regla del Scrum Master).
- **Control de versiones del código:** Git con integración continua a `main`; cada push despliega el backend en Railway.
- **Control de versiones documental:** cada FD lleva su tabla de Control de Versiones; los cambios agregan filas sin reescribir el historial.
- **Cambios de reglas de negocio:** requieren actualizar FD03 (RN-*) + la prueba automatizada correspondiente en el mismo ciclo (regla "la prueba se rompe antes que producción", FD06 §9.3).
- **Ejemplos reales gestionados:** migración del ETL a `SIDPOL_DELITOS_TOTAL` (cambio de proveedor de datos), reemplazo del filtro histórico por vigencia mensual (cambio de regla RN-05), y rediseño del HUD ciudadano (cambio de UX aprobado por el PO tras la review).

---

# 12. Conclusiones

## 12.1. Reflexiones finales

1. **SCRUM es viable en modo Solopreneur** cuando los roles se ejercen de forma explícita y calendarizada: la separación de "sombreros" evitó tanto el sobre-diseño (PO recortando alcance) como el descontrol técnico (SM protegiendo el sprint y el DoD).
2. **El DoD con pruebas automatizadas fue el punto de inflexión del proyecto:** los tres primeros sprints dependían de validación manual y un defecto crítico (D-01) llegó a producción; tras incorporar la suite al DoD en S4, los 8 defectos de la iteración se detectaron y cerraron con evidencia, y el más grave quedó blindado por regresión.
3. **Las retrospectivas produjeron cambios de proceso medibles** (prohibición de ediciones de texto crudo, BackgroundTasks obligatorios, spikes de investigación), demostrando mejora continua real y no ceremonial.
4. **La entrega incremental protegió el valor:** cada sprint dejó un producto desplegable, lo que permitió que los cambios de rumbo (vigencia mensual de zonas, rediseño del HUD) se tomaran con el sistema funcionando y no sobre especulación.

## 12.2. Próximos pasos

Backlog priorizado para las siguientes iteraciones (velocidad de referencia: ~31 pts/sprint):

| Prioridad | Ítem | Origen |
|---|---|---|
| 1 | Autenticación JWT con middleware de autorización por rol en todos los endpoints | Deuda técnica CP-RF-005 |
| 2 | Pipeline CI (GitHub Actions) con las suites como gate de merge | Propuesta FD06 §4.3 |
| 3 | Recuperación de contraseña por correo (infraestructura Resend ya operativa) | RF-AUT-04 diferido |
| 4 | Cron mensual de re-extracción ArcGIS + regeneración de zonas | Recomendación FD05 §9.5 |
| 5 | Pruebas de carga (Locust/k6) sobre los endpoints geoespaciales | Plan de Pruebas §2.2 |
| 6 | Registro de auditoría (`audit_log`) para acciones críticas | FD05 §9.8, Ley N° 29733 |
| 7 | Publicación en Google Play (piloto cerrado con PNP/Municipalidad) | FD01 §4.3 |

---

**Referencias cruzadas:** FD01 (factibilidad y riesgos), FD03 (backlog formal RF/RN), FD04 (arquitectura), FD05 (implementación y cronograma), FD06 (mapa documental), `docs/SCRUM.md` (checklist operativo), `docs/SQA_Informe_Iteracion.md` (calidad por iteración), `docs/Plan_de_Pruebas.md` e `docs/Informe_de_Pruebas.md` (evidencia QA).
