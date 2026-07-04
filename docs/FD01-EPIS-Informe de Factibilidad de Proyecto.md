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

**Documento Informe de Factibilidad**  
**Versión:** 1.0  

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha      | Motivo                             |
|---------|-----------|--------------|--------------|------------|------------------------------------|
| 1.0     | PP        | PP           | AF           | 13/03/2026 | Versión Original                   |

---

## ÍNDICE GENERAL

1. [Descripción del Proyecto](#1-descripción-del-proyecto)
2. [Riesgos](#2-riesgos)
3. [Análisis de la Situación actual](#3-análisis-de-la-situación-actual)
4. [Estudio de Factibilidad](#4-estudio-de-factibilidad)
   - 4.1. [Factibilidad Técnica](#41-factibilidad-técnica)
   - 4.2. [Factibilidad Económica](#42-factibilidad-económica)
   - 4.3. [Factibilidad Operativa](#43-factibilidad-operativa)
   - 4.4. [Factibilidad Legal](#44-factibilidad-legal)
   - 4.5. [Factibilidad Social](#45-factibilidad-social)
   - 4.6. [Factibilidad Ambiental](#46-factibilidad-ambiental)
5. [Análisis Financiero](#5-análisis-financiero)
6. [Conclusiones](#6-conclusiones)

---

## 1. Descripción del Proyecto

**1.1. Nombre del proyecto**  
SGEO — Sistema de Geolocalización de Inseguridad Ciudadana con Machine Learning Predictivo y Espacial.

**1.2. Duración del proyecto**  
12 meses (Implementación piloto y desarrollo: 6 meses; Despliegue completo y Entrenamiento de Modelos a nivel regional: 6 meses adicionales).

**1.3. Descripción**  
El proyecto consiste en el desarrollo e implementación de una aplicación móvil multiplataforma orientada a la participación ciudadana y la acción policial estratégica en la región de Tacna, Perú. El sistema registra, visualiza, predice y alerta sobre zonas de inseguridad en tiempo real mediante la integración de reportes comunitarios geolocalizados y datos históricos oficiales del Estado Peruano.

La ausencia de un mapa situacional dinámico y accesible ha ocasionado que ciudadanos y autoridades transiten por zonas de alto riesgo criminal sin capacidad de prevención adecuada. SGEO aborda este desafío combinando reportes colaborativos en vivo con la ingestión de datos históricos del Sistema de Información Policial (SIDPOL) y la Unidad de Flagrancia de la región de Tacna.

El sistema implementa una arquitectura de Inteligencia Artificial de dos componentes: un **Motor Espacial DBSCAN** (`epsilon=150m`, `min_samples=5`, métrica Haversine) que identifica hotspots geográficos delictivos a partir del historial confirmado; y un **Motor Predictivo Contextual** que combina Análisis Temporal (distribución por hora, turno, día y tendencia mediante Regresión Lineal), un **Safety Score dinámico** (escalar 0-100 basado en proximidad a zonas de riesgo, densidad de incidentes, factor temporal y tendencia distrital), e **Insights Contextuales automáticos** personalizados por ubicación y horario. El backend está implementado sobre FastAPI con Python 3.11, MongoDB Atlas como base de datos NoSQL con índices geoespaciales `2dsphere`, Flutter/Dart para el frontend multiplataforma, y Firebase Cloud Messaging (FCM) para notificaciones push en tiempo real.

**1.4. Objetivos**  

**1.4.1. Objetivo general**  
Desarrollar e implementar un sistema inteligente de geolocalización criminal que reduzca los tiempos de respuesta policial y aumente la prevención civil en la región de Tacna mediante el uso de inteligencia artificial espacial y predictiva, proporcionando métricas analíticas en tiempo real a las autoridades y herramientas de prevención a la ciudadanía.

**1.4.2. Objetivos Específicos**  
- **Interfaz Multirrol Táctica:** Diseñar e implementar tres interfaces nativas diferenciadas en Flutter bajo el sistema visual "Premium Tactical Dark" para los roles Ciudadano, Policía y Administrador, con enrutamiento estricto basado en el atributo `rol` persistido en `SharedPreferences`.
- **Alertas Preventivas de Geofencing:** Implementar un servicio de seguimiento GPS continuo (`distanceFilter=50m`) que detecte la entrada del usuario a zonas de riesgo calculadas por DBSCAN y emita alertas locales contextuales con información del turno horario, con un mecanismo de cooldown de 30 minutos para evitar saturación.
- **Motor de Inteligencia Artificial:** Implementar el algoritmo DBSCAN con parámetros geoespaciales (`epsilon=150m`, `min_samples=5`, métrica Haversine) para clusterización de hotspots calculados sobre el mes más reciente de datos SIDPOL disponibles (evitando que estadísticas antiguas generen zonas obsoletas), el Safety Score dinámico (0-100) con cuatro factores de cálculo, y la Regresión Lineal para predicción de incidentes a 3 meses por distrito sobre el historial SIDPOL vigente.
- **Reducción de Costos Policiales:** Proveer dashboards analíticos con `fl_chart` a los administradores policiales para visualizar estadísticas de reportes, tendencias por distrito, y predicciones futuras que optimicen la asignación de recursos de patrullaje.

---

## 2. Riesgos

**2.1. Riesgos Técnicos**  
- **Inestabilidad del servicio de datos gubernamental:** Probabilidad media, impacto alto. El servicio ArcGIS REST del MININTER (`SIDPOL_DELITOS_TOTAL`) podría cambiar sus endpoints o esquema de campos, afectando el pipeline ETL (mitigado: el extractor valida la distribución de datos por mes y reporta errores en cada corrida).
- **Falsos Positivos en ML DBSCAN:** Probabilidad media, impacto medio. Radios o agrupaciones calculados erróneamente por ruido o alta densidad inusual en los reportes de los ciudadanos.
- **Degradación de rendimiento con mapas pesados:** Probabilidad media, impacto alto. La carga simultánea de miles de polígonos geoespaciales podría afectar los FPS de la aplicación móvil en dispositivos de gama baja.

**2.2. Riesgos Operativos**  
- **Reportes Falsos (Trolleo):** Probabilidad alta, impacto medio. Ciudadanos malintencionados podrían enviar reportes de crímenes falsos (mitigado mediante triple barrera: límite de 5 reportes diarios por usuario, validación policial obligatoria dentro del radio de patrullaje de 1 km, y agrupación automática de reportes duplicados en un radio de 500 m).
- **Resistencia al cambio institucional:** Probabilidad alta, impacto medio. El personal policial podría ser reticente a adoptar nuevas tecnologías tácticas de validación vía smartphone.
- **Limitación en penetración ciudadana:** Probabilidad media, impacto alto. Si no se alcanza una masa crítica de usuarios reportando, el mapa en tiempo real perderá eficacia.

**2.3. Riesgos Financieros**  
- **Fluctuaciones en costos Cloud:** Probabilidad media, impacto alto. El procesamiento intensivo del modelo de Machine Learning y el uso masivo de Firebase y MongoDB Atlas está ligado a tarifas en USD.
- **Costos ocultos en el consumo de APIs:** Probabilidad baja, impacto medio. Escalado incontrolado del uso de servidores de mapas OSM u otros proveedores asociados.

---

## 3. Análisis de la Situación actual

**3.1. Planteamiento del problema**  
La región de Tacna enfrenta desafíos críticos en materia de gestión de seguridad ciudadana que impactan directamente la tranquilidad social, el turismo y la eficiencia policial. 

Los problemas identificados incluyen:
- **Carencia de plataformas preventivas:** Los ciudadanos no tienen cómo saber si la calle a la que acaban de ingresar registró 15 asaltos la última semana. 
- **Aislamiento de datos oficiales:** Las estadísticas recopiladas en SIDPOL y la Unidad de Flagrancia existen, pero son de difícil acceso y no se aprovechan geográficamente para crear mapas térmicos ciudadanos.
- **Patrullajes reactivos, no predictivos:** Las autoridades despliegan personal sin usar análisis matemáticos, desperdiciando horas de combustible y patrullaje en zonas que las estadísticas muestran que estarán en calma, mientras descuidan los verdaderos picos predictivos de crimen.

**3.2. Consideraciones de hardware y software**  

**Hardware disponible y alcanzable:**
- Servidores virtuales en cloud: Backend desplegado en Railway PaaS, con escalado automático mediante contenedores y `Procfile` de inicio (`uvicorn main:app`).
- Equipo de desarrollo: Estación de trabajo con Windows 11, procesador multi-núcleo para emuladores Android y procesamiento de DataFrames Pandas sobre el dataset oficial SIDPOL del año vigente.
- Dispositivos móviles físicos: Smartphones Android (API 26+) con chip GPS integrado para pruebas del módulo de geofencing y notificaciones push.

**Software implementado (versiones reales):**
- **Frontend Móvil:** Flutter SDK ^3.11.3 (Dart), con paquetes: `flutter_map ^8.2.2`, `geolocator ^14.0.2`, `firebase_messaging ^16.2.0`, `fl_chart ^1.2.0`, `flutter_animate ^4.5.2`, `google_fonts ^8.1.0`, `lottie ^3.3.2`, `showcaseview 3.0.0`.
- **Backend / API REST:** Python 3.11+, `fastapi==0.104.1`, `uvicorn==0.24.0`, `pydantic==2.5.2`.
- **Base de datos NoSQL:** MongoDB Atlas (base `geocrimen_tacna`) con 4 colecciones: `usuarios`, `reportes_ciudadano`, `historial_delitos`, `zonas_riesgo`; índices `2dsphere` sobre campos `ubicacion` y `centroide`.
- **Inteligencia Artificial:** `scikit-learn==1.3.2`, `pandas==2.1.3`, `numpy==1.26.2`; algoritmos DBSCAN (espacial) y LinearRegression (predictivo).
- **Notificaciones Push:** `firebase-admin==6.3.0`, Firebase Cloud Messaging (FCM) con tópicos `alertas_ciudadanos`.
- **ETL Histórico:** Scripts `extract_arcgis_data.py` e `import_arcgis_data.py` para ingestión de datos ArcGIS/SIDPOL.

**Tecnología evaluada y adoptada:**  
Se priorizó tecnología open-source de alta madurez industrial. Scikit-Learn provee los algoritmos DBSCAN y LinearRegression con rendimiento óptimo para datasets criminológicos; Flutter compila a código nativo para Android e iOS desde una única base de código; MongoDB Atlas ofrece soporte nativo para consultas geoespaciales mediante operadores `$nearSphere` y `$geoIntersects` en C++.

---

## 4. Estudio de Factibilidad

Los resultados esperados del estudio de factibilidad incluyen la validación técnica, económica y operativa del proyecto. El estudio demuestra la viabilidad de la arquitectura propuesta en Tacna, con estimaciones y proyecciones económicas preparadas considerando el modelo "Solopreneur" o desarrollador único que asumirá todas las fases del proyecto.

### 4.1. Factibilidad Técnica

**Recursos tecnológicos disponibles:**  
La evaluación confirma y la implementación valida la disponibilidad absoluta de infraestructura tecnológica y de servicios en la nube para el levantamiento y operación del sistema SGEO.

**Hardware evaluado e implementado:**
- **Infraestructura local:** Estación de trabajo Windows 11 con procesador multi-núcleo empleada para el desarrollo, emulación Android y procesamiento del pipeline ETL sobre el dataset oficial SIDPOL del año vigente (miles de registros criminológicos georeferenciados de la provincia de Tacna).
- **Hardware en nube:** Railway PaaS con inicio automático vía `Procfile`, capaz de ejecutar los `BackgroundTasks` de FastAPI para el motor DBSCAN sin bloquear el Event Loop de la API.
- **Hardware externo:** Smartphones Android (API 26+) con GPS de alta precisión para el módulo de geofencing (`LocationAccuracy.high`, `distanceFilter=50m`).

**Software evaluado e implementado:**
- **Frontend:** Flutter SDK ^3.11.3 compila a APK/AAB nativo. Implementa `flutter_map` para cartografía OpenStreetMap, `geolocator` para GPS en background, y `firebase_messaging` para recepción de notificaciones push en todos los estados de la app (foreground, background, terminado).
- **Motor IA Espacial:** DBSCAN de Scikit-Learn con `algorithm='ball_tree'` y `metric='haversine'`, configurado a `epsilon=150m` y `min_samples=5`. Genera hotspots con nivel de riesgo (bajo/medio/alto/crítico) y radio dinámico (150m–350m) en función del volumen de incidentes por clúster.
- **Motor IA Predictivo:** `predictive_context_engine.py` implementa `SafetyScoreCalculator` (4 factores: proximidad DBSCAN, densidad incidentes, factor temporal por turno, tendencia distrital vía LinearRegression), `TemporalAnalyzer`, `InsightGenerator` y `SafeHoursCalculator`.
- **Persistencia en Nube:** MongoDB Atlas con base `geocrimen_tacna`, índices `2dsphere` en `ubicacion` (reportes) y `centroide` (zonas_riesgo) para consultas geoespaciales `$nearSphere` en tiempo sub-250ms.

**Integración con sistemas externos:**  
Se implementaron scripts ETL (`extract_arcgis_data.py`, `import_arcgis_data.py`) para la extracción e importación de datos oficiales desde el servicio `SIDPOL_DELITOS_TOTAL` de la plataforma ArcGIS del MININTER hacia MongoDB. La extracción filtra por departamento y provincia de Tacna, tipo de hecho PATRIMONIO (DELITO) y año vigente, alimentando los motores predictivos con datos actuales (1,286 registros de enero a mayo de 2026 en la última corrida) en lugar de estadísticas históricas obsoletas.

**Conclusión técnica:**  
El proyecto se encuentra completamente implementado con la infraestructura tecnológica open-source evaluada. La pila tecnológica real ha demostrado soporte para geolocalización en milisegundos (`$nearSphere`), clustering espacial automático (DBSCAN), análisis predictivo temporal (LinearRegression) y distribución masiva de alertas push (FCM). Todos los componentes han sido validados en entorno de desarrollo con datos reales del SIDPOL de la región de Tacna.

### 4.2. Factibilidad Económica

**1. Costos Generales**  
Los costos generales incluyen inversiones en herramientas de desarrollo, cuentas vitalicias para la distribución pública del software, y utilidades básicas que se usarán en el proceso de ingeniería de software durante los 12 meses.

| Concepto | Cantidad | Costo Unitario (S/) | Total (S/) |
|----------|----------|---------------------|------------|
| Cuenta Developer de Google Play (Lifetime) | 1 | 100 | 100 |
| Cuenta Apple Developer Program (Anual) | 1 | 390 | 390 |
| Material de oficina y periféricos | 1 paquete | 250 | 250 |
| **Total** | - | - | **740** |

*Fuente: Elaboración Propia*

**2. Costos operativos durante el desarrollo**  
Estos costos representan los gastos mensuales recurrentes necesarios para mantener la red, la energía eléctrica y el equipo comunicativo activo en la fase de desarrollo e implementación local.

| Concepto | Mensual (S/) | 12 Meses (S/) |
|----------|--------------|---------------|
| Internet fibra óptica empresarial | 120 | 1,440 |
| Electricidad adicional de equipos | 60 | 720 |
| Comunicaciones y viáticos | 50 | 600 |
| **Total** | **230** | **2,760** |

*Fuente: Elaboración Propia*

**3. Costos del ambiente**  
Los costos del ambiente comprenden los servicios de infraestructura digital en la nube, servidores de Inteligencia Artificial y la base de datos distribuida en MongoDB que sostendrán todo el backend funcionando las 24 horas.

| Concepto | Mensual (S/) | 12 Meses (S/) |
|----------|--------------|---------------|
| Hosting Backend - Railway (PaaS) | 60 | 720 |
| Base de Datos - MongoDB Atlas (Tier) | 80 | 960 |
| Servicios Firebase Push y Auth | 10 | 120 |
| Dominios, SSL y Mapas | 20 | 240 |
| **Total** | **170** | **2,040** |

*Fuente: Elaboración Propia*

**4. Costos de personal**  
Los costos de personal consideran la dedicación intensiva de un único ingeniero de software capaz de abarcar las disciplinas de Inteligencia Artificial (Python), Frontend Móvil (Flutter), y Arquitectura Cloud (MongoDB/PaaS) a tiempo parcial durante el lapso de un año.

| Rol | Personas | Dedicación | Monto total (S/) |
|-----|----------|------------|------------------|
| Desarrollador Full-Stack/IA (Piero Paja) | 1 | 12 meses part-time | 18,000 |
| **Total Costos Personal** | - | - | **18,000** |

*Fuente: Elaboración Propia*

**5. Costos totales del desarrollo del sistema**  
El resumen consolidado presenta una inversión total de S/ 23,540, de los cuales el 76% recae en la alta especialización humana requerida para combinar sistemas móviles con Machine Learning predictivo, y el resto financia la infraestructura tecnológica de nube y operación diaria.

| Categoría | Monto (S/) |
|-----------|------------|
| Costos Generales | 740 |
| Costos Operativos | 2,760 |
| Costos del Ambiente | 2,040 |
| Costos de Personal | 18,000 |
| **Total Proyecto** | **23,540** |

*Fuente: Elaboración Propia*

### 4.3. Factibilidad Operativa

**Beneficios del producto:**  
El sistema proporcionará predicciones de inteligencia artificial exclusivas a la policía, una notificación constante a las unidades en campo y un reporte visual sin precedentes para el ciudadano común. La curva de aprendizaje en Flutter es plana (UI nativa muy amigable).

**Capacidad del cliente:**  
Se buscará alianza estratégica con la Municipalidad de Tacna o el Comando Policial de la región. Existen recursos humanos para supervisar el panel web, ya que sus operadores de videovigilancia podrán añadir SGEO a su protocolo diario sin esfuerzo extra.

**Lista de interesados:**
- Ciudadanía Tacneña (usuarios finales beneficiados).
- Comando Policial PNP Tacna (usuarios de validación y administradores).
- Municipalidad Provincial de Tacna (sponsor y coordinador logístico).
- Ministerio Público (proveedor indirecto de data).

### 4.4. Factibilidad Legal

No existen conflictos legales identificados. El proyecto cumple con:
- **Ley de Protección de Datos Personales (Ley N° 29733):** Anonimización de reportes, encriptación Bcrypt de contraseñas en bases de datos, privacidad y no-persistencia del GPS ciudadano.
- **Políticas de Datos Abiertos (Gobierno Peruano):** Uso lícito y transparente de bases de datos de SIDPOL amparado en el libre acceso a la información pública.
- **Seguridad y Propiedad Intelectual:** Componentes Flutter y librerías Python bajo licencias permisivas MIT y Apache 2.0.

### 4.5. Factibilidad Social

**Clima social:**  
Existe una fuerte presión ciudadana hacia la reducción de tasas de crimen. Total aceptación de herramientas tecnológicas cívicas que democratizan el acceso a la seguridad.

**Aspectos éticos:**  
Mitigación algorítmica para evitar el estigma a zonas vulnerables: los mapas de riesgo se recalculan íntegramente con cada validación policial usando únicamente el mes más reciente de datos, de modo que una zona deja de aparecer cuando la incidencia real disminuye — sin manchar permanentemente la reputación de un distrito.

### 4.6. Factibilidad Ambiental

**Impacto positivo:**
- Optimización de rutas de patrullaje Policial usando las proyecciones IA, lo que se traduce directamente en menos gasto de combustible fósil de las camionetas y motocicletas de serenazgo.
- Menor emisión de CO2 por reducción de rondas "a ciegas".
- Digitalización completa de la denuncia situacional comunitaria, eliminando por completo los formatos y actas de papel.

---

## 5. Análisis Financiero

### 5.1. Justificación de la Inversión

**5.1.1. Beneficios del Proyecto**

*Beneficios Tangibles:*
- **Reducción de costos de combustible (Patrulleros):** Al enfocar el 30% del esfuerzo logístico solo hacia las proyecciones de riesgo dadas por la Inteligencia Artificial. Ahorro municipal de S/ 16,500 anuales.
- **Reducción de atención burocrática:** Disminución del procesamiento de llamadas falsas o repetidas a centrales de atención de emergencias (105) al agruparse digitalmente en el mapa en vivo a 500m. Ahorro adicional de S/ 10,200 anuales.
- **Total de beneficios tangibles anuales:** S/ 26,700

*Beneficios Intangibles:*
- Sensación real y generalizada de mayor seguridad ciudadana.
- Efecto disuasorio en el crimen organizado al haber prevención táctica mapeada.
- Cultura cívica participativa y moderna.

**5.1.2. Criterios de Inversión**

*5.1.2.1. Relación Beneficio/Costo (B/C)*  
Se evalúa proyectando los beneficios (S/ 26,700 anual) divididos en meses, usando una tasa de descuento mensual estándar de 1% (12% anual). 
- Inversión / Costo Inicial: S/ 23,540
- Beneficio mensual: S/ 26,700 ÷ 12 = S/ 2,225

| Mes | Beneficio Mensual (S/.) | Factor de Descuento (1%) | Valor Presente (S/.) |
|-----|-------------------------|--------------------------|----------------------|
| 1   | 2,225.00                | 0.9901                   | 2,203                |
| 2   | 2,225.00                | 0.9803                   | 2,181                |
| 3   | 2,225.00                | 0.9706                   | 2,160                |
| 4   | 2,225.00                | 0.9610                   | 2,138                |
| 5   | 2,225.00                | 0.9515                   | 2,117                |
| 6   | 2,225.00                | 0.9420                   | 2,096                |
| 7   | 2,225.00                | 0.9327                   | 2,075                |
| 8   | 2,225.00                | 0.9235                   | 2,055                |
| 9   | 2,225.00                | 0.9143                   | 2,034                |
| 10  | 2,225.00                | 0.9053                   | 2,014                |
| 11  | 2,225.00                | 0.8963                   | 1,994                |
| 12  | 2,225.00                | 0.8874                   | 1,974                |
| **Total VP Beneficios** | **26,700**          | ---                      | **25,041**           |

*Fuente: Elaboración Propia*

*Cálculo B/C:*  
`B/C = 25,041 / 23,540 = 1.06`

*5.1.2.2. Valor Actual Neto (VAN)*  
El VAN representa la diferencia entre el valor presente de los beneficios y los costos iniciales del proyecto:  
`VAN = VP Beneficios − Inversión Inicial = 25,041 − 23,540 = 1,501`  

El resultado positivo de **S/ 1,501** indica que el proyecto genera valor económico genuino además del inmenso rédito social que provee.

*5.1.2.3. Tasa Interna de Retorno (TIR)*  
Evaluando la TIR asumiendo flujos de S/ 26,700 durante los próximos años de utilidad contra la inversión inicial de S/ 23,540. La TIR obtenida supera el **13%**, demostrando rentabilidad sostenible para potenciales inversores del sector público o privado.

---

## 6. Conclusiones

Los resultados del exhaustivo análisis de factibilidad demuestran que el proyecto SGEO es íntegramente factible en los frentes técnico, legal, económico y operativo. Aprovecha un nicho vacío en la ciudad de Tacna utilizando tecnología de vanguardia (Scikit-Learn, Flutter, MongoDB) bajo presupuestos sumamente controlables que rinden una tasa Beneficio/Costo favorable.

El VAN positivo de S/ 1,501 garantiza que las inversiones en cuentas developer, servidores cloud y horas hombre tendrán un retorno cimentado en la optimización logística policial. Al ofrecer análisis algorítmico a gran escala, la app impactará masivamente en la prevención civil y en el ecosistema digital peruano, validándose como un caso de éxito de Ingeniería de Sistemas.
