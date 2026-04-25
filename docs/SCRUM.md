# Documentación Scrum: Proyecto SGEO (Sistema de Geolocalización de Inseguridad Ciudadana)

## Visión del Proyecto
Crear una plataforma táctica móvil (iOS/Android) que prevenga el crimen mediante geolocalización cívico-policial y analítica avanzada. El sistema integra Machine Learning (Scikit-Learn) para mapear clústeres espaciales (DBSCAN) y predecir tendencias criminalísticas (Regresión Lineal) utilizando Big Data del Estado (SIDPOL).

## Arquitectura del Proyecto
- **Frontend Móvil:** Flutter (Dart) con enfoque de diseño "Premium Tactical Dark".
- **Backend API:** Python 3.11 con FastAPI y Scikit-Learn.
- **Base de Datos:** MongoDB Atlas (M10 Cluster) con soporte `2dsphere`.
- **Integraciones:** Firebase Cloud Messaging (FCM) para Geofencing.

---

## Product Backlog (Pila del Producto)

### Épica 1: Autenticación y Control de Accesos (RBAC)
- [x] **Historia 1.1:** Registro y login de usuarios con encriptación Bcrypt.
- [x] **Historia 1.2:** Crear 3 roles diferenciados: Ciudadano, Policía y Administrador.
- [x] **Historia 1.3:** Enrutador dinámico en Flutter que aísla las interfaces para prevenir acceso no autorizado (Redirección estricta).

### Épica 2: UX Táctica y Reportes Geográficos
- [x] **Historia 2.1:** Implementar el diseño visual *Premium Tactical Dark* con acentos rojos.
- [x] **Historia 2.2:** Permisos de ubicación y captura de lat/lon en milisegundos sin depender de direcciones manuales.
- [x] **Historia 2.3:** Creación de reportes civiles con categorización de delitos.

### Épica 3: Validación Policial y Zonas de Riesgo
- [x] **Historia 3.1:** Crear interfaz especial para el Policía con botón "Validar" / "Rechazar".
- [x] **Historia 3.2:** Restringir al policía auditar solo incidentes en un radio táctico de 3 km a la redonda.
- [x] **Historia 3.3:** Sancionar a los ciudadanos civiles con "Strikes" (baneos temporales) si hacen reportes falsos o *troll*.

### Épica 4: Inteligencia Artificial y Dashboards
- [x] **Historia 4.1:** Algoritmo espacial **DBSCAN** que agrupa reportes validados para dibujar polígonos rojos de peligro.
- [x] **Historia 4.2:** Importación del Big Data oficial policial (SIDPOL/Flagrancia).
- [x] **Historia 4.3:** Dashboards Administrativos en Flutter utilizando `fl_chart` para estadísticas visuales.
- [x] **Historia 4.4:** Endpoint `/predict` de **Regresión Lineal** que cruza el histórico mensual para pronosticar incidentes futuros.

---

## Historial de Sprints

### Sprint 1: Fundación, GPS y Arquitectura Base (Completado)
**Objetivo:** Consolidar el entorno de desarrollo, mitigar errores nativos de GPS y armar los esquemas NoSQL en MongoDB.
**Entregables:**
- [x] Solución definitiva a caídas por `geolocator timeout`.
- [x] Exclusión del campo "Dirección manual" a favor de coordenadas geoespaciales.
- [x] Script `setup_db.py` con validadores `$jsonSchema` estrictos.

### Sprint 2: Roles (RBAC), UI Táctica y Validaciones (Completado)
**Objetivo:** Desarrollar el sistema de login seguro y aislar las vistas por Rol para evitar deuda técnica, implementando el diseño Premium.
**Entregables:**
- [x] Diseño UI *Tactical Dark* implementado en todos los componentes.
- [x] Separación de carpetas `lib/roles/admin`, `lib/roles/police` y `lib/roles/citizen`.
- [x] Lógica de validación policial a 3km operativa en FastAPI.

### Sprint 3: Machine Learning, Analítica y Despliegue (Completado)
**Objetivo:** Darle "inteligencia" al sistema procesando Big Data, dibujando gráficas financieras y redactando la documentación universitaria.
**Entregables:**
- [x] Pantalla *Dual Tab* para el Administrador (Métricas en Tiempo Real vs Big Data).
- [x] Endpoints asíncronos para DBSCAN y Regresión Lineal funcionando.
- [x] Reformateo total de los Documentos Universitarios (`FD01`, `FD02`, `FD03`, `FD04`).

---
**Estado General del Proyecto:** Listo para pase a Producción / Presentación Académica Final.
