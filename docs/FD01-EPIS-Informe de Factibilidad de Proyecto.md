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
El proyecto consiste en el desarrollo e implementación de una aplicación móvil híbrida orientada a la participación ciudadana y la acción policial estratégica en la región de Tacna. El sistema registrará, visualizará, predecirá y alertará sobre zonas de inseguridad en tiempo real.

La actual falta de un mapa situacional accesible y dinámico ha generado que los ciudadanos y autoridades transiten por zonas con un inminente riesgo criminal sin contar con la capacidad de prevención adecuada. Esta solución abordará este desafío mediante la combinación de reportes comunitarios en vivo y la extracción automatizada de datos gubernamentales oficiales (SIDPOL / Unidad de Flagrancia).

El sistema incluye una arquitectura avanzada de Machine Learning de 2 fases: Una fase Espacial (mediante el algoritmo DBSCAN) para mapear clusters y definir radios de riesgo en la ciudad; y una fase Predictiva (mediante algoritmos de Regresión Lineal) para analizar grandes volúmenes de datos históricos (2018-2026) y pronosticar riesgos futuros por distritos. Contempla una API RESTful escalable en FastAPI, integración de bases de datos MongoDB, diseño de UI táctico multiplataforma en Flutter y notificaciones preventivas vía Firebase Cloud Messaging (FCM).

**1.4. Objetivos**  

**1.4.1. Objetivo general**  
Desarrollar e implementar un sistema inteligente de geolocalización criminal que reduzca los tiempos de respuesta policial y aumente la prevención civil en Tacna mediante el uso de inteligencia artificial espacial y predictiva, proporcionando métricas 24/7 a las autoridades.

**1.4.2. Objetivos Específicos**  
- **Interfaz Multirrol Táctica:** Diseñar e implementar el sistema visual "Premium Tactical Dark" en Flutter con soporte 100% independiente para ciudadanos, policías y administradores.
- **Alertas Preventivas de Geofencing:** Lograr que los ciudadanos reciban una alerta push automatizada con menos de 60 segundos de latencia al ingresar a una zona catalogada como de alto riesgo por la Inteligencia Artificial.
- **Motor Inteligente:** Implementar los algoritmos DBSCAN (espacial) y Linear Regression (predictivo) para procesar más del 90% de los incidentes de las bases de datos oficiales de SIDPOL.
- **Reducción de Costos Policiales:** Proveer métricas analíticas a los administradores policiales para optimizar los recorridos de patrullaje basándose en las predicciones del modelo, logrando ahorros tangibles de combustible.

---

## 2. Riesgos

**2.1. Riesgos Técnicos**  
- **Inconsistencia de Web Scraping:** Probabilidad media, impacto alto. Las páginas gubernamentales (SIDPOL, Corte Superior de Tacna) podrían cambiar su estructura HTML, afectando los pipelines ETL automatizados en el backend.
- **Falsos Positivos en ML DBSCAN:** Probabilidad media, impacto medio. Radios o agrupaciones calculados erróneamente por ruido o alta densidad inusual en los reportes de los ciudadanos.
- **Degradación de rendimiento con mapas pesados:** Probabilidad media, impacto alto. La carga simultánea de miles de polígonos geoespaciales podría afectar los FPS de la aplicación móvil en dispositivos de gama baja.

**2.2. Riesgos Operativos**  
- **Reportes Falsos (Trolleo):** Probabilidad alta, impacto medio. Ciudadanos malintencionados podrían enviar reportes de crímenes falsos (mitigado mediante sistema de validación policial exclusivo a 3km a la redonda).
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
- Servidores virtuales en cloud: Backend desplegado en PaaS (Railway) con redundancia automática.
- Equipo de desarrollo: Laptop/Estación de trabajo con Windows 10/11, 16GB RAM, procesador multi-núcleo para levantar emuladores de Android y procesar Pandas.
- Dispositivos móviles físicos: Smartphones Android e iOS de diversas gamas para asegurar el testing del hardware GPS nativo.

**Software posible para implementación:**
- **Frontend Móvil:** Flutter (Dart) con integración a Google Maps / OpenStreetMap.
- **Backend / API REST:** Python 3.11+, FastAPI, Uvicorn.
- **Base de datos NoSQL:** MongoDB 6.0+ (Atlas) usando índices geoespaciales 2dsphere.
- **Inteligencia Artificial y Big Data:** Scikit-learn, Pandas, NumPy.
- **Notificaciones:** Firebase Cloud Messaging (FCM).
- **Tareas Automáticas:** Cron Jobs nativos en servidores para Scraping (BeautifulSoup4).

**Tecnología evaluada:**  
Se priorizará tecnología open-source moderna y robusta. Python y Scikit-learn son los estándares absolutos de la industria para algoritmos de regresión; Flutter permitirá programar para iOS y Android desde un solo código base; y MongoDB tiene un soporte inigualable para la geolocalización.

---

## 4. Estudio de Factibilidad

Los resultados esperados del estudio de factibilidad incluyen la validación técnica, económica y operativa del proyecto. El estudio demuestra la viabilidad de la arquitectura propuesta en Tacna, con estimaciones y proyecciones económicas preparadas considerando el modelo "Solopreneur" o desarrollador único que asumirá todas las fases del proyecto.

### 4.1. Factibilidad Técnica

**Recursos tecnológicos disponibles:**  
La evaluación confirma la disponibilidad absoluta de infraestructura tecnológica y de servicios en la nube para el levantamiento de SGEO.

**Hardware evaluado:**
- **Infraestructura local:** Estación de trabajo de alto rendimiento del desarrollador suficiente para emular ambas plataformas (Android/iOS) y procesar en local el pipeline ETL.
- **Hardware en nube:** Servicios cloud PaaS (Railway) capaces de escalar el procesamiento requerido de las BackgroundTasks en la API en tiempo real.
- **Hardware externo:** Smartphones comunes de los ciudadanos cuentan hoy en día con un chip GPS preciso integrado de manera universal.

**Software evaluado:**
- **Plataformas Base:** Framework Flutter v3+, Python 3.11 para algoritmos de alta carga matemática.
- **Procesamiento AI:** Scikit-Learn. El algoritmo DBSCAN evaluado mostró un rendimiento impecable frente al mapeo geoespacial debido a su técnica basada en densidad y manejo de distancias de haversine.
- **Persistencia en Nube:** MongoDB Atlas, ideal para queries nativos como `$near` y `$geoIntersects`.

**Integración con sistemas existentes:**  
Capacidad de ingestar y parsear hojas de cálculo y JSON abiertos del Gobierno Peruano mediante web scraping automatizado.

**Conclusión técnica:**  
El proyecto es completamente viable con la infraestructura tecnológica open-source seleccionada, la cual posee la madurez necesaria para soportar geolocalización en milisegundos y entrenamientos robustos de ML en la nube.

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
Mitigación algorítmica para evitar el estigma a zonas vulnerables (los mapas de riesgo se calculan estadísticamente y expiran de manera dinámica tras 72 horas, no manchando permanentemente la reputación de un distrito).

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
