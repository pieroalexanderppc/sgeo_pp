# Documentación Scrum: Proyecto SGEO (Geolocalización de Inseguridad Ciudadana)

## Visión del Proyecto
Crear una aplicación móvil que permita a los ciudadanos registrarse, visualizar un mapa con su ubicación actual, y consultar/reportar zonas de inseguridad. La aplicación utilizará Inteligencia Artificial para generar mapas de calor (heatmaps) predictivos o estadísticos basados en datos de incidencias (ej. SIDPOL) almacenados en MongoDB.

## Arquitectura Recomendada
- **Aplicación Móvil:** Flutter (Patrón Clean Architecture).
- **Backend:** Python con FastAPI (Seleccionado para facilitar integración IA a futuro).
- **Base de Datos:** MongoDB en la nube (Railway) con protecciones de seguridad en repositorio (.gitignore).
- **Inteligencia Artificial:** Python (Scikit-Learn, TensorFlow, o algoritmos de clustering Espacial/KDE) expuesto mediante una API.

## Product Backlog (Pila del Producto)

### Épica 1: Autenticación y Perfil de Usuario
- [ ] **Historia de Usuario 1.1:** Como usuario, quiero poder registrarme en la aplicación con mi correo y contraseña para tener una cuenta. *(En progreso)*
- [ ] **Historia de Usuario 1.2:** Como usuario, quiero poder iniciar sesión para acceder al mapa. *(Solo UI inicial completa)*

### Épica 2: Geolocalización y Mapas
- [x] **Historia de Usuario 2.1:** Como sistema, debo solicitar permisos de ubicación al dispositivo.
- [x] **Historia de Usuario 2.2:** Como usuario, quiero ver un mapa (OpenStreetMap/flutter_map) centrado en mi ubicación actual.

### Épica 3: Backend y Base de Datos (MongoDB)
- [x] **Historia de Usuario 3.1:** Crear la base de datos en MongoDB alojada en la nube (Railway) y configuración segura del entorno (ocultar contraseñas).
- [ ] **Historia de Usuario 3.2:** Desarrollar el servicio REST de registro de usuarios (FastAPI + PyMongo). *(Próximo paso)*
- [ ] **Historia de Usuario 3.3:** Importar la data inicial de SIDPOL a la colección de incidentes.

### Épica 4: Inteligencia Artificial y Mapas de Calor
- [ ] **Historia de Usuario 4.1:** Desarrollar un modelo/script que lea los datos de MongoDB y genere densidades (puntos de calor).
- [ ] **Historia de Usuario 4.2:** Integrar los puntos de calor en la capa visual del mapa en Flutter.

## Sprint 1: Registro y Mapa Básico (Actual)
**Objetivo del Sprint:** El usuario puede registrarse (UI) y ver su ubicación en un mapa, junto con arquitectura backend base.

**Progreso de Tareas:**
- [x] Tarea 1: Crear interfaz base de Login / Registro (`LoginView`).
- [x] Tarea 2: Integrar paquete de mapas (`flutter_map` y `latlong2`).
- [x] Tarea 3: Integrar paquete de geolocalización (`geolocator`).
- [x] Tarea 4: Mostrar en pantalla el mapa centrado.
- [x] Tarea 5: Configurar entorno de desarrollo para el Backend con Python y conectarlo a MongoDB de Railway en entorno local.
- [x] Tarea 6: Configurar reglas de seguridad en `.gitignore` para no subir `.env` a GitHub.

---
*Última actualización: Hitos del Sprint 1 marcados como completados. Base de datos conectada existosamente.*
