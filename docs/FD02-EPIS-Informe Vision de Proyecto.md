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

**Documento de Visión**  
**Versión:** 1.0  

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha      | Motivo                             |
|---------|-----------|--------------|--------------|------------|------------------------------------|
| 1.0     | PP        | PP           | AF           | 13/03/2026 | Versión Original                   |

---

## ÍNDICE GENERAL

1. [Introducción](#1-introducción)
   - 1.1. [Propósito](#11-propósito)
   - 1.2. [Alcance](#12-alcance)
   - 1.3. [Definiciones, Siglas y Abreviaturas](#13-definiciones-siglas-y-abreviaturas)
   - 1.4. [Referencias](#14-referencias)
   - 1.5. [Visión General](#15-visión-general)
2. [Posicionamiento](#2-posicionamiento)
   - 2.1. [Oportunidad de negocio](#21-oportunidad-de-negocio)
   - 2.2. [Definición del problema](#22-definición-del-problema)
3. [Descripción de los interesados y usuarios](#3-descripción-de-los-interesados-y-usuarios)
   - 3.1. [Resumen de los interesados](#31-resumen-de-los-interesados)
   - 3.2. [Resumen de los usuarios](#32-resumen-de-los-usuarios)
   - 3.3. [Entorno de usuario](#33-entorno-de-usuario)
   - 3.4. [Perfiles de los interesados](#34-perfiles-de-los-interesados)
   - 3.5. [Perfiles de los Usuarios](#35-perfiles-de-los-usuarios)
   - 3.6. [Necesidades de los interesados y usuarios](#36-necesidades-de-los-interesados-y-usuarios)
4. [Vista General del Producto](#4-vista-general-del-producto)
   - 4.1. [Perspectiva del producto](#41-perspectiva-del-producto)
   - 4.2. [Resumen de capacidades](#42-resumen-de-capacidades)
   - 4.3. [Suposiciones y dependencias](#43-suposiciones-y-dependencias)
   - 4.4. [Costos y precios](#44-costos-y-precios)
   - 4.5. [Licenciamiento e instalación](#45-licenciamiento-e-instalación)
5. [Características del producto](#5-características-del-producto)
6. [Restricciones](#6-restricciones)
7. [Rangos de calidad](#7-rangos-de-calidad)
8. [Precedencia y Prioridad](#8-precedencia-y-prioridad)
9. [Otros requerimientos del producto](#9-otros-requerimientos-del-producto)
   - a) [Estándares legales](#a-estándares-legales)
   - b) [Estándares de comunicación](#b-estándares-de-comunicación)
   - c) [Estándares de cumplimiento de la plataforma](#c-estándares-de-cumplimiento-de-la-plataforma)
   - d) [Estándares de calidad y seguridad](#d-estándares-de-calidad-y-seguridad)
[CONCLUSIONES](#conclusiones)
[RECOMENDACIONES](#recomendaciones)
[BIBLIOGRAFÍA](#bibliografía)
[WEBGRAFÍA](#webgrafía)

---

## 1. Introducción

### 1.1. Propósito
Este documento de visión define los objetivos, alcance y características principales del proyecto **"SGEO — Sistema de Geolocalización de Inseguridad Ciudadana con Machine Learning Predictivo y Espacial"**, diseñado específicamente para abordar la crisis de seguridad en la región de Tacna, Perú. Está dirigido a los stakeholders del proyecto, incluyendo desarrolladores, la Policía Nacional del Perú (PNP), autoridades municipales, y la comunidad civil.

El sistema busca revolucionar la forma en que los ciudadanos interactúan con la seguridad de su entorno, combinando inteligencia artificial, reportes colaborativos (crowdsourcing) y la ingesta masiva de Big Data gubernamental oficial (SIDPOL).

### 1.2. Alcance
El proyecto abarca el desarrollo completo de un ecosistema móvil multiplataforma y un backend inteligente. Las entregas clave incluyen:
- **Desarrollo Frontend Móvil:** Construcción en Flutter (SDK ^3.11.3, Dart) bajo el sistema de diseño "Premium Tactical Dark", separando estrictamente tres interfaces nativas para Ciudadanos, Policías y Administradores, con enrutamiento dinámico basado en el atributo `rol` almacenado en `SharedPreferences`.
- **Implementación de Machine Learning:** Uso de Scikit-Learn para clustering espacial con el algoritmo **DBSCAN** (`epsilon=150m`, `min_samples=5`, métrica Haversine, `algorithm='ball_tree'`) para delimitar zonas de riesgo con radios dinámicos (150m–350m); **LinearRegression** para predicciones mensuales de incidentes por distrito; y el **Motor Predictivo Contextual** (`predictive_context_engine.py`) con cuatro clases especializadas: `SafetyScoreCalculator`, `TemporalAnalyzer`, `InsightGenerator` y `SafeHoursCalculator`.
- **APIs REST:** Backend en FastAPI (`fastapi==0.104.1`) con seis módulos de rutas: autenticación (`/api/auth`), reportes (`/api/reportes`), mapas (`/api/map`), predictivo (`/api/predictive` con 5 endpoints), usuarios (`/api/users`) y administración (`/api/admin`).
- **ETL Histórico:** Scripts `extract_arcgis_data.py` e `import_arcgis_data.py` para ingestión de datos ArcGIS/SIDPOL. Dataset histórico `datos_historicos_tacna.json` (~3.4 MB) con registros criminológicos 2018-2026.
- **Sistema de Geofencing y Alertas Push:** Servicio `GeofenceService` implementado en Flutter con seguimiento GPS continuo (`distanceFilter=50m`, `LocationAccuracy.high`), detección de ingreso a zonas DBSCAN, cooldown de 30 minutos, y alertas contextuales con información del turno horario. Firebase Cloud Messaging (FCM) para notificaciones push masivas por tópico (`alertas_ciudadanos`).

### 1.3. Definiciones, Siglas y Abreviaturas
- **SGEO:** Sistema de Geolocalización de Inseguridad Ciudadana.
- **AI / IA:** Inteligencia Artificial.
- **ML:** Aprendizaje Automático (Machine Learning).
- **DBSCAN:** Density-Based Spatial Clustering of Applications with Noise (Algoritmo de clustering).
- **SIDPOL:** Sistema de Información Policial del Estado Peruano.
- **FCM:** Firebase Cloud Messaging.
- **ETL:** Extracción, Transformación y Carga de datos.
- **RBAC:** Role-Based Access Control (Control de Acceso Basado en Roles).
- **Geofencing:** Perímetro virtual para un área geográfica del mundo real.

### 1.4. Referencias
- IEEE. (2019). IEEE Standard for Software and Systems Engineering - Life Cycle Processes - Requirements Engineering. IEEE Std 29148-2018.
- Documentación Oficial de Flutter (v3.11+).
- Scikit-Learn Machine Learning in Python, Pedregosa et al., JMLR 12, pp. 2825-2830, 2011.

### 1.5. Visión General
El documento está estructurado en nueve secciones principales que describen desde el posicionamiento estratégico del sistema predictivo hasta los requerimientos específicos de despliegue móvil, rendimiento de la API en la nube y estándares de seguridad para el manejo de los datos.

---

## 2. Posicionamiento

### 2.1. Oportunidad de negocio
En el contexto actual de la ciudad de Tacna, la percepción de inseguridad ciudadana está en aumento. Existe un déficit de herramientas preventivas de fácil acceso que logren capitalizar la inteligencia comunitaria.

La oportunidad se fundamenta en tres pilares principales:
- **Democratización de la Prevención:** Las personas tienen derecho a saber de manera inmediata y visual cuáles son las rutas seguras. SGEO reemplaza la información desordenada en redes sociales con un mapa validado oficialmente.
- **Evolución del Patrullaje (Patrullaje Predictivo):** El Comando Policial de Tacna (PNP) dejará de reaccionar al delito. Al poseer un algoritmo de ML Predictivo sobre la historia criminalística desde 2018, pueden dirigir sus limitados recursos logísticos hacia distritos específicos con alto riesgo futuro proyectado, ahorrando combustible y tiempo.
- **Posicionamiento Cívico-Digital:** Consolida un puente directo entre el Estado Peruano, la municipalidad, la policía y el ciudadano a través de su dispositivo móvil, modernizando radicalmente la infraestructura social de Tacna.

### 2.2. Definición del problema
La región de Tacna enfrenta desafíos críticos:
- **Tiempos de latencia y burocracia:** Los ciudadanos se desaniman de realizar denuncias formales por procesos extensos. SGEO permite realizar reportes visuales geoespaciales en menos de tres clics.
- **Información estadística estática:** Existen datos de la Unidad de Flagrancia y SIDPOL, pero son reportes en Excel poco intuitivos que no benefician al peatón.
- **Sistemas sin validación táctica:** Herramientas similares sufren de reportes falsos. SGEO soluciona esto aislando el rol de Policía, que filtra y certifica los incidentes reportados por civiles en un radio de 3 kilómetros.

---

## 3. Descripción de los interesados y usuarios

### 3.1. Resumen de los interesados
- **Municipalidad Provincial de Tacna (Sponsor Potencial):** Interesados en métricas de Big Data que justifiquen su presupuesto en seguridad ciudadana.
- **Comando Policial PNP (Tácticos):** Responsables del uso logístico de la aplicación, supervisores directos del mapeo en vivo y dueños de la validación.
- **Ministerio Público y Poder Judicial:** Generadores pasivos de la información de base a través de sus sistemas de transparencia.

### 3.2. Resumen de los usuarios
- **Ciudadanos (70%):** Residentes de Tacna que usarán la aplicación diariamente para planificar rutas seguras, leer el Feed RSS de noticias de seguridad y reportar robos o accidentes in-situ.
- **Policías (25%):** Efectivos activos que tendrán instalada la aplicación con un panel diferencial (Vista de Validación y Dashboard de 3km) para auditar el mapa cívico en tiempo real.
- **Administradores / Inteligencia Policial (5%):** Jefes operativos con acceso a los Dashboards Avanzados (fl_chart), gestión gráfica de la base de usuarios y tableros predictivos de Machine Learning.

### 3.3. Entorno de usuario
- **Multidispositivo y móvil-first:** Operatividad central en iOS y Android bajo el ecosistema de UI "Premium Tactical Dark".
- **Hardware de geolocalización:** Uso intensivo pero optimizado (battery-friendly) de los sensores GPS.
- **Restricciones de red:** La app manejará caché local de mapas y tiles OSM para funcionar incluso con redes móviles intermitentes (3G/4G/5G).

### 3.4. Perfiles de los interesados

**Alcalde / Comando Policial (Sponsor)**
- *Responsabilidades:* Implementación institucional de la plataforma a nivel ciudadano.
- *Criterios de éxito:* Reducción medible del crimen en polígonos históricamente peligrosos gracias a la redistribución predictiva.
- *Entregables de interés:* Reportes mensuales exportables de la Regresión Lineal y estadísticas del módulo Admin.

**Gerente de Seguridad Ciudadana (Operaciones)**
- *Responsabilidades:* Monitoreo del flujo de validaciones de los agentes en campo.
- *Criterios de éxito:* Alto volumen de reportes atendidos/validados por el serenazgo o policía. Reducción de falsas alarmas en un 90%.

### 3.5. Perfiles de los Usuarios

**Usuario Final - Ciudadano**
- *Nivel técnico:* Básico. Uso habitual de apps como WhatsApp o Waze.
- *Objetivos principales:* Identificar zonas rojas, crear un reporte de emergencia sin fricción, sentirse protegido gracias a las notificaciones proactivas del Geofence.
- *Frustraciones actuales:* Desconfianza, exceso de desinformación, burocracia para reportar zonas peligrosas.

**Usuario Final - Policía / Patrullero**
- *Nivel técnico:* Intermedio. 
- *Objetivos principales:* Visualizar en el mapa a las víctimas cercanas, agrupar reportes similares (DBSCAN de 500m), rechazar reportes troll y despachar patrullas de manera eficiente.
- *Herramientas de trabajo:* Panel especial en la App Móvil con listados de validación y mapa limpio.

**Administrador / Oficial de Inteligencia**
- *Nivel técnico:* Avanzado.
- *Objetivos principales:* Monitorear los clústeres delictivos a nivel macro, analizar Big Data del SIDPOL, visualizar las tendencias de Regresión Lineal de crímenes, y gestionar activaciones o baneos de cuentas de usuarios fraudulentos.

### 3.6. Necesidades de los interesados y usuarios
- **Ciudadanos:** Interfaz inmersiva, Dark Mode (ahorro de batería), y cero tecnicismos matemáticos (la IA debe mostrarle resultados visuales como "Zona Roja", no datos estadísticos complejos).
- **Policías:** Botones de acción táctica inmediatos ("Confirmar", "Rechazar", "Ignorar"). Ubicación satelital con lat/long exactos.
- **Administradores:** Dashboards interactivos, métricas cuantitativas, y sistemas estables de base de datos sin latencia.

---

## 4. Vista General del Producto

### 4.1. Perspectiva del producto
SGEO es un sistema autoconteido y completamente modularizado. Actúa como el centro neurálgico de información situacional. Emplea la arquitectura C/S (Cliente-Servidor) y una conexión directa M2M (Machine to Machine) hacia bases gubernamentales.

- **Integración Transparente:** La app extrae por debajo Data del Estado (SIDPOL) para entrenar su ML y cruza la información en vivo (reportes de la app) para emitir alertas Push por tópicos vía Firebase Admin SDK.
- **Microservicios (FastAPI):** Python permite cálculos pesados como DBSCAN y Linear Regression de manera asíncrona mediante `BackgroundTasks`, garantizando que la API nunca se bloquee frente a consultas HTTP de los usuarios móviles.

### 4.2. Resumen de capacidades

| Beneficio para el usuario | Características Técnicas |
|---------------------------|-----------------------------|
| Prevención pasiva automática | - Geofencing GPS continuo (`distanceFilter=50m`, `LocationAccuracy.high`).<br>- Alerta sonora local con cooldown de 30 minutos y mensaje contextual por turno horario (mañana/tarde/noche/madrugada). |
| Safety Score dinámico | - Cálculo escalar 0-100 en tiempo real basado en 4 factores: proximidad a zonas DBSCAN, densidad de incidentes en radio 1km, factor temporal por turno, tendencia distrital.<br>- Nivel de riesgo: Seguro (≥80, verde), Precaución (50-79, amarillo), Alto Riesgo (<50, rojo). |
| Eliminación del ruido policial | - Módulo Táctico Policial de validación con radio de 3km.<br>- Solo reportes con estado `confirmado` nutren el historial y el modelo DBSCAN final. |
| Visualización de Patrones de Crimen | - DBSCAN con `epsilon=150m`, `min_samples=5`, `algorithm='ball_tree'`, `metric='haversine'`.<br>- Radios dinámicos por hotspot (150m–350m) según densidad de incidentes. |
| Inteligencia Contextual | - 5 endpoints predictivos: `safety_score`, `temporal_analysis`, `context_insights`, `risk_forecast`, `safe_hours`.<br>- Insights automáticos (hasta 6 por consulta) personalizados por ubicación y hora. |
| Administración Proactiva e IA | - Dashboards analíticos con `fl_chart` (reportes por estado, por tipo).<br>- Predicción de incidentes por distrito a 3 meses vía LinearRegression sobre histórico SIDPOL 2018-2026. |
| Feed de Noticias de Seguridad | - Módulo de noticias en la interfaz del Ciudadano con contenido de seguridad ciudadana.<br>- Historial de notificaciones persistido localmente con `SharedPreferences`. |
| Acceso universal y fluido | - Frontend compilado a APK/AAB (Android) con tema "Premium Tactical Dark".<br>- Enrutamiento dinámico por rol (`ciudadano`, `policia`, `admin`/`administrador`). |

### 4.3. Suposiciones y dependencias
- **Dependencias externas:** Servicios de MongoDB Atlas operativos, disponibilidad del servicio Google Maps/OSM Tiles, y operatividad del sitio web del SIDPOL (para el scraping mensual).
- **Dependencias internas:** Mantenimiento de los modelos de Machine Learning (reentrenamiento periódico cada fin de mes), claves privadas SSL y credenciales Firebase.

### 4.4. Costos y precios
- **Inversión Total del Proyecto (Solopreneur 12 Meses):** S/ 23,540
  - Costos de Personal (Piero Paja, Full-Stack): S/ 18,000 (76%)
  - Costos del Ambiente (Cloud, Firebase, Mongo): S/ 2,040 (9%)
  - Costos Operativos (Fibra óptica, Energía): S/ 2,760 (12%)
  - Costos Generales (Licencias Google/Apple): S/ 740 (3%)
- **Análisis Financiero:**
  - Beneficios Tangibles Anuales: S/ 26,700 (Ahorro en patrullajes y procesos redundantes).
  - Relación B/C: 1.06
  - VAN: S/ 1,501 (Valor positivo)
  - TIR: > 13%

### 4.5. Licenciamiento e instalación
- **Modelo de licenciamiento:** Código abierto para los repositorios frontend y backend, excluyendo los credenciales del `.env` y el `firebase-adminsdk.json`.
- **Despliegue móvil:** Descarga gratuita en Google Play Store y Apple App Store.
- **Arquitectura de nube:** Backend dockerizado o subido directamente a PaaS (Railway). MongoDB Cluster autogestionado.

---

## 5. Características del producto
- **Motor de IA Espacial DBSCAN:** Configurado con `epsilon=150m` (equivalente a 0.15/6371.0 radianes), `min_samples=5`, `algorithm='ball_tree'` y `metric='haversine'`. Discrimina el "ruido" de reportes aislados y genera hotspots con nivel de riesgo (bajo/medio/alto/crítico) y radio dinámico entre 150m y 350m según el volumen de incidentes. Se ejecuta automáticamente cada vez que un Policía confirma un nuevo reporte, mediante `BackgroundTasks` de FastAPI.
- **Safety Score Dinámico (0-100):** Cálculo compuesto implementado en `SafetyScoreCalculator` con cuatro factores ponderados: (1) proximidad a zonas DBSCAN, (2) densidad de incidentes en radio 1km, (3) factor temporal por turno horario, (4) tendencia del distrito más cercano vía LinearRegression. Niveles: Seguro (≥80), Precaución (50-79), Alto Riesgo (<50).
- **Análisis Temporal Avanzado:** `TemporalAnalyzer` calcula distribución por hora (0-23h), día de la semana, turno horario (mañana/tarde/noche/madrugada) y tendencia mensual mediante regresión lineal sobre ventana de 3-6 meses.
- **Insights Contextuales Automáticos:** `InsightGenerator` genera hasta 6 recomendaciones personalizadas por ubicación y hora, con tipos: temporal, recomendación, tendencia, día_semana, proximidad; y severidades: info, warning, danger.
- **Predicción Temporal (LinearRegression):** `analytics_service.py` transforma el timeline mensual de incidentes en vectores numéricos para predecir los próximos 3 meses a nivel global y por distrito, identificando el distrito de mayor riesgo proyectado.
- **Geocercas Contextuales (Geofencing):** `GeofenceService` rastrea en background cada 50 metros desplazados (`distanceFilter=50m`); si el ciudadano cruza el radio calculado por el DBSCAN, emite una alerta local con información del turno horario actual y un cooldown de 30 minutos para evitar spam.
- **Autenticación con RBAC:** Middleware en Flutter valida el atributo `rol` persistido en `SharedPreferences` para enrutar a las interfaces nativas diferenciadas (`ciudadano`, `policia`, `admin`/`administrador`). El backend valida credenciales mediante Bcrypt y controla el estado de la cuenta (`activo`).
- **Módulo de Noticias:** Vista dedicada en la interfaz del Ciudadano con contenido de seguridad ciudadana actualizado.
- **Historial de Notificaciones:** Persistencia local de notificaciones recibidas (push y geofencing) mediante `SharedPreferences` a través del servicio `NotificationsStorageService`.

---

## 6. Restricciones
- **Técnicas:** Los algoritmos de scraping requieren mantenimiento si el Estado Peruano cambia las cabeceras HTML de sus portales.
- **Rendimiento:** El mapa interactivo debe renderizar no más de 1,000 marcadores simultáneos usando técnicas de Clustering visual para no agotar la RAM en Androids de gama baja.
- **Regulatorias:** No se expone información personal en el mapa, respetando la legislación peruana de Datos Personales (Ley N° 29733). Las ubicaciones de denuncias se anonimizan y randomizan a 5-10 metros de diferencia.

---

## 7. Rangos de calidad
- **Latencia de API:** Tiempo de respuesta del servidor (FastAPI) menor a 400ms para consultas regulares.
- **Precisión GPS:** Margen de error aceptable menor a 15 metros a cielo abierto.
- **Cobertura del Modelo de IA:** Se considerará exitoso si logra una curva `R^2` superior a 0.70 en las pruebas de validación cruzada para las proyecciones distritales.
- **Uptime Backend:** Mínimo de 99.8% mensual alojado en plataformas profesionales PaaS.

---

## 8. Precedencia y Prioridad

**Prioridad Alta (Crítico para MVP - Sprint 1 & 2):**
1. Autenticación y control de Sesiones (RBAC).
2. Funcionalidad core de Mapas y marcadores in-situ.
3. Creación y lectura de Reportes (Backend/Frontend).
4. Implementación del motor IA Espacial (DBSCAN).
5. Interfaz policial de validación de reportes.

**Prioridad Media (Adopción y Optimización - Sprint 3):**
1. Dashboards analíticos avanzados con `fl_chart`.
2. Geocercas en segundo plano para notificaciones automáticas de proximidad.
3. Tareas Cron para ingesta y scraping de bases (SIDPOL).
4. Motor IA Predictivo de Regresión Lineal.

**Prioridad Baja (Futuro - Roadmap):**
1. Integración completa de videocámaras municipales en el mapa.
2. Predicción multivariable mediante redes neuronales complejas (Deep Learning).

---

## 9. Otros requerimientos del producto

### a) Estándares legales
- Cumplimiento de la **Ley N° 29733** (Protección de Datos Personales del Perú): Registro de bases, almacenamiento seguro y anonimización de ubicaciones delictivas de los denunciantes.
- Uso legal de **Datos Abiertos** gubernamentales conforme a la ley de transparencia institucional.

### b) Estándares de comunicación
- Cifrado en tránsito: Toda comunicación entre Flutter y FastAPI debe ejecutarse bajo el protocolo **HTTPS/TLS 1.3**.
- Cifrado en reposo: Contraseñas de usuarios cifradas utilizando **Bcrypt** con salt, impidiendo el acceso, inclusive al administrador de MongoDB.
- Protocolo Push: API V1 de Firebase Admin SDK.

### c) Estándares de cumplimiento de la plataforma
- **Arquitectura Limpia:** Estricta separación de carpetas en Dart (`features/`, `roles/`, `core/`, `theme/`).
- **Control de Versiones:** Git flow estructurado.
- **Análisis Estático de Código:** Cero errores en el `flutter analyze` y cumplimiento de los lints recomendados por Dart (`analysis_options.yaml`).

### d) Estándares de calidad y seguridad
- **Mitigación de Inyecciones (NoSQL):** PyMongo sanitiza todas las entradas; Pydantic V2 garantiza la integridad y tipado estricto de cada request y response (e.g. `EmailStr`).
- **Resiliencia de Infraestructura:** El despliegue automatizado asegura un reinicio autónomo de la aplicación Python ante cualquier caída imprevista del microservicio.

---

## CONCLUSIONES
El documento de Visión consolida el rumbo estratégico y tecnológico del SGEO, marcando hitos irrefutables: desde el diseño UI de su app móvil hasta la complejidad matemática de su motor en Python. Demuestra que la amalgama de reportes ciudadanos con Big Data oficial e Inteligencia Artificial es el paso inminente hacia un modelo de "Smart City" en Tacna, con viabilidad económica y técnica absoluta para ser lanzado de forma productiva.

## RECOMENDACIONES
Se sugiere iniciar las pruebas piloto focalizadas en el Distrito Crítico (indicado por la predicción IA inicial) para validar el comportamiento real del algoritmo DBSCAN y la adherencia del personal de serenazgo/policía a la validación de alertas. Así mismo, formalizar el contacto con los entes gubernamentales para obtener accesos oficiales mediante API a los datos del SIDPOL, disminuyendo la dependencia actual del web scraping.

## BIBLIOGRAFÍA
- Sommerville, I. (2016). *Software Engineering* (10th ed.). Pearson.
- Pedregosa, F., et al. (2011). Scikit-learn: Machine Learning in Python. JMLR.
- Documentation by Flutter Team (2025). Material 3 Design Guidelines.

## WEBGRAFÍA
- Flutter.dev, "Building Beautiful Native Apps".
- FastAPI.tiangolo.com, "Modern, fast web framework for building APIs with Python".
- MongoDB.com, "Geospatial Queries in MongoDB Atlas".
