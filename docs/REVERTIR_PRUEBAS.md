# 🚀 Checklist para Producción (Revertir Cambios de Prueba)

Durante la fase de validación y pruebas hemos reducido intencionalmente algunos tiempos de caché y enfriamiento (cooldown) para acelerar los resultados. 

Antes de lanzar la versión final a producción, asegúrate de **revertir estos 2 valores**:

## 1. Caché del API de Zonas de Riesgo (Backend)
**Archivo:** `backend/main.py`
**Dónde:** Dentro del endpoint `@app.get("/api/map/zonas_riesgo")`

* **Estado de Prueba (Actual):** `(time.time() - _cache_time) < 60` (1 minuto)
* **Estado de Producción:** `(time.time() - _cache_time) < 600` (10 minutos)
* **¿Por qué regresarlo?** Consultar los datos de IA cada minuto por cada usuario saturaría innecesariamente tu base de datos en Railway. 10 minutos (600 segundos) es el umbral óptimo.

---

## 2. Cooldown de Notificaciones Locales (Frontend)
**Archivo:** `lib/core/services/geofence_service.dart`
**Dónde:** Variable `_alertCooldownMinutes` en la parte superior del archivo.

* **Estado de Prueba (Actual):** `static const int _alertCooldownMinutes = 1;` 
* **Estado de Producción:** `static const int _alertCooldownMinutes = 15;`
* **¿Por qué regresarlo?** El GPS de los teléfonos fluctúa. Si un usuario camina por el borde de una zona de riesgo o se queda ahí un buen rato, 1 minuto causaría que la app le llene la barra de notificaciones con spam ("¡Estás en zona de riesgo!" cada minuto). 15 minutos garantiza un recordatorio prudente sin ser molesto.

---

🛑 **NOTA SOBRE CAMBIOS PERMANENTES:**
El ajuste que hicimos en `lib/core/services/map_service.dart` donde agregamos la función `GeofenceService.refreshZones()` dentro de `clearCache()` **NO debe revertirse**. Ese fue un parche vital para solucionar el bug de desincronización de las geocercas en segundo plano.