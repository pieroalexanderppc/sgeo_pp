# Documentación Scrum: Proyecto SGEO (Geolocalización de Inseguridad Ciudadana)

## Visión del Proyecto
Crear una aplicación móvil que permita a los ciudadanos registrarse, visualizar un mapa con su ubicación actual, y consultar/reportar zonas de inseguridad. La aplicación utilizará Inteligencia Artificial para generar mapas de calor (heatmaps) predictivos o estadísticos basados en datos de incidencias almacenados en MongoDB.

## Arquitectura Recomendada
- **Aplicación Móvil:** Flutter (Patrón Clean Architecture).
- **Backend:** Python con FastAPI (Construido para soportar reportes históricos e integración IA).
- **Base de Datos:** MongoDB en la nube (Railway).

## Product Backlog (Pila del Producto)

### Épica 1: Autenticación y Perfil de Usuario
- [ ] **Historia de Usuario 1.1:** Como usuario, quiero poder registrarme en la aplicación con mi correo y contraseña. *(En progreso)*
- [x] **Historia de Usuario 1.2:** Como usuario, quiero poder iniciar sesión para acceder al mapa. *(Estructura UI lista)*

### Épica 2: Geolocalización y Mapas
- [x] **Historia de Usuario 2.1:** Como sistema, debo solicitar permisos de ubicación al dispositivo.
- [x] **Historia de Usuario 2.2:** Como usuario, quiero ver un mapa con mi ubicación exacta mediante GPS en tiempo real.
- [x] **Historia de Usuario 2.3:** Como usuario, los errores de timeout del GPS deben mitigarse efectivamente. *(Corregido)*

### Épica 3: Backend, Historial y Base de Datos
- [x] **Historia de Usuario 3.1:** Crear la base de datos en MongoDB alojada en la nube (Railway).   
- [x] **Historia de Usuario 3.2:** Guardar reportes asociando el ID de usuario (`usuario_id`) al reporte para seguimiento.
- [x] **Historia de Usuario 3.3:** Crear API para obtener el listado histórico de mis reportes y mostrarlos bajo el tap "Reportes".
- [ ] **Historia de Usuario 3.4:** Importar la data inicial de SIDPOL a la colección de incidentes.

### Épica 4: Inteligencia Artificial y Mapas de Calor
- [ ] **Historia de Usuario 4.1:** Desarrollar un modelo que lea los datos de MongoDB y genere puntos de calor.
- [ ] **Historia de Usuario 4.2:** Mostrar en modo de prueba pantallas de noticias y notificaciones como "En mantenimiento". *(Terminado)*

## Sprint 1: Localización, UX y Backend de Reportes (Actual)
**Objetivo del Sprint:** Consolidar el entorno GPS, refinar la interfaz de usuario de los reportes ocultando datos innecesarios de entrada, y conectar correctamente el Frontend al Backend FastAPI para el flujo completo y rastreable de reportes.

**Progreso de Tareas:**
- [x] Tarea 1: Solucionar caídas o problemas con geolocalización (`geolocator` timeout).
- [x] Tarea 2: Solucionar dependencias faltantes para la compilación en Web.
- [x] Tarea 3: Modificar diálogo de reporte para excluir el campo manual "Dirección" (uso de coordenadas).
- [x] Tarea 4: Actualizar las etiquetas de navegación inferior (Nav bar a "Reportes").
- [x] Tarea 5: Dejar en estado de "Mantenimiento" las pestañas de noticias y notificaciones.
- [x] Tarea 6: Refactorizar base de datos y backend `main.py` para asociar los reportes a sus dueños.
- [x] Tarea 7: Crear y exponer la ruta GET `mis_reportes/{user_id}` para poblar el historial en Flutter.

---
*Última actualización: Hitos del Sprint marcados como completados en relación a la geolocalización, corrección UI y almacenamiento histórico en backend.*
