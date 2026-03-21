# Documentación Scrum: Proyecto SGEO (Geolocalización de Inseguridad Ciudadana)

## Visión del Proyecto
Crear una aplicación móvil para registrar y consultar zonas de inseguridad ciudadana en tiempo real (enfocado en geocrimen). Integrar un motor de Inteligencia Artificial Espacial para agrupar y visualizar zonas de riesgo mediante mapas de calor basados en datos de MongoDB.

## Arquitectura del Proyecto
- **Frontend App:** Flutter (Patrón Clean Architecture).
- **Backend API:** Python con FastAPI (con ejecución de IA en segundo plano).
- **Base de Datos:** MongoDB en Railway (geocrimen_tacna).

---

## Product Backlog (Pila del Producto)

### Épica 1: Autenticación y Perfil de Usuario
- [ ] **Historia de Usuario 1.1:** Registro de usuarios con correo y contraseña. *(En progreso)*
- [x] **Historia de Usuario 1.2:** Inicio de sesión para acceder al mapa. *(Login endpoint listo en backend)*
- [ ] **Historia de Usuario 1.3:** Visualizar el perfil del usuario activo y cerrar sesión.

### Épica 2: Geolocalización, Mapas y Reportes
- [x] **Historia de Usuario 2.1:** Solicitar permisos de ubicación al dispositivo.
- [x] **Historia de Usuario 2.2:** Ver un mapa con ubicación exacta mediante GPS.
- [x] **Historia de Usuario 2.3:** Mitigar los errores de timeout del GPS. *(Corregido)*
- [x] **Historia de Usuario 2.4:** Crear un reporte de incidencia asociando automáticamente las coordenadas GPS sin escribir la dirección.

### Épica 3: Backend, Historial y Base de Datos
- [x] **Historia de Usuario 3.1:** Crear y conectar base de datos MongoDB.
- [x] **Historia de Usuario 3.2:** Guardar reportes asociando el usuario_id y las coordenadas.
- [x] **Historia de Usuario 3.3:** Crear API para listado histórico (GET /mis_reportes/{user_id}) y conectarlo en Flutter.
- [ ] **Historia de Usuario 3.4:** Mantener e importar la data de SIDPOL mediante los scripts de limpieza y llenado.

### Épica 4: Inteligencia Artificial y Mapas de Calor
- [x] **Historia de Usuario 4.1:** Ejecutar el modelo (motor_ia_espacial.py) al encender el backend (startup_event) para generar clusters de riesgo.
- [ ] **Historia de Usuario 4.2:** Integrar y exponer endpoints para que el frontend dibuje las coordenadas del mapa del calor gráficamente.

---

## Sprint 1: Localización, UX y Backend de Reportes (Completado)
**Objetivo:** Consolidar el entorno GPS, refinar la interfaz (Nav Bar, Reportes directos por GPS sin dirección manual) y establecer conexión con FastAPI.

**Completado:**
- [x] Solución de caídas por geolocator timeout.
- [x] Exclusión del campo "Dirección" a favor de coordenadas en los reportes.
- [x] Estado de "Mantenimiento" a las pestañas de noticias y notificaciones.
- [x] Refactor de base de datos y endpoints para asociar reportes a su creador y leerlos mediante mis_reportes/{user_id}.

## Sprint 2: Autenticación Final, Data SIDPOL y Mapeo IA (Actual)
**Objetivo:** Terminar de enganchar el frontend del login con el backend de FastAPI, cargar datos voluminosos a Mongo y visualizar el mapa de calor de inseguridad.

**Backlog del Sprint:**
- [ ] Tarea 1: Finalizar conexión de los formularios de Flutter (Login/Signup) con la API REST de FastAPI y sus rutas /login.
- [ ] Tarea 2: Depurar e importar datos de incidentes reales (SIDPOL/DATOS.txt) en Railway con los scripts de la BD.
- [ ] Tarea 3: Enganchar la lectura visual de los puntos de calor del modelo de IA sobre la pantalla de mapa en Flutter.
