# PROJECT_MAP — SGEO (Sistema de Geolocalización de Inseguridad Ciudadana)

## Stack
- **Frontend:** Flutter (Dart SDK `^3.11.3`) — estado: dev (build local vía `flutter run`/`flutter build apk`; sin evidencia de publicación en Play Store/App Store)
- **Backend:** FastAPI 0.104.1 (Uvicorn ASGI) — Python 3.11.x — estado: **producción** (Railway, `https://sgeo-backend-production.up.railway.app`)
- **BD / Storage:** MongoDB Atlas, base `geocrimen_tacna`, 4 colecciones activas en código: `usuarios`, `reportes_ciudadano`, `historial_delitos`, `zonas_riesgo` (ver Notas — el README documenta 7, pero solo 4 están implementadas)
- **Deploy:** Backend en Railway (`Procfile`: `uvicorn main:app --host 0.0.0.0 --port $PORT`); Firebase Cloud Messaging para push (proyecto `sgeo-7e191`, solo plataforma Android configurada en `firebase_options.dart`)

## Árbol de módulos clave

### Flutter (lib/)
| Alias | Ruta | Responsabilidad |
|-------|------|-----------------|
| @auth | lib/features/auth/views/ | Login, registro y splash screen |
| @map_user | lib/roles/user/map/views/map_view.dart | Mapa ciudadano: FlutterMap, zonas de riesgo, reporte de incidentes, safety score, geocercas |
| @map_police | lib/roles/police/map/views/map_view.dart | Mapa policial táctico (perímetro 3km), validación de reportes |
| @report_dialog | lib/roles/user/map/views/widgets/report_dialog.dart | Diálogo de creación de denuncia (tipo, descripción, geocodificación inversa Nominatim) |
| @models | lib/core/models/report_model.dart | Modelo `ReportModel` tipado (NO existe carpeta `lib/models/` separada) |
| @api | lib/core/config/api_config.dart | `ApiConfig`: centraliza base URL y rutas de todos los endpoints del backend |
| @services | lib/core/services/ | `AuthService`, `MapService`, `ReportService`, `GeofenceService`, `PredictiveService`, `NotificationsStorageService`, `TutorialService`, `UserService`, `AdminService` (nuevo), `PoliceService` (nuevo) |
| @widgets | lib/core/widgets/ | Sistema "Premium Tactical Dark": `SafetyLayout`, `SafetyCard`, `SafetyButton` (+ `ButtonVariant` primary/secondary/danger/ghost, rediseño v2), `SafetyScoreGauge`, `SafetyScoreFab` (+ gradiente accentCyan→accentBlue y entrada `elasticOut`, rediseño v2), `InsightsCard`. **Nuevos (rediseño v2):** `StatusBadge` (chip de estado: pendiente/confirmado/rechazado/aprobado/activo/suspendido/agrupado), `RoleBadge` (chip de rol: ciudadano/policía/admin), `SectionHeader` (encabezado título+subtítulo+acción — creado pero aún sin consumidores), `InfoRow` (fila etiqueta/valor; se llamaba `DataRow` en el plan original pero colisiona con `material.dart`), `NavBounceIcon` (pulso de escala al seleccionar un tab del `BottomNavigationBar`), `AnimatedCountBadge` (ícono+badge con scale-pop al cambiar el conteo), `SkeletonLoader` (placeholder con shimmer para listas en carga, vía `flutter_animate`, sin dependencias nuevas) |
| @theme | lib/core/theme/app_theme.dart | `AppTheme`, `themeNotifier`. Rediseño v2: tipografía Inter (antes Montserrat), `accentCyan` (único color nuevo, uso selectivo), `displayFont()`/`monoFont()`, `inputDecorationTheme`/`dialogTheme`/`snackBarTheme`/`bottomSheetTheme` alineados a `borderSubtle`/`accentCyan` |
| @roles_admin | lib/roles/admin/{dashboard,home,profile,users,approvals}/views/ | Dashboard analítico (fl_chart) + KPIs de usuarios, gestión de usuarios, perfil admin, panel de Solicitudes (aprobar/rechazar policías, nuevo) |
| @roles_police | lib/roles/police/{home,map,profile,validations,inicio}/views/ | Shell policial (5 tabs), mapa táctico (círculo 3km + joystick de simulación), panel de validación (tabs Pendientes/Historial), perfil, resumen operativo del día (nuevo) |
| @roles_user | lib/roles/user/{home,map,news,notifications,profile,reports}/views/ | Shell ciudadano, mapa, feed RSS de noticias, notificaciones, perfil, historial de reportes |
| @entry | lib/main.dart, lib/firebase_options.dart | Entry point: init Firebase/FCM, notificaciones locales, routing por rol vía SharedPreferences |

### Backend
| Alias | Ruta | Responsabilidad |
|-------|------|-----------------|
| @routes | backend/routes/ | Endpoints: `auth.py`, `reports.py`, `maps.py`, `predictive.py`, `users.py`, `admin.py` (este último ahora protegido por `require_admin_role`, ver Reglas críticas) |
| @models_be | backend/models/ | Esquemas Pydantic: `auth_schemas.py`, `user_schemas.py` (+ `RechazoUsuarioRequest`, nuevo), `report_schemas.py` |
| @services_be | backend/services/ | `report_service.py` (validación/confirmación/rechazo de denuncias), `analytics_service.py` (regresión lineal), `email_service.py` (nuevo — emails del flujo de aprobación policial vía Resend) |
| @utils_be | backend/utils/ | `crypto.py` (bcrypt), `string_helpers.py` (normalización de distritos), `time_helpers.py` (turnos/zona horaria) |
| @config_be | backend/config/database.py | Conexión MongoDB (`DatabaseManager`, proxies de colección), creación de índices `2dsphere` |
| @ia_core | backend/motor_ia_zonas_riesgo.py | Motor DBSCAN (clustering espacial de hotspots) |
| @predictive_core | backend/predictive_context_engine.py | `TemporalAnalyzer`, `SafetyScoreCalculator`, `InsightGenerator`, `SafeHoursCalculator` |
| @firebase_be | backend/firebase_service.py | Inicialización Firebase Admin SDK y envío de push FCM |
| @etl | backend/scripts_iniciales/ | `setup_db.py`, `extract_arcgis_data.py`, `import_arcgis_data.py` (ETL histórico SIDPOL/ArcGIS) |
| @tests_be | backend/tests/ | `conftest.py` + `test_reports.py` (nuevo — pytest + mongomock, monta solo el router de `reports` para no disparar el lifespan/IA real) |

## Endpoints registrados
| Método | Ruta | Controlador | Descripción |
|--------|------|-------------|-------------|
| GET | `/` | main.py | Health check (`{"status":"ok"}`) |
| POST | `/api/auth/login` | routes/auth.py → `login` | Autenticación email/password (bcrypt). Si `rol=="policia"` y `activo==False`: 403 ("siendo revisada" o, si hay `motivo_rechazo`, el motivo exacto) — **actualizado** |
| POST | `/api/auth/register` | routes/auth.py → `register` | Registro de usuario. Si `rol=="policia"`: además marca `aprobacion_pendiente=True`, `activo=False` y envía email de verificación (Resend); respuesta indica "revisa tu correo" en vez de "registrado correctamente" — **actualizado**, sin tocar `RegisterRequest` |
| GET | `/api/usuarios/{user_id}` | routes/users.py → `obtener_usuario` | Obtiene perfil (sin password_hash) |
| PUT | `/api/usuarios/{user_id}` | routes/users.py → `actualizar_usuario` | Actualiza nombre, email, teléfono |
| POST | `/api/reportes` | routes/reports.py → `crear_reporte` | Crea denuncia ciudadana (límite 5/día si autenticado) |
| POST | `/api/reportes/confirmar/{reporte_id}` | routes/reports.py → `confirmar_reporte` | Policía confirma → mueve a `historial_delitos`, agrupa cercanos (500m), push FCM, dispara IA |
| POST | `/api/reportes/rechazar/{reporte_id}` | routes/reports.py → `rechazar_reporte` | Policía rechaza → agrupa reportes cercanos inválidos |
| GET | `/api/reportes/mis_reportes/{user_id}` | routes/reports.py → `obtener_mis_reportes` | Historial de denuncias propias |
| DELETE | `/api/reportes/{reporte_id}` | routes/reports.py → `eliminar_mi_reporte` | Elimina denuncia propia pendiente |
| GET | `/api/reportes/policia` | routes/reports.py → `obtener_reportes_policia` | Lista reportes pendientes/confirmados/**rechazados** para policía (antes excluía rechazados por completo — ver Notas), incluye `gravedad`/`confirmado_en`/`rechazado_en` — **actualizado** |
| POST | `/api/map/generar_zonas_ia` | routes/maps.py → `desencadenar_ia_zonas` | Trigger manual del motor DBSCAN (background) |
| GET | `/api/map/zonas_riesgo` | routes/maps.py → `obtner_zonas_riesgo` | Zonas de riesgo (cache en memoria 60s) |
| GET | `/api/map/puntos_exactos` | routes/maps.py → `obtener_puntos_exactos` | Incidentes confirmados (evita falsos positivos) |
| GET | `/api/map/historial_puntos` | routes/maps.py → `obtener_historial_puntos` | Historial completo (ArcGIS + reportes validados) |
| GET | `/api/predictive/safety_score` | routes/predictive.py → `get_safety_score` | Score de seguridad 0-100 por ubicación+hora |
| GET | `/api/predictive/temporal_analysis` | routes/predictive.py → `get_temporal_analysis` | Distribución por hora/día/turno/tendencia |
| GET | `/api/predictive/context_insights` | routes/predictive.py → `get_context_insights` | Hasta 6 recomendaciones contextuales |
| GET | `/api/predictive/risk_forecast` | routes/predictive.py → `get_risk_forecast` | Pronóstico de riesgo por turno/distrito |
| GET | `/api/predictive/safe_hours` | routes/predictive.py → `get_safe_hours` | Horas más seguras/riesgosas (z-score) |
| GET | `/api/admin/dashboard_stats` | routes/admin.py → `obtener_dashboard_stats` | Estadísticas en vivo de reportes (filtrable por tiempo) |
| GET | `/api/admin/sidpol_stats` | routes/admin.py → `obtener_sidpol_stats` | Estadísticas históricas SIDPOL (top distritos/tipos) |
| GET | `/api/admin/sidpol_predict` | routes/admin.py → `obtener_sidpol_prediccion` | Predicción a 3 meses (Regresión Lineal) por distrito |
| GET | `/api/admin/usuarios` | routes/admin.py → `listar_usuarios` | Lista usuarios (sin password_hash); `?rol=` o `?pendiente=true` (policías con `aprobacion_pendiente=True`) — **nuevo** |
| PUT | `/api/admin/usuarios/{id}/aprobar` | routes/admin.py → `aprobar_usuario` | Aprueba policía pendiente (`activo=True`, `aprobacion_pendiente=False`) y dispara email de aprobación — **nuevo** |
| PUT | `/api/admin/usuarios/{id}/rechazar` | routes/admin.py → `rechazar_usuario` | Rechaza policía con `{"motivo": str}` (`activo=False`, guarda `motivo_rechazo`) y dispara email de rechazo — **nuevo** |
| DELETE | `/api/admin/usuarios/{id}` | routes/admin.py → `eliminar_usuario` | Elimina el documento de usuario completo — **nuevo** |
| PUT | `/api/admin/usuarios/{id}/suspender` | routes/admin.py → `suspender_usuario` | Toggle de `activo` (cualquier rol) — **nuevo** |

**Nota:** `ApiConfig` en Flutter (`lib/core/config/api_config.dart`) referencia todos estos endpoints salvo los de `/api/predictive/*`, que son consumidos por `PredictiveService` — verificar que las rutas estén alineadas 1:1 antes de modificar cualquiera de los dos lados. `[REVISAR]` si existen endpoints adicionales no documentados aquí ni en `ApiConfig`.

**Nota (nuevo):** todo `/api/admin/*` (los 3 endpoints originales y los 5 nuevos) ahora exige el header `X-User-Role: admin` (dependencia `require_admin_role` a nivel de router) — ver Reglas críticas sobre por qué esto **no es seguridad real**. `AdminService` (Flutter) ya envía este header en cada llamada; cualquier código nuevo que golpee `/api/admin/*` directo con `http` sin pasar por `AdminService` quedará bloqueado con 403.

## Modelos de datos
| Modelo | Archivo Flutter | Archivo Backend | Campos principales |
|--------|----------------|-----------------|-------------------|
| Reporte/Incidente | lib/core/models/report_model.dart (`ReportModel`) | backend/models/report_schemas.py (`ReporteCiudadano`) | Flutter: id, estado, subTipo, creadoEn, direccion, descripcion, latitud, longitud, rangoHorario, gravedad, fechaCompleta, diaSemana, precisionGps, timestampUtc. Backend: subtipo_hecho, modalidad_hecho, latitud, longitud, direccion_hecho, distrito/provincia/departamento_hecho, descripcion, usuario_id, precision_gps, fuente, gravedad, device_timestamp, timezone, metadata_contextual |
| Login | — (manejado inline en `AuthService`) | backend/models/auth_schemas.py (`LoginRequest`) | email, password |
| Registro | — (manejado inline en `register_view.dart`) | backend/models/auth_schemas.py (`RegisterRequest`) | nombre, email, password, rol (default "ciudadano"), is_active |
| Usuario (update) | — (manejado inline en `profile_view.dart`) | backend/models/user_schemas.py (`UpdateUser`) | nombre, email, telefono |
| Rechazo de usuario (nuevo) | — (manejado inline en `ApprovalsView`) | backend/models/user_schemas.py (`RechazoUsuarioRequest`) | motivo |

**`[REVISAR]`**: no existen clases Dart `LoginModel`/`UserModel` tipadas — los datos de usuario se pasan como `Map`/parámetros sueltos entre `AuthService`/`UserService` (nuevo, ver Bloque 2) y las vistas. Se mantuvo así deliberadamente para no introducir una abstracción nueva fuera del alcance pedido; si se requiere consistencia estricta Flutter↔Backend, considerar crear modelos Dart equivalentes a `auth_schemas.py`/`user_schemas.py`.

## Reglas críticas del proyecto
- ✅ **RESUELTO** — **FlutterMap (`@map_user`, `@map_police`)**: confirmado explícitamente por el usuario durante el rediseño visual v2 — no tocar `FlutterMap` ni ningún widget dentro de las pantallas de mapa. Única excepción concedida explícitamente: widgets que viven en archivo propio fuera del árbol de `FlutterMap` aunque su pantalla "padre" sea el mapa (`@report_dialog`, `SafetyScoreFab`), y ajustes de color de un token suelto dentro del joystick policial (`map_view.dart` línea ~1064, `Colors.grey` → `AppTheme.textSecondary`) explícitamente listado en el plan del rediseño. Cualquier otro cambio dentro de `lib/roles/{user,police}/map/views/map_view.dart` requiere confirmación explícita, no asumirla.
- **"Sin tildes ni ñ" — NO aplica**: el código fuente usa tildes y ñ libremente en comentarios y strings de UI en español (ej. `"Iniciar Sesión - SGEO"`, `widget_test.dart:23`). Esta regla del template no está vigente en este repo; no aplicarla a menos que el usuario la confirme explícitamente.
- **Caché en memoria sin Redis**: `routes/maps.py` y `routes/predictive.py` usan caché en memoria de proceso (TTL 60s / 30s) — comentarios `TODO` y advertencias explícitas (agregadas en este pase) indican que esto rompe si se escala a más de un worker/réplica. Hoy el `Procfile` corre `uvicorn main:app` sin `--workers` (1 solo proceso), así que el riesgo está dormido mientras Railway no escale horizontalmente. No asumir que el caché es compartido entre instancias si eso cambia.
- **Sin JWT/sesión por token**: confirmado — `routes/auth.py` solo verifica credenciales una vez y no emite token; ningún otro endpoint valida sesión, confían en el `user_id`/`usuario_id` que envía el cliente. `SECRET_KEY` en `.env`/`.env.example` está declarada pero sin uso (documentado explícitamente en ambos archivos). Decisión del equipo: no implementar JWT por ahora — cualquier interceptor de error 401 en Flutter sería código muerto hasta que esto cambie.
- **`/api/admin/*` usa un guard de rol cosmético, no autenticación real**: `routes/admin.py` define `require_admin_role` (dependencia a nivel de router) que exige el header `X-User-Role: admin`. Como no hay sesión/token, el cliente envía su propio rol (leído de `SharedPreferences` por `AdminService`) — **cualquiera con `curl` puede falsificar el header**. Sirve solo para evitar llamadas accidentales desde un rol equivocado, no es un control de seguridad. Si se implementa JWT a futuro, este guard debería reemplazarse por una validación real del rol del token.
- **Flujo de aprobación policial usa `activo` como gate, no un campo nuevo**: por diseño explícito, no se modificó `RegisterRequest`. Un policía recién registrado queda con `activo=False` y `aprobacion_pendiente=True` (seteado en un `update_one` *después* del `insert_one`, que sí usa los defaults del schema sin tocarlo). El admin aprueba/rechaza vía `/api/admin/usuarios/{id}/aprobar|rechazar`, que ajustan `activo`/`aprobacion_pendiente`/`motivo_rechazo`. **Limitación conocida**: el DNI/placa/unidad del policía nunca se guardan en MongoDB (viajan solo por la respuesta del email al admin) — el panel de Solicitudes no puede mostrarlos.
- **Emails (Resend) fallan en silencio por diseño**: `services/email_service.py` nunca lanza excepción — si `RESEND_API_KEY` no está configurada (`.env.example` trae placeholders `[CONFIGURAR]`), solo loggea y continúa. No asumir que un email "se envió" solo porque el endpoint devolvió 200.
- **Límite de 5 reportes/día por usuario**: aplicado en `services/report_service.py::validar_limite_diario` — cualquier cambio al flujo de creación de reportes debe respetar esta regla salvo indicación contraria.
- **Confirmación de reporte es una operación compuesta**: `confirmar_reporte_en_db` mueve el documento a `historial_delitos`, agrupa reportes cercanos (radio 500m) y dispara el motor IA — comentarios en código (`reports.py`, `report_service.py`) marcan correcciones de bugs previos ("no ignorar IDs de usuario inválidos", "no confirmar si falla el insert a historial_delitos"); mantener ese orden de validaciones.
- **Solo Android tiene Firebase configurado**: `firebase_options.dart` lanza `UnsupportedError` para iOS/macOS/Windows/Linux. Cualquier feature que dependa de FCM no funcionará en otras plataformas hasta configurar `flutterfire`.
- **Sin gestor de estado externo**: el proyecto usa `setState` + `ValueNotifier` (no Provider/Riverpod/Bloc/GetX). No introducir un gestor de estado nuevo sin alinear con el usuario, ya que rompería el patrón establecido en todos los `services`.
- **Sin capa de modelos Dart consistente para Auth/Usuario** (ver sección de Modelos) — al tocar `@auth` o `@roles_*/profile`, verificar los campos esperados directamente contra los schemas Pydantic del backend, no contra un modelo Dart (no existe).

## Estado de features
| Feature | Flutter | Backend | Estado |
|---------|---------|---------|--------|
| Auth / login-registro | @auth | @routes (auth.py) | ✅ completo (bcrypt, roles) |
| Mapa de riesgo (ciudadano) | @map_user | @routes (maps.py) + @ia_core | ✅ completo |
| Mapa táctico + joystick simulación (policía) | @map_police | @routes (maps.py, reports.py) | ✅ completo — agregado círculo visual de 3km (`CircleLayer`) y joystick de simulación de posición (solo afecta filtros/distancias, nunca la cámara de `FlutterMap`) |
| Reportes ciudadanos (CRUD) | @report_dialog, lib/roles/user/reports/ | @routes (reports.py) + @services_be | ✅ completo |
| Panel validaciones (policía) | lib/roles/police/validations/ | @routes (reports.py: confirmar/rechazar) | ✅ completo — tabs Pendientes/Historial, Confirmar/Rechazar también disponible desde el mapa (`PoliceService`, compartido) |
| Dashboard admin (live + Big Data SIDPOL) | lib/roles/admin/dashboard/ | @routes (admin.py) + @services_be (analytics_service.py) | ✅ completo — se agregó fila de KPIs (ciudadanos/policías activos/pendientes) |
| Gestión de usuarios (admin) | lib/roles/admin/users/ | @routes (admin.py: `/usuarios`, `/suspender`, DELETE) | ✅ completo — el endpoint anterior (`/api/usuarios` sin id) no existía; ahora usa `/api/admin/usuarios` con filtros, chips Todos/Ciudadanos/Policías/Suspendidos, suspender/reactivar y eliminar |
| Flujo de aprobación policial + emails (Resend) | lib/roles/admin/approvals/ | @routes (auth.py, admin.py) + @services_be (email_service.py) | ✅ completo (nuevo) — registro de policía queda `activo=False`/`aprobacion_pendiente=True`, login bloqueado con mensaje específico, panel de Solicitudes para aprobar/rechazar, emails vía Resend (placeholders `[CONFIGURAR]` si no hay API key real) |
| Predictive/Safety Score | lib/core/services/predictive_service.dart | @routes (predictive.py) + @predictive_core | ✅ completo |
| Geocercas / alertas locales | lib/core/services/geofence_service.dart | — (lado backend solo envía push, la lógica de cruce de zona es 100% cliente) | ✅ completo |
| Notificaciones push (FCM) | lib/main.dart + notifications_storage_service.dart | @firebase_be | ✅ completo |
| Feed de noticias RSS | lib/roles/user/news/ | — (consumo de XML externo, sin endpoint propio) | ✅ completo |
| ETL histórico SIDPOL/ArcGIS | — | @etl | ✅ completo (ejecución manual/cron, no expuesto vía API) |

**Hardening del rol ciudadano (Bloques 2-4, sin cambio de estado en la tabla — ya estaban en ✅ a nivel de feature, pero tenían bugs internos):**
- *Reportes ciudadanos*: el límite de 5/día (HTTP 429) estaba silenciado en el cliente (`MapService.crearReporte` descartaba el `statusCode`) — corregido, ahora se muestra "Límite de reportes alcanzado por hoy". `ReportService.deleteReport` también dejó de mostrar mensajes genéricos cuando el backend sí da un detalle específico.
- *Perfil*: `ProfileView` hacía `http` directo en vez de usar la capa de servicios — se extrajo a `UserService` (nuevo), que además interpreta correctamente `detail` como string u objeto de validación Pydantic.
- *Notificaciones / Home*: se agregó badge de no leídas en el tab "Alertas" y disparo automático del tutorial guiado en el primer ingreso (el flag `has_seen_map_tutorial` se escribía pero nunca se leía).
- *Mapa ciudadano*: se desactivó el joystick de pruebas (`_isTestMode`) que había quedado expuesto en producción. No se tocó el widget `FlutterMap`.

**Hardening de los roles policía/admin (Bloques 0-4):**
- *Gestión de usuarios (admin)*: `UsersManageView` apuntaba a `GET /api/usuarios` (sin id) — **ese endpoint nunca existió**, la pantalla siempre estaba vacía. Migrado a `GET /api/admin/usuarios`.
- *Validaciones (policía)*: `ValidationsView` y `PoliceMapView` leían `sub_tipo`/`direccion`/`modalidad` — el backend devuelve `subtipo_hecho`/`direccion_hecho`/`modalidad_hecho`. El subtipo de delito y la dirección **nunca se mostraban** (siempre caían al texto de fallback). Corregido en ambos archivos.
- *`/api/reportes/policia` excluía los reportes rechazados por completo* (`$in: ["pendiente", "confirmado"]`) y no proyectaba `gravedad` — hacía imposible construir el contador "Rechazados hoy" o un tab de Historial con datos reales. Se amplió el filtro e incluyeron los campos faltantes; se agregó `rechazado_en` (no existía) en `rechazar_reporte_en_db`.
- *Perfiles admin/policía*: mismo fix que ciudadano — `http` directo → `UserService`.
- Todos los cambios de backend de este bloque se verificaron con `mongomock` (sin tocar la BD real) antes de darlos por completos.

**Rediseño visual v2 — "todos los roles" (Bloques 0-8, solo Flutter, cero cambios de lógica de negocio):**
- *Sistema de diseño*: tipografía global Inter (antes Montserrat), `accentCyan` agregado a `AppTheme` (único color nuevo, uso selectivo — no reemplaza `accentBlue` como color por defecto), `ButtonVariant` (primary/secondary/danger/ghost) en `SafetyButton`, propiedad `elevated` en `SafetyCard`. Ver fila `@widgets` para los 7 widgets nuevos.
- *Auth*: splash/login/register con gradiente de fondo, tarjetas con animación de entrada, selector de rol en registro pasó de `Switch` a 2 tarjetas seleccionables.
- *Por rol*: nav bar de cada rol con su color distintivo (ciudadano/admin = `accentCyan`, policía = `alertAmber`, coincide con `RoleBadge`); `StatusBadge`/`RoleBadge`/`InfoRow` reemplazan chips y filas armados a mano en perfiles, reportes, validaciones, solicitudes y gestión de usuarios; KPIs del resumen operativo policial en 32px.
- *Dialogs/sheets/snackbars*: `dialogTheme`/`snackBarTheme`/`bottomSheetTheme` alineados a `borderSubtle` (antes `borderTactical`); se encontró y corrigió un campo de texto en el panel de Solicitudes (admin) que ignoraba por completo el tema global (`border: OutlineInputBorder()` fijo).
- *Animaciones*: `NavBounceIcon` (pulso al seleccionar tab), `AnimatedCountBadge` (scale-pop al cambiar conteo) y `SkeletonLoader` (shimmer, vía `flutter_animate`) son nuevos — antes no existía ninguna animación de carga tipo skeleton en el proyecto.
- *Regla dura respetada*: no se tocó `FlutterMap` ni la lógica de mapas (filtros, cachés, geocercas, cálculo de posición). Las únicas excepciones, explícitamente autorizadas, fueron `@report_dialog` (archivo propio), `SafetyScoreFab` (archivo propio) y un color suelto dentro del joystick policial — ver Reglas críticas.
- *Pendiente/omitido a propósito*: `SectionHeader` se creó pero no se usó en ninguna pantalla (no encajaba bien en los lugares evaluados); `lib/roles/user/news/views/news_view.dart` no se tocó (ya tenía un estilo propio bien resuelto); el diálogo "Confirmar/Rechazar incidente" dentro de `map_view.dart` (policía) quedó con su borde antiguo (`borderTactical`) sin alinear — vive dentro del archivo del mapa y no estaba en la lista de excepciones autorizadas.

## Dependencias externas críticas

### Flutter (pubspec.yaml)
| Paquete | Versión | Usado en | Notas |
|---------|---------|----------|-------|
| flutter_map | ^8.2.2 | @map_user, @map_police | Mapas OSM — widget central, ver Reglas críticas |
| latlong2 | ^0.9.1 | @map_user, @map_police | Coordenadas geográficas |
| geolocator | ^14.0.2 | geofence_service.dart | GPS, geocercas (muestreo cada 50m) |
| http | ^1.6.0 | @api, @services | Cliente HTTP nativo (no Dio) |
| firebase_core | ^4.7.0 | main.dart | Init Firebase |
| firebase_messaging | ^16.2.0 | main.dart | FCM (solo Android configurado) |
| flutter_local_notifications | ^21.0.0 | main.dart | Notificaciones locales |
| shared_preferences | ^2.5.5 | auth_service.dart, main.dart | Sesión, rol, notificaciones persistidas |
| fl_chart | ^1.2.0 | lib/roles/admin/dashboard/ | Gráficos del dashboard |
| google_fonts | ^8.1.0 | @theme | Tipografía |
| lottie | ^3.3.2 / flutter_animate | ^4.5.2 | Animaciones UI |
| sliding_up_panel | ^2.0.0+1 | @map_user, @map_police | Panel inferior de filtros |
| showcaseview | 3.0.0 (fijo, sin `^`) | — | Tutorial/onboarding — `[REVISAR]` por qué está pineado sin rango |
| xml | ^6.6.1 | lib/roles/user/news/ | Parseo de feed RSS |
| intl | ^0.20.2 | varios | Formateo de fechas |
| url_launcher | ^6.3.2 | — | Deep linking |

### Backend (requirements.txt)
| Paquete | Versión | Usado en | Notas |
|---------|---------|----------|-------|
| fastapi | 0.104.1 | main.py | Framework |
| uvicorn | 0.24.0 | main.py / Procfile | Servidor ASGI |
| pymongo | 4.6.0 | config/database.py | Driver MongoDB |
| bcrypt | 4.1.1 | utils/crypto.py | Hash de contraseñas |
| scikit-learn | 1.3.2 | motor_ia_zonas_riesgo.py, analytics_service.py | DBSCAN + LinearRegression |
| pandas | 2.1.3 | analytics_service.py, scripts_iniciales/ | Procesamiento de datos |
| numpy | 1.26.2 | motor_ia_zonas_riesgo.py | Cálculos numéricos |
| firebase-admin | 6.3.0 | firebase_service.py | Push FCM |
| pydantic | 2.5.2 (+ pydantic[email]) | models/ | Validación de esquemas |
| python-dotenv | 1.0.0 | config/database.py, firebase_service.py | Variables de entorno |
| pytz | 2023.3 | utils/time_helpers.py | Zona horaria America/Lima |
| httpx | 0.25.1 | @services_be (email_service.py) + @tests_be | **Ya no es solo de test** — runtime real para llamar a la API de Resend |
| pytest | 7.4.3 | @tests_be | Solo test, no runtime |
| mongomock | 4.1.2 | @tests_be | MongoDB en memoria para tests, solo test |

## Convenciones detectadas
- **Nombrado de archivos:** snake_case en ambos lados (`api_config.dart`, `report_model.dart`, `motor_ia_zonas_riesgo.py`)
- **Nombrado de clases:** PascalCase (`ApiConfig`, `ReportModel`, `MapView`, `TemporalAnalyzer`, `DatabaseManager`)
- **Nombrado de funciones/métodos:** camelCase en Dart, snake_case en Python
- **Estructura de respuesta API:** `{"status": "success", ...campos variables según endpoint...}` en éxito; `{"detail": "mensaje de error"}` en error (vía `HTTPException` de FastAPI) — **no** sigue el patrón fijo `{status, data, message}` propuesto en la plantilla; cada endpoint agrega sus propias claves (`usuario`, `score`, `id_reporte`, etc.)
- **Manejo de errores:** backend usa `HTTPException` con códigos HTTP explícitos (401, 429, etc.); Flutter maneja errores principalmente con try/catch y `SnackBar`/diálogos locales (no hay interceptor HTTP centralizado)
- **Estado / State management:** sin librería externa — `setState` local + `ValueNotifier` para eventos cross-widget (`ReportService.reportsUpdatedNotifier`, `AppTheme.themeNotifier`, `NotificationsStorageService.updateNotifier`, `TutorialService.triggerTutorialNotifier`, `AdminService.pendingCountNotifier`, `PoliceService.pendingReportsNotifier`)
- **Arquitectura Flutter:** feature-first por rol (`lib/roles/{admin|police|user}/{feature}/views/`), más un núcleo compartido (`lib/core/`) y un módulo transversal (`lib/features/auth/`)
- **Idioma:** identificadores de código en inglés, comentarios y strings de UI en español (con tildes/ñ)

## Variables de entorno (backend/.env)
| Variable | Usada en | Notas |
|----------|----------|-------|
| `MONGO_URL` | config/database.py | Cadena de conexión MongoDB Atlas |
| `SECRET_KEY` | — | Declarada pero sin uso (no hay JWT) — ver Reglas críticas |
| `FIREBASE_CREDENTIALS_JSON` | firebase_service.py | JSON del service account (alternativa al archivo local `sgeo-firebase-adminsdk.json`) |
| `PORT` | main.py / Procfile | Puerto del servidor (Railway lo inyecta automáticamente) |
| `ENV` | main.py | `development` → CORS abierto; cualquier otro valor → lista restringida |
| `RESEND_API_KEY` | services/email_service.py | API key de Resend — **nuevo**. Sin configurar, los emails solo se loggean (no se envían, no se rompe el flujo) |
| `RESEND_FROM_EMAIL` | services/email_service.py | Remitente de los emails — **nuevo**, `[CONFIGURAR]` dominio verificado en Resend |
| `ADMIN_EMAIL` | services/email_service.py | Recibe el `reply_to` del email de verificación policial — **nuevo**, `[CONFIGURAR]` correo real del administrador |

## Notas del análisis
- **Discrepancia README vs. código real (colecciones Mongo):** `README.md` documenta 7 colecciones (`usuarios`, `reportes_ciudadano`, `incidentes`, `estadisticas_sidpol`, `estadisticas_flagrancia`, `estadisticas_sidpol_historico`, `zonas_riesgo`, `alertas`), pero `backend/config/database.py` solo crea índices y proxies para 4: `usuarios`, `reportes_ciudadano`, `historial_delitos`, `zonas_riesgo`. El nombre `historial_delitos` tampoco aparece en la lista del README. Tratar el README como aspiracional/desactualizado en este punto; confiar en `config/database.py` y en los `routes/*.py` como fuente de verdad.
- ✅ **RESUELTO** (decisión: documentar, no implementar JWT) — **`SECRET_KEY` en `.env.example` no parece usarse**: confirmado, no hay JWT ni firma de sesión en ninguna ruta (`auth.py` solo verifica bcrypt y devuelve el usuario, una sola vez). Se documentó explícitamente en `.env.example` y `routes/auth.py` que la variable es vestigial y que ningún endpoint valida sesión.
- ✅ **RESUELTO** — **Sin tests de backend**: se agregó `backend/tests/` (`conftest.py` + `test_reports.py`) con 3 tests del flujo crítico de reportes (crear, listar propios, límite 5/día → 429), usando `mongomock` para no tocar la BD real. Verificados localmente (3/3 passed). Sigue sin haber tests para `maps.py`, `predictive.py`, `users.py`, `admin.py` ni `auth.py` — cobertura parcial, no total.
- ✅ **RESUELTO** — **CORS abierto a `*`** en `backend/main.py`: ahora depende de `ENV` (`ENV=development` → abierto; cualquier otro valor → lista restringida). **Ojo**: el dominio puesto en la lista restringida es la URL del propio backend (no hay frontend web desplegado hoy, no existe carpeta `web/`) — corregirlo el día que exista un origen real de un cliente web.
- ⚠️ **PARCIALMENTE RESUELTO** — **Caché en memoria de proceso** en `routes/maps.py` y `routes/predictive.py`: se agregaron advertencias explícitas sobre el riesgo multi-worker/multi-réplica. La migración a Redis (el TODO original) no se hizo. Confirmado que el `Procfile` corre un solo worker hoy, así que el riesgo no está activo mientras Railway no escale horizontalmente.
- ✅ **RESUELTO** — `routes/users.py::obtener_usuario` tenía un `except Exception` que envolvía su propio `HTTPException(404, "Usuario no encontrado")` deliberado y lo re-empaquetaba como `400` con un mensaje confuso. Se agregó `except HTTPException: raise` antes del `except Exception` genérico — ahora un usuario inexistente devuelve 404 real.
- ✅ **RESUELTO** — `GET /api/reportes/policia` excluía por completo los reportes con `estado=="rechazado"` (`$in: ["pendiente", "confirmado"]`) y no proyectaba `gravedad`. Hacía imposible construir el contador "Rechazados hoy" o un tab de Historial con datos reales para el rol policía. Se amplió el filtro a `["pendiente", "confirmado", "rechazado"]`, se agregó `gravedad`/`confirmado_en`/`rechazado_en` a la proyección, y se agregó el seteo de `rechazado_en` (no existía) en `services/report_service.py::rechazar_reporte_en_db`.
- **Plataformas soportadas:** el repo tiene carpetas `android/` e `ios/` generadas por Flutter, pero `firebase_options.dart` solo define configuración real para Android (`UnsupportedError` para el resto) — tratar el proyecto como Android-first hasta que se corra `flutterfire configure` para iOS.
- **No hay carpeta `lib/models/`** como sugiere la plantilla genérica — los modelos Dart viven en `lib/core/models/`. Ajustado el alias `@models` en este mapa para reflejar la ruta real.
- **Documentación existente paralela:** `docs/SCRUM.md`, `docs/DIAGRAMAS.md`, `docs/Plan_Despliegue_Arquitectura.md` y los informes `FD0X-EPIS-*.md` contienen contexto de gestión de proyecto (Scrum, arquitectura, factibilidad) que complementa este mapa técnico pero no fue usado como fuente para las tablas de endpoints/modelos (se usó el código fuente directamente).
