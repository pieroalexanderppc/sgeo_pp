![Logo UPT](media/image17.png)

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

**Documento de Arquitectura de Software (SAD)**  
**Versión:** 1.0  

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha      | Motivo                             |
|---------|-----------|--------------|--------------|------------|------------------------------------|
| 1.0     | PP        | PP           | AF           | 13/03/2026 | Creación Inicial - Contexto SGEO   |

---

## ÍNDICE GENERAL

1. [Introducción](#1-introducción)
2. [Representación Arquitectónica](#2-representación-arquitectónica)
3. [Objetivos y Restricciones Arquitectónicas](#3-objetivos-y-restricciones-arquitectónicas)
4. [Vista de Casos de Uso](#4-vista-de-casos-de-uso)
5. [Vista Lógica](#5-vista-lógica)
6. [Vista de Implementación](#6-vista-de-implementación)
7. [Vista de Procesos](#7-vista-de-procesos)
8. [Vista de Despliegue](#8-vista-de-despliegue)
9. [Calidad del Software](#9-calidad-del-software)
10. [Decisiones Arquitectónicas](#10-decisiones-arquitectónicas)
11. [Tamaño y Rendimiento](#11-tamaño-y-rendimiento)

---

## 1. Introducción

### 1.1. Propósito
El presente Documento de Arquitectura de Software (SAD) describe la arquitectura técnica del **Sistema SGEO**, una plataforma predictiva de inseguridad ciudadana. Sirve como un plano arquitectónico exhaustivo (incluyendo diagramas UML, APIs y modelos lógicos) para comunicar las decisiones tecnológicas al equipo de desarrollo, a la plana docente de la UPT y a los stakeholders (Policía Nacional y Municipalidad).

### 1.2. Alcance
Cubre el diseño arquitectónico del **Frontend** (Aplicación Móvil en Flutter), el **Backend** (API RESTful en FastAPI con Machine Learning), la **Capa de Persistencia** (MongoDB Atlas) y los **Servicios de Nube** externos (Firebase Cloud Messaging).

### 1.3. Definiciones, Siglas y Abreviaturas
- **SAD:** Software Architecture Document.
- **SGEO:** Sistema de Geolocalización de Inseguridad Ciudadana.
- **DBSCAN:** Algoritmo de clustering espacial basado en densidad.
- **MVC/MVT:** Patrones de arquitectura Model-View-Controller.
- **FCM:** Firebase Cloud Messaging.

### 1.4. Referencias
- Patrones de Arquitectura Empresarial (Martin Fowler).
- Documentación Oficial de FastAPI (Asynchronous Python).
- Documentación del Framework Flutter (Dart).

---

## 2. Representación Arquitectónica

### 2.1. Modelo de Vistas
Se ha documentado el sistema utilizando un **Enfoque de Arquitectura en Capas (Layered Architecture)** y un modelo tipo C4 modificado para reflejar la estructura real del repositorio:
1. **Vista de Contexto / Casos de Uso:** Relación de los actores (Policía, Administrador, Ciudadano) con el sistema central de SGEO y los servicios en la nube.
2. **Vista Lógica (Contenedores):** Separación en módulos independientes: Frontend (Aplicación Móvil en Flutter), Backend (API REST en FastAPI) y Persistencia (MongoDB Atlas).
3. **Vista de Implementación (Componentes):** Cómo el código fuente está agrupado en el repositorio (Ej: directorios `core`, `roles` en Flutter y los `Routers` en Python).
4. **Vista de Procesos:** Orquestación y concurrencia asíncrona, documentando cómo FastAPI procesa la Inteligencia Artificial (DBSCAN y ML) en tareas en segundo plano.
5. **Vista de Despliegue:** Mapa de la infraestructura técnica donde se ejecuta el código en producción (PaaS Railway, AWS y Firebase).

### 2.2. Patrones Arquitectónicos Aplicados
- **Cliente-Servidor (Client-Server):** Desacoplamiento total entre la App Móvil (Cliente) y la API Central (Servidor).
- **Clean Architecture (Frontend):** Separación en Flutter entre `core`, `features`, `theme` y `roles`.
- **Arquitectura Basada en Eventos:** Uso de *Push Notifications* y Tareas en Segundo Plano (*BackgroundTasks* en FastAPI) para no bloquear el `Event Loop`.

### 2.3. Tecnologías Utilizadas
- **Frontend:** Flutter v3+, Dart, `flutter_map`, `fl_chart`.
- **Backend:** Python 3.11+, FastAPI, Uvicorn, Scikit-Learn (ML), Pandas.
- **Base de Datos:** MongoDB Atlas (M0/M10 Cluster) con índices `2dsphere`.
- **Integraciones:** Firebase Admin SDK, Bcrypt.

---

## 3. Objetivos y Restricciones Arquitectónicas

### 3.1. Objetivos de Software
- **Alta Cohesión y Bajo Acoplamiento:** Cada módulo del Backend (Auth, Dashboards, Machine Learning, Reportes) opera de manera independiente a través de Routers de FastAPI.
- **Latencia Mínima Espacial:** Las consultas geográficas (`$near`) deben responder en milisegundos incluso con miles de reportes.

### 3.2. Restricciones Tecnológicas
- **Lenguaje:** Obligatoriedad de usar Python en el Backend para garantizar la compatibilidad matemática con las librerías `scikit-learn` y `pandas`.
- **Persistencia:** Requerimiento estricto de base de datos NoSQL con soporte geoespacial nativo (MongoDB).
- **Costo:** Maximizar el uso de capa gratuita (PaaS como Railway y MongoDB Atlas) para mantener el presupuesto por debajo de S/ 2,000 mensuales en infraestructura.

---

## 4. Vista de Casos de Uso

### 4.1. Diagrama de Casos de Uso General
```plantuml
@startuml
left to right direction
actor "Ciudadano" as C
actor "Policía" as P
actor "Administrador" as A

package "App SGEO" {
  usecase "Reportar Crimen GPS" as UC1
  usecase "Ver Mapa de Calor" as UC2
  usecase "Recibir Alertas Push" as UC3
  
  usecase "Validar/Rechazar Reportes a 3km" as UC4
  usecase "Monitorear su Cuadrante" as UC5
  
  usecase "Analizar Dashboards (fl_chart)" as UC6
  usecase "Generar Predicciones ML" as UC7
  usecase "Visualizar Data SIDPOL" as UC8
}

C --> UC1
C --> UC2
C --> UC3

P --> UC4
P --> UC5

A --> UC6
A --> UC7
A --> UC8

UC4 .> UC1 : "Audita"
UC7 .> UC8 : "Consume Data"
@enduml
```

---

## 5. Vista Lógica

### 5.1. Arquitectura de Alto Nivel
```plantuml
@startuml
skinparam componentStyle rectangle

package "Capa de Presentación (Flutter)" {
  [Auth View]
  [Citizen Map View]
  [Police Tactical View]
  [Admin Dashboard View]
}

package "Capa de Lógica de Negocio (FastAPI)" {
  [Auth Service (JWT)]
  [Reports Service (CRUD)]
  [AI Prediction Service]
  [Geo Spatial Service (DBSCAN)]
}

package "Capa de Datos" {
  [MongoDB Driver (PyMongo)]
}

[Auth View] --> [Auth Service (JWT)]
[Citizen Map View] --> [Geo Spatial Service (DBSCAN)]
[Police Tactical View] --> [Reports Service (CRUD)]
[Admin Dashboard View] --> [AI Prediction Service]
[Auth Service (JWT)] --> [MongoDB Driver (PyMongo)]
[Reports Service (CRUD)] --> [MongoDB Driver (PyMongo)]
[AI Prediction Service] --> [MongoDB Driver (PyMongo)]
@enduml
```

### 5.2. Modelo de Base de Datos (Diagrama de Clases)
```plantuml
@startuml
class Usuario {
  +ObjectId id
  +String nombre
  +String email
  +String password_hash
  +String rol
  +GeoJSON ubicacion_default
}

class ReporteCiudadano {
  +ObjectId id
  +String sub_tipo
  +GeoJSON ubicacion
  +String estado (pendiente, confirmado)
}

class EstadisticaSidpol {
  +int anio
  +int mes
  +String distrito
  +int cantidad
}

class ZonaRiesgo {
  +GeoJSON centroide
  +int radio_metros
  +String nivel_riesgo
}

Usuario "1" -- "0..*" ReporteCiudadano
EstadisticaSidpol "1" ..> "1" ZonaRiesgo : alimenta ML
@enduml
```

---

## 6. Vista de Implementación

### 6.1. Estructura de Directorios del Repositorio
**Frontend (Flutter):**
```
sgeo_pp/
├── lib/
│   ├── core/         # Servicios base, HTTP, Utils, Theme
│   ├── features/     # Auth, Onboarding (Módulos transversales)
│   ├── roles/        # Separación estricta (admin/, citizen/, police/)
│   └── main.dart     # Punto de entrada y Router principal
```

**Backend (Python/FastAPI):**
```
backend/
├── api/
│   ├── auth.py       # JWT Login
│   ├── ciudadano.py  # Rutas de civil
│   ├── admin.py      # Rutas de administrador e Inteligencia Artificial
│   └── policia.py    # Rutas de validación
├── models/           # Pydantic schemas (validación estricta de JSON)
├── scripts_iniciales/ # setup_db.py y scripts de ETL para SIDPOL
├── database.py       # Conexión PyMongo singleton
└── main.py           # Instancia FastAPI y middleware CORS
```

### 6.2. Diagrama de Componentes
```plantuml
@startuml
component "App Móvil (iOS/Android)" as App {
  [Dio HTTP Client]
  [Geolocator]
}

component "Backend Server (Railway)" as Server {
  [Uvicorn ASGI]
  [FastAPI Routers]
  [Scikit-Learn Engine]
}

component "Database (MongoDB Atlas)" as DB {
  [2dsphere Indexes]
}

[Dio HTTP Client] --> [Uvicorn ASGI] : HTTPS (REST)
[FastAPI Routers] --> [2dsphere Indexes] : Motor PyMongo
[Scikit-Learn Engine] --> [2dsphere Indexes] : Fetch Pandas DataFrame
@enduml
```

---

## 7. Vista de Procesos

### 7.1. Diagrama de Actividad: Generación de Zonas Rojas (DBSCAN)
El procesamiento espacial corre en background para no interrumpir al oficial de policía que acaba de validar un incidente.
```plantuml
@startuml
|Oficial de Policía|
start
:Presiona "Validar Incidente";
|Backend (FastAPI)|
:Actualiza estado a "confirmado" en MongoDB;
fork
  :Responde "200 OK" al instante al Oficial;
fork again
  |Backend (Background Task)|
  :Obtiene todos los incidentes confirmados (30 días);
  :Ejecuta algoritmo DBSCAN (eps=400m);
  :Calcula nuevos centroides y radios;
  :Guarda colección 'zonas_riesgo';
  if (Hubo un cambio severo de zona?) then (Sí)
    |Firebase|
    :Emitir Push Notification "Peligro en zona";
  else (No)
  endif
end fork
|Oficial de Policía|
stop
@enduml
```

---

## 8. Vista de Despliegue

### 8.1. Arquitectura Cloud e Infraestructura
```plantuml
@startuml
node "Dispositivos Móviles" {
  [Smartphone Android (APK)]
  [Smartphone iPhone (IPA)]
}

node "Infraestructura Cloud (PaaS)" {
  component "Railway App Service" {
    [FastAPI Docker Container]
    [Python 3.11 Environment]
  }
}

node "MongoDB Atlas Cluster" {
  database "Replica Set (Primary)" {
    [geocrimen_tacna DB]
  }
}

cloud "Google Cloud Firebase" {
  [Cloud Messaging Server]
}

[Smartphone Android (APK)] --> [FastAPI Docker Container] : HTTPS (REST)
[FastAPI Docker Container] --> [geocrimen_tacna DB] : MongoDB Wire Protocol (TLS)
[FastAPI Docker Container] --> [Cloud Messaging Server] : Firebase Admin SDK
[Cloud Messaging Server] -.> [Smartphone Android (APK)] : Push Alerta
@enduml
```

### 8.2. Especificaciones Técnicas
- **Servidor API:** Instancia Railway con 1GB RAM y 1vCPU. Entorno aislado en Docker `python:3.11-slim`.
- **Base de Datos:** MongoDB Atlas M10 (Cluster dedicado o capa gratuita optimizada), desplegado en AWS `us-east-1` (Virginia) para menor latencia con Perú.
- **Canal Seguro:** Todos los endpoints están resguardados por certificados TSL/SSL provistos automáticamente por la plataforma Railway.

---

## 9. Calidad del Software
- **Testabilidad:** Separación de Pydantic Models y Controllers facilita la inyección de dependencias para `pytest`.
- **Mantenibilidad:** El uso del patrón Repository (Manejadores directos de BD) en `database.py` previene el espagueti code en los endpoints de FastAPI.
- **Performance:** Al delegar los cálculos pesados de Scikit-Learn a la librería C underlying (Numpy), el Event Loop de Python nunca se bloquea, logrando métricas de *High-Concurrency*.

## 10. Decisiones Arquitectónicas
- **¿Por qué Flutter y no React Native?** Flutter provee un motor de renderizado propio (Skia/Impeller) que asegura 60 FPS estables al dibujar cientos de polígonos geoespaciales (hotspots criminales), algo en lo que React Native sufre pérdida de *frames*.
- **¿Por qué FastAPI en lugar de Node.js?** Si bien Node.js es rápido para E/S, SGEO requiere ejecutar Modelos Predictivos y DBSCAN. Python es el estándar de oro en Inteligencia Artificial y FastAPI permite exponer esos modelos asíncronamente en una sola pieza de infraestructura.

## 11. Tamaño y Rendimiento
- **Métricas Esperadas:**
  - Ingesta de 500,000 registros históricos de SIDPOL procesados en memoria (Pandas) en menos de 5 segundos de entrenamiento en servidor.
  - El peso del aplicativo Móvil final optimizado (AppBundle para Android) es estimado a `< 30 MB`.
  - Capacidad para atender hasta 2,000 conexiones concurrentes gracias al servidor ASGI Uvicorn.
