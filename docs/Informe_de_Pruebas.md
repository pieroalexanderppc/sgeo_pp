```
Universidad Privada de Tacna (UPT)
Escuela Profesional de Ingeniería de Sistemas (EPIS)
Asignatura: Construcción de Software II | Ciclo X
Unidad III: Entrega y Mantenimiento del Software

INFORME DE EJECUCIÓN DE PRUEBAS DE SOFTWARE
(Test Completion Report — ISO/IEC/IEEE 29119-3)
SGEO — Sistema de Geolocalización de Inseguridad Ciudadana

Versión: 1.0
Fecha de ejecución: 02 de Julio de 2026
Documento de referencia: Plan_de_Pruebas.md v1.0
```

---

## 1. RESUMEN EJECUTIVO

Se ejecutó la campaña de pruebas automatizadas del sistema SGEO cubriendo el backend
(FastAPI + MongoDB) y el frontend móvil (Flutter). El resultado global es el siguiente:

| Indicador | Valor |
|---|---|
| **Total de pruebas automatizadas** | **82** |
| Pruebas de backend (pytest) | 68 |
| Pruebas de frontend (flutter_test) | 14 |
| **Aprobadas (PASSED)** | **82 (100 %)** |
| Fallidas (FAILED) | 0 |
| Defectos críticos abiertos | 0 |
| Defectos detectados y corregidos en la iteración | 8 |
| Tiempo total de ejecución | ≈ 4 s (backend) + ≈ 2 s (frontend) |

Contra los criterios de finalización de la Sección 3 del Plan de Pruebas: la tasa de éxito
(100 %) supera el umbral mínimo del 90 %, los casos ejecutados superan el 95 % del plan
automatizable, y no quedan defectos críticos abiertos. **El dictamen de la campaña es
APROBADO.**

---

## 2. ENTORNO DE PRUEBAS

| Componente | Versión / Detalle |
|---|---|
| Sistema operativo | Windows 11 Pro (build 26200) |
| Python | 3.14.3 |
| pytest | 9.1.1 |
| mongomock (BD en memoria) | 4.3.0 |
| FastAPI / TestClient | 0.135.1 (httpx) |
| Flutter SDK | 3.41.5 (channel stable) |
| flutter_test | incluido en el SDK |
| Base de datos de pruebas | mongomock — **aislada**; ninguna prueba toca MongoDB Atlas de producción |
| Servicios externos | Firebase (push) y motor IA reemplazados por dobles de prueba (monkeypatch) |

**Principio de aislamiento aplicado (Plan de Pruebas §6.1):** las suites montan el router
bajo prueba en una instancia limpia de FastAPI en lugar de importar `main:app`, evitando el
lifespan real (conexión a producción + hilo de la IA). El envío de emails SMTP y las
notificaciones FCM se anulan con `monkeypatch`.

---

## 3. INVENTARIO DE SUITES Y RESULTADOS

### 3.1 Backend — `backend/tests/` (68 pruebas, 68 PASSED)

#### Suite `test_utils.py` — Pruebas unitarias de utilitarios puros (24)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1–8 | `test_get_turno_limites_de_cada_franja` (8 casos parametrizados) | Fronteras exactas de los 4 turnos: 0/5 MADRUGADA, 6/11 MAÑANA, 12/17 TARDE, 18/23 NOCHE (técnica BVA) | PASS |
| 9 | `test_get_turno_weight_madrugada_es_el_mas_riesgoso` | Orden de pesos de riesgo: MADRUGADA > NOCHE > TARDE > MAÑANA | PASS |
| 10 | `test_get_local_time_devuelve_hora_de_lima_por_defecto` | Offset UTC−5 de Perú | PASS |
| 11 | `test_get_local_time_zona_invalida_usa_lima` | Zona horaria inválida degrada a America/Lima | PASS |
| 12 | `test_limpiar_distrito_nombre_exacto` | Coincidencia exacta de distrito | PASS |
| 13 | `test_limpiar_distrito_normaliza_minusculas_y_tildes` | Normalización de mayúsculas/tildes | PASS |
| 14–17 | `test_limpiar_distrito_atajos_manuales` (4 casos parametrizados) | Alias frecuentes (Gregorio Albarracín, La Yarada, Alto Alianza) | PASS |
| 18 | `test_limpiar_distrito_fuzzy_matching` | Corrección de errores tipográficos (difflib ≥ 0.65) | PASS |
| 19 | `test_limpiar_distrito_vacio_o_desconocido_cae_a_tacna` | Valores nulos/desconocidos degradan a TACNA | PASS |
| 20 | `test_coordenadas_distritos_dentro_de_rango_de_tacna` | Las 9 coordenadas maestras caen dentro del rango geográfico de Tacna | PASS |
| 21–24 | `test_hash_y_verify_password_roundtrip`, `..._rechaza_clave_incorrecta`, `..._hash_corrupto_no_lanza_excepcion`, `..._usa_salt_aleatorio` | Contrato completo de bcrypt (hash ≠ texto plano, verificación, tolerancia a hash corrupto, salt aleatorio) | PASS |

#### Suite `test_report_service.py` — Unitarias del servicio de reportes (12)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `test_construir_metadatos_estructura_completa` | Normalización a mayúsculas, estado `pendiente`, GeoJSON `[lng, lat]`, turno y día de semana derivados de hora de Lima | PASS |
| 2 | `test_construir_metadatos_anonimo_sin_usuario` | Reporte sin usuario queda `anonimo: true` | PASS |
| 3 | `test_construir_metadatos_modalidad_por_defecto` | Modalidad ausente → "NO ESPECIFICADO" | PASS |
| 4 | `test_limite_diario_pasa_con_menos_de_5` | 4 reportes del día no bloquean | PASS |
| 5 | `test_limite_diario_bloquea_el_sexto` | El 6.º reporte lanza HTTP 429 | PASS |
| 6 | `test_confirmar_actualiza_estado_y_devuelve_coordenadas` | Confirmación cambia estado y retorna lat/lng para el push | PASS |
| 7 | **`test_regresion_confirmar_copia_historial_con_campos_del_schema`** | **Regresión del defecto D-01**: la copia a `historial_delitos` usa `departamento_hecho`, `provincia_hecho`, `distrito_hecho`, `turno_hecho` y `fuente="ciudadano"` (el enum del schema) | PASS |
| 8 | `test_confirmar_id_invalido_devuelve_400` | ObjectId malformado → 400 | PASS |
| 9 | `test_confirmar_reporte_inexistente_devuelve_404` | Id inexistente → 404 | PASS |
| 10 | `test_confirmar_dos_veces_devuelve_400` | Doble confirmación → 400 | PASS |
| 11 | `test_rechazar_marca_estado_rechazado` | Rechazo persiste estado y **no** alimenta el historial de la IA | PASS |
| 12 | `test_rechazar_reporte_inexistente_devuelve_404` | Id inexistente → 404 | PASS |

#### Suite `test_reports.py` — Integración del flujo ciudadano (5)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `test_crear_reporte_guarda_pendiente_en_la_bd` | POST /api/reportes persiste con estado `pendiente` | PASS |
| 2 | `test_obtener_mis_reportes_filtra_por_usuario` | GET /mis_reportes solo devuelve los del usuario | PASS |
| 3 | `test_sexto_reporte_del_dia_devuelve_429` | Límite 5/día a nivel HTTP | PASS |
| 4 | `test_payload_sin_coordenadas_devuelve_422` | Pydantic rechaza cargas malformadas (CP-RF-008) | PASS |
| 5 | `test_eliminar_reporte_inexistente_devuelve_404` | DELETE de id desconocido → 404 (CP-RF-010) | PASS |

#### Suite `test_reports_policia.py` — Integración del flujo policía (5)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `test_confirmar_dispara_push_con_coordenadas_e_ia` | La confirmación emite push `incident` con lat/lng exactos al topic `alertas_ciudadanos` y encola el recalculo de zonas | PASS |
| 2 | `test_confirmar_inexistente_devuelve_404_y_no_notifica` | Fallo de confirmación no genera efectos colaterales | PASS |
| 3 | `test_rechazar_no_dispara_push_ni_ia` | El rechazo es silencioso (sin push, sin IA) | PASS |
| 4 | `test_listado_policia_incluye_los_tres_estados` | /policia lista pendiente/confirmado/rechazado y excluye agrupados | PASS |
| 5 | `test_eliminar_solo_reportes_pendientes` | El ciudadano solo puede borrar pendientes (400 si confirmado) | PASS |

#### Suite `test_auth_api.py` — Integración de autenticación (9)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `test_registro_ciudadano_exitoso` | Registro persiste con hash bcrypt (nunca texto plano) | PASS |
| 2 | `test_registro_email_duplicado_devuelve_400` | Unicidad de correo | PASS |
| 3 | `test_registro_nombre_duplicado_devuelve_400` | Unicidad de nombre | PASS |
| 4 | `test_registro_policia_queda_pendiente_de_aprobacion` | Gate de seguridad: cuenta policial nace `activo:false` + `aprobacion_pendiente:true` | PASS |
| 5 | `test_login_exitoso_devuelve_datos_sin_password` | La respuesta jamás incluye el hash | PASS |
| 6 | `test_login_password_incorrecta_devuelve_401` | Credencial inválida → 401 | PASS |
| 7 | `test_login_email_inexistente_devuelve_401_mismo_mensaje` | Mismo mensaje genérico: no revela si el correo existe (anti-enumeración) | PASS |
| 8 | `test_login_policia_pendiente_devuelve_403` | Policía sin aprobar no puede ingresar | PASS |
| 9 | `test_login_policia_rechazado_informa_motivo` | El rechazo comunica el motivo registrado por el admin | PASS |
| — | *(fixture del cliente)* correo Resend anulado con monkeypatch | Sin dependencia de red en toda la suite | — |

#### Suite `test_motor_ia.py` — Integración del motor de IA DBSCAN (8)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `test_detecta_el_mes_mas_reciente_con_datos` | `$max` sobre `fecha_hecho` de SIDPOL → (2026, 5) | PASS |
| 2 | `test_sin_datos_sidpol_cae_al_mes_actual` | Fallback al mes calendario actual | PASS |
| 3 | `test_genera_zonas_solo_del_ultimo_mes` | Cluster de mayo 2026 genera zona; cluster de enero 2024 se ignora. Verifica `anio_periodo`/`mes_periodo`, nivel de riesgo, delito predominante y centroide | PASS |
| 4 | `test_ignora_otras_provincias_y_sin_coordenada` | Filtros `provincia_hecho: TACNA` y `estado_coord ≠ SIN COORDENADA` | PASS |
| 5 | `test_menos_de_5_puntos_no_genera_zonas` | Umbral `min_samples=5` de DBSCAN (BVA) | PASS |
| 6 | `test_regenerar_reemplaza_zonas_anteriores` | Guardado atómico: borra zonas viejas antes de insertar | PASS |
| 7 | `test_cooldown_registra_marca_de_notificacion` | La marca `last_map_update_notification` se persiste en `db.config` | PASS |
| 8 | `test_cooldown_no_reenvia_antes_de_24h` | Dentro de la ventana de 24 h no sale push ni se sobreescribe la marca | PASS |

#### Suite `test_maps_api.py` — Integración de los endpoints de mapa (5)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `test_zonas_riesgo_serializa_y_conserva_periodo` | ObjectId→str, datetime→ISO y campos `anio_periodo`/`mes_periodo` que la app usa para auto-filtrar | PASS |
| 2 | `test_zonas_riesgo_segunda_llamada_sale_del_cache` | Cache en memoria de 60 s (`cached: true`) | PASS |
| 3 | `test_zonas_riesgo_vacio_devuelve_lista_vacia` | Sin zonas → lista vacía, no error | PASS |
| 4 | `test_puntos_exactos_solo_confirmados_recientes` | Solo confirmados de los últimos 60 días; pendientes/rechazados/antiguos excluidos | PASS |
| 5 | `test_historial_excluye_sin_coordenada` | Puntos geo-forzados a comisaría no contaminan el mapa | PASS |

### 3.2 Frontend — `test/` (14 pruebas, 14 PASSED)

#### Suite `widget_test.dart` — Smoke de arranque (1)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `Sin sesión activa la app muestra el LoginView` | Splash (3 s) → fade → LoginView con 'Bienvenido a SGEO', botón 'Iniciar Sesión' y campos de credenciales | PASS |

#### Suite `safety_button_test.dart` — Widget del design system (5)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `renderiza el label y el ícono` | Composición visual básica | PASS |
| 2 | `ejecuta onPressed al tocar` | Interacción táctil | PASS |
| 3 | `onPressed null deshabilita el botón sin lanzar errores` | Estado deshabilitado seguro | PASS |
| 4 | `isLoading muestra spinner y oculta el label` | Estado de carga | PASS |
| 5 | `expand:false ajusta el ancho al contenido (con ícono)` | Comportamiento del botón REPORTAR compacto del mapa | PASS |

#### Suite `notifications_storage_test.dart` — Almacenamiento local de alertas (8)

| # | Prueba | Verificación | Resultado |
|---|---|---|---|
| 1 | `sin datos guardados devuelve lista vacía` | Estado inicial limpio | PASS |
| 2 | `saveFromRemoteMessage guarda la notificación como no leída` | Persistencia desde push FCM + contador de no leídas | PASS |
| 3 | `la notificación más nueva queda primera en la lista` | Orden cronológico inverso | PASS |
| 4 | `markAsRead marca solo la notificación indicada` | Lectura individual | PASS |
| 5 | `markAllAsRead deja el contador de no leídas en cero` | Lectura masiva (badge del Home) | PASS |
| 6 | `deleteNotification elimina solo la indicada` | Swipe-to-dismiss | PASS |
| 7 | `clearAll borra todo el historial` | Limpieza total | PASS |
| 8 | `un push sin bloque notification se ignora` | Robustez ante mensajes de solo-data | PASS |

### 3.3 Análisis estático

| Verificación | Resultado |
|---|---|
| `flutter analyze` (todo el proyecto, 3 roles) | **No issues found** (0 errores, 0 warnings, 0 infos) |
| Parseo sintáctico de los 13 módulos Python del backend | OK |

---

## 4. TRAZABILIDAD CONTRA EL PLAN DE PRUEBAS

Actualización de la matriz de la Sección 8.3 del Plan de Pruebas:

| ID Caso | Requerimiento | Cubierto por | Resultado |
|---|---|---|---|
| CP-RF-001 | RF-001 Autenticación | `test_auth_api.py` (login exitoso / 401 / 403) | **PASSED** |
| CP-RF-002 | RF-003 Límite 5 reportes/día | `test_reports.py::test_sexto_reporte_del_dia_devuelve_429` + `test_report_service.py` (unitaria) | **PASSED** |
| CP-RF-003 | RF-005 Confirmación + IA DBSCAN | `test_reports_policia.py` + `test_motor_ia.py` | **PASSED** |
| CP-RF-004 | RF-007 Notificaciones de geocerca | Push simulado en `test_reports_policia.py`; el disparo físico del geofence en dispositivo queda como prueba **manual** (requiere GPS real) | PARCIAL (automatizado lo automatizable) |
| CP-RF-005 | RF-008 Privilegios predictivos | No automatizado — el backend no implementa middleware de autorización por token (limitación conocida documentada en routes/auth.py) | PENDIENTE (deuda técnica) |
| CP-RF-006 | RF-004 Historial ciudadano | `test_reports.py::test_obtener_mis_reportes_filtra_por_usuario` | **PASSED** |
| CP-RF-007 | RF-009 Filtros del mapa | Lógica de filtro validada por diseño (capa historial); prueba visual **manual** en dispositivo | PARCIAL |
| CP-RF-008 | RF-002 Registro con payload inválido | `test_reports.py::test_payload_sin_coordenadas_devuelve_422` + unicidad en `test_auth_api.py` | **PASSED** |
| CP-RF-009 | RF-010 Métricas Dashboard | Prueba visual **manual** (render de fl_chart) | MANUAL |
| CP-RF-010 | RF-011 Eliminar reporte | `test_reports.py::test_eliminar_reporte_inexistente_devuelve_404` + `test_reports_policia.py::test_eliminar_solo_reportes_pendientes` | **PASSED** |

---

## 5. DEFECTOS DETECTADOS Y CORREGIDOS EN LA ITERACIÓN

Registro conforme al ciclo de vida de la Sección 8.2 del Plan (todos en estado **CERRADO**):

| ID | Severidad | Módulo | Descripción del defecto (falla observada) | Causa raíz | Corrección |
|---|---|---|---|---|---|
| D-01 | **Crítica** | Backend / confirmación | Al validar un reporte la policía recibía "Document failed validation" y la confirmación fallaba | El insert a `historial_delitos` usaba campos `departamento/provincia/distrito/turno` (el schema exige sufijo `_hecho`) y `fuente="CIUDADANO_APP"` (fuera del enum) | Campos renombrados y `fuente="ciudadano"`; prueba de regresión permanente `test_regresion_confirmar_copia_historial_con_campos_del_schema` |
| D-02 | Alta | App ciudadano / mapa | Los chips de filtro (Zonas, Reportes, Mis Aportes) no respondían al toque | `GestureDetector` competía con el reconocedor de scroll del `ListView` con `BouncingScrollPhysics` | `HitTestBehavior.opaque` + `ClampingScrollPhysics` |
| D-03 | Alta | Notificaciones | "Toca para ver" no hacía nada con la app en primer plano | `flutter_local_notifications` no tenía `onDidReceiveNotificationResponse` ni payload en `show()` | Handler agregado + `payload: jsonEncode(message.data)` |
| D-04 | Media | Backend / push | "Mapa de Zonas Actualizado" se enviaba en cada confirmación policial | El motor notificaba sin ninguna ventana de enfriamiento | Cooldown de 24 h persistido en `db.config`; cubierto por 2 pruebas del motor |
| D-05 | Media | App ciudadano / mapa | Reportes confirmados invisibles según el modo de tema | Color del marcador `white/black` según tema | `AppTheme.successGreen` en ambos mapas |
| D-06 | Media | App ciudadano / HUD | Botón REPORTAR y joystick ocultos tras la barra de navegación | El body del `SlidingUpPanel` usa la altura completa de pantalla | Reposicionamiento (`bottom: 104/156`) |
| D-07 | Baja | App policía / Validar | La lista parpadeaba con un spinner cada 30 s | El auto-refresh activaba `_isLoading` | Refresh silencioso (`silent: true`) |
| D-08 | Baja | Notificaciones | Tap de notificación sin sesión abría un Home roto (userId vacío) | Falta de guard de sesión en `_handleNotificationTap` | Se ignora el tap si `is_logged_in` es falso |

**Observación registrada (no defecto):** los IDs de notificaciones locales usan
`millisecondsSinceEpoch`; dos pushes en el mismo milisegundo colisionarían. Improbable en
producción (FCM nunca entrega dos pushes en el mismo ms); documentado en el helper de la
suite de pruebas.

---

## 6. MÉTRICAS DE CIERRE (Stopping Rules — Plan §3.1)

| Métrica | Umbral del Plan | Obtenido | ¿Cumple? |
|---|---|---|---|
| Tasa de éxito | ≥ 90 % | 100 % (82/82) | ✅ |
| Casos ejecutados | ≥ 95 % del plan automatizable | 100 % | ✅ |
| Defectos críticos abiertos | < 2 | 0 | ✅ |
| Análisis estático | — | 0 issues | ✅ |

---

## 7. CÓMO REPRODUCIR LA EJECUCIÓN

```bash
# Backend (68 pruebas — no requiere MongoDB real)
cd backend
pip install pytest mongomock httpx firebase-admin
python -m pytest tests/ -v

# Frontend (14 pruebas)
cd ..
flutter test

# Análisis estático
flutter analyze
```

---

## 8. CONCLUSIONES Y DICTAMEN

1. Las 82 pruebas automatizadas se ejecutan en verde sobre una base de datos en memoria,
   sin dependencia de servicios externos, lo que las hace aptas para integrarse a un
   pipeline de CI (Plan §7, Paso 4).
2. El defecto crítico de la iteración (D-01, validación de MongoDB al confirmar reportes)
   quedó blindado con una prueba de regresión permanente.
3. Las reglas de negocio de mayor riesgo — límite diario, aprobación policial, ventana de
   60 días del mapa, detección del último mes del motor IA, cooldown de notificaciones —
   están cubiertas con pruebas de frontera (BVA) y partición de equivalencias.
4. Queda como deuda técnica documentada la ausencia de middleware de autorización por
   token (CP-RF-005): los endpoints confían en el `user_id` que envía el cliente. Se
   recomienda abordarlo antes de un despliegue público masivo.
5. Las pruebas físicas de geocerca (CP-RF-004), render de gráficos (CP-RF-009) y filtros
   visuales del mapa (CP-RF-007) permanecen como pruebas manuales en dispositivo, conforme
   a la estrategia de automatización por ROI del Plan (§2.3).

**Dictamen: APROBADO.** El sistema cumple los criterios de finalización del Plan de
Pruebas y se encuentra apto para la fase de entrega.
