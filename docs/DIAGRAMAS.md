# Diagramas del Proyecto SGEO (Plataforma Táctica)

Este documento consolida los diagramas principales de la plataforma SGEO (Sistema de Geolocalización de Eventos y Operaciones), basándose en la arquitectura, base de datos y flujos del sistema. Estos diagramas proporcionan una visión detallada de cómo interactúan los componentes en la aplicación móvil, el backend de Inteligencia Artificial y la base de datos MongoDB.

---

## 1. Diagrama de Arquitectura

El diagrama de arquitectura define los límites del sistema, mostrando la Aplicación Móvil (Flutter) para la interacción del usuario, el Backend (FastAPI) para el procesamiento de peticiones y ejecución del Motor de IA Espacial, y la Base de Datos (MongoDB) para el almacenamiento de colecciones.

```plantuml
@startuml arquitectura
title SGEO - Diagrama de Arquitectura

top to bottom direction
skinparam shadowing false
skinparam roundcorner 10
skinparam linetype ortho
skinparam dpi 150
skinparam defaultFontName Segoe UI
skinparam backgroundColor #F8FAFC
skinparam ArrowColor #334155
skinparam ArrowThickness 1
skinparam nodesep 60
skinparam ranksep 60
skinparam PackageBackgroundColor #EEF2FF
skinparam PackageBorderColor #4F46E5
skinparam PackageFontStyle bold
skinparam ComponentBackgroundColor #FFFFFF
skinparam ComponentBorderColor #6366F1
skinparam ComponentFontColor #0F172A
skinparam DatabaseBackgroundColor #ECFDF5
skinparam DatabaseBorderColor #047857
skinparam NoteBackgroundColor #FEF3C7
skinparam NoteBorderColor #B45309

actor "Usuario" as User

package "Aplicacion Movil (Flutter)" {
  component "Capa UI\nLogin, Home, Map,\nReportes, Perfil" as UI
  component "AuthService\n(core/services)" as AuthSvc
  component "MapService\n(core/services)" as MapSvc
  component "HTTP directo\n(ProfileView, MyReportsView)" as DirectHttp
}

package "Backend (FastAPI)" {
  component "API REST\nbackend/main.py" as API
  component "Motor IA Espacial\nbackend/motor_ia_espacial.py" as IA
}

database "MongoDB\ngeocrimen_tacna" as Mongo

package "Colecciones" {
  component "usuarios" as CUsuarios
  component "reportes_ciudadano" as CReportes
  component "incidentes" as CIncidentes
  component "estadisticas_sidpol" as CSidpol
  component "zonas_riesgo" as CZonas
  component "alertas" as CAlertas
}

User --> UI : uso de la app
UI --> AuthSvc : login, register
UI --> MapSvc : zonas, puntos, crear reporte
UI --> DirectHttp : perfil, mis reportes

AuthSvc --> API
MapSvc --> API
DirectHttp --> API

API --> Mongo : CRUD y consultas
API ..> IA : startup y trigger manual
IA --> Mongo : recalculo de zonas

Mongo --> CUsuarios
Mongo --> CReportes
Mongo --> CIncidentes
Mongo --> CSidpol
Mongo --> CZonas
Mongo --> CAlertas

note right of API
Rutas activas:
1) POST /api/auth/login
2) POST /api/auth/register
3) POST /api/reportes
4) GET /api/reportes/mis_reportes/{user_id}
5) GET /api/map/zonas_riesgo
6) GET /api/map/puntos_exactos
7) POST /api/map/generar_zonas_ia
8) GET|PUT /api/usuarios/{user_id}
end note

@enduml
```

---

## 2. Diagrama de Flujo (Reporte y Visualización)

El diagrama de flujo ilustra el ciclo de vida de un reporte ciudadano, desde la interacción del usuario en la interfaz móvil hasta el procesamiento del motor de IA que recalcula las zonas de riesgo.

```plantuml
@startuml flujo
title SGEO - Diagrama de Flujo (Reporte y Motor IA)

actor "Usuario (Ciudadano)" as Ciudadano
participant "App Móvil\n(Flutter)" as App
participant "Servicios\n(MapService)" as MapSvc
participant "API Backend\n(FastAPI)" as API
participant "Motor IA\n(DBSCAN)" as IA
database "MongoDB" as DB

== Inicialización de Mapa ==
Ciudadano -> App : Inicia sesión y abre Mapa
App -> MapSvc : Solicita Zonas y Puntos
MapSvc -> API : GET /api/map/zonas_riesgo\nGET /api/map/puntos_exactos
API -> DB : Consulta colecciones (zonas, reportes)
DB --> API : Retorna listados
API --> MapSvc : JSON con Zonas y Puntos
MapSvc --> App : Datos procesados
App -> Ciudadano : Muestra Mapa geolocalizado

== Generación de Reporte ==
Ciudadano -> App : Presiona "Reportar Incidente"
App -> Ciudadano : Muestra Formulario (Tipo, Modalidad)
Ciudadano -> App : Completa y envía datos + GPS
App -> MapSvc : crearReporte(data)
MapSvc -> API : POST /api/reportes
API -> DB : Inserta en "reportes_ciudadano"
DB --> API : Confirmación
API --> MapSvc : 201 Created
MapSvc --> App : Reporte Exitoso
App -> Ciudadano : Muestra confirmación en UI

== Recálculo de Zonas (Background/Manual) ==
API -> IA : Trigger de recálculo (generar_zonas_ia)
IA -> DB : Lee "incidentes" y "estadisticas_sidpol"
IA -> IA : Ejecuta clustering DBSCAN\ny Regresión Lineal
IA -> DB : Actualiza/Sobrescribe "zonas_riesgo"
DB --> IA : Confirmación de persistencia
@enduml
```

---

## 3. Diagrama de Base de Datos (Entidad - Relación)

Este diagrama representa el diseño lógico y relacional sobre nuestra base de datos NoSQL (MongoDB), mostrando la estructura de los documentos y referencias (a través de `ObjectId`) que actúan como llaves foráneas lógicas.

```plantuml
@startuml entidad_relacion
hide circle

top to bottom direction
skinparam shadowing false
skinparam roundcorner 8
skinparam linetype ortho
skinparam dpi 150
skinparam defaultFontName Segoe UI
skinparam backgroundColor #F8FAFC
skinparam ArrowColor #0F766E
skinparam ArrowThickness 1
skinparam nodesep 55
skinparam ranksep 55
skinparam EntityBackgroundColor #FFFFFF
skinparam EntityBorderColor #0F766E
skinparam EntityFontColor #134E4A
skinparam NoteBackgroundColor #ECFEFF
skinparam NoteBorderColor #0F766E

entity "USUARIOS" as usuarios {
  * _id : ObjectId
  --
  email : string <<unique>>
  nombre : string
  password_hash : string
  rol : ciudadano|policia|admin
  telefono : string
  activo : bool
  creado_en : date
}

entity "REPORTES_CIUDADANO" as reportes {
  * _id : ObjectId
  --
  usuario_id : ObjectId?
  sub_tipo : HURTO|ROBO|EXTORSION
  modalidad : string
  ubicacion : Point
  estado : pendiente|confirmado|rechazado
  relacion_incidente : string
  fecha_hecho : date
  creado_en : date
}

entity "INCIDENTES" as incidentes {
  * _id : ObjectId
  --
  fuente : ciudadano|policia|sidpol
  reporte_id : ObjectId?
  verificado_por : ObjectId?
  sub_tipo : HURTO|ROBO|EXTORSION
  ubicacion : Point
  distrito : string
  anio : int
  mes : int
}

entity "ESTADISTICAS_SIDPOL" as sidpol {
  * _id : ObjectId
  --
  ubigeo : string
  distrito : string
  anio : int
  mes : int
  sub_tipo : string
  modalidad : string
  cantidad : int
}

entity "ZONAS_RIESGO" as zonas {
  * _id : ObjectId
  --
  centroide : Point
  radio_metros : int
  distrito : string
  nivel_riesgo : bajo|medio|alto|critico
  total_incidentes : int
  delito_predominante : string
  tendencia : subiendo|estable|bajando
  origen : SIDPOL|APP_INCIDENTES
  calculado_en : date
}

entity "ALERTAS" as alertas {
  * _id : ObjectId
  --
  usuario_id : ObjectId
  incidente_id : ObjectId?
  zona_id : ObjectId?
  tipo : nuevo_incidente|zona_peligrosa|zona_actualizada
  leida : bool
  push_enviado : bool
  creado_en : date
}

usuarios ||--o{ reportes : crea
usuarios ||--o{ incidentes : verifica
reportes ||--o| incidentes : se_convierte_en
sidpol ||--o{ zonas : alimenta_macro
incidentes ||--o{ zonas : alimenta_micro
usuarios ||--o{ alertas : recibe
incidentes ||--o{ alertas : genera
zonas ||--o{ alertas : genera

note right of reportes
API de mapa usa reportes confirmados
para puntos exactos.
end note

note right of zonas
Motor IA calcula zonas con:
1) estadisticas_sidpol
2) clustering DBSCAN en incidentes
end note

@enduml
```

---

## 4. Diagrama de Clases (Aplicación y Dominio)

Muestra las relaciones entre las Vistas (UI), Servicios y los Modelos Pydantic utilizados para el transporte de datos (payloads) hacia la API.

```plantuml
@startuml clases
title SGEO - Diagrama de Clases

top to bottom direction
skinparam shadowing false
skinparam roundcorner 10
skinparam linetype ortho
skinparam dpi 150
skinparam defaultFontName Segoe UI
skinparam backgroundColor #FFFBF5
skinparam ArrowColor #6D28D9
skinparam ArrowThickness 1
skinparam nodesep 55
skinparam ranksep 50
skinparam PackageBackgroundColor #F3E8FF
skinparam PackageBorderColor #7C3AED
skinparam PackageFontStyle bold
skinparam ClassBackgroundColor #FFFFFF
skinparam ClassBorderColor #8B5CF6
skinparam ClassFontColor #2E1065
skinparam NoteBackgroundColor #FEF3C7
skinparam NoteBorderColor #B45309

package "Flutter UI" {
  class MyApp {
    +build(context): Widget
  }
  class LoginView
  class RegisterView
  class HomeView {
    +userRole: String
    +userName: String
    +userId: String
  }
  class MapView {
    +userId: String
  }
  class ReportDialog {
    +latitud: double
    +longitud: double
    +userId: String
  }
  class MyReportsView {
    +userId: String
  }
  class ProfileView {
    +userId: String?
  }
}

package "Flutter Services" {
  class AuthService <<static>> {
    +login(email, password)
    +register(nombre, email, password)
  }
  class MapService <<static>> {
    +fetchZonasRiesgo()
    +fetchPuntosExactos()
    +crearReporte(data)
  }
}

package "Backend Models (Pydantic)" {
  class LoginRequest {
    +email: EmailStr
    +password: str
  }
  class RegisterRequest {
    +nombre: str
    +email: EmailStr
    +password: str
  }
  class ReporteCiudadano {
    +sub_tipo: str
    +latitud: float
    +longitud: float
    +usuario_id: Optional[str]
  }
  class UpdateUser {
    +nombre: str
    +email: EmailStr
    +telefono: str
  }
}

MyApp --> LoginView : home inicial
LoginView --> AuthService : login
RegisterView --> AuthService : register
LoginView --> HomeView : exito

HomeView --> MapView
HomeView --> MyReportsView
HomeView --> ProfileView

MapView --> ReportDialog
MapView --> MapService : zonas y puntos
ReportDialog --> MapService : crear reporte

AuthService ..> LoginRequest : payload
AuthService ..> RegisterRequest : payload
MapService ..> ReporteCiudadano : payload
ProfileView ..> UpdateUser : PUT /api/usuarios

note bottom
Diagrama enfocado en clases de dominio y colaboración.
Las clases internas de estado de Flutter se omitieron para legibilidad.
end note

@enduml
```
