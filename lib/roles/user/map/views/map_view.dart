import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/predictive_service.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/models/report_model.dart';
import '../../../../core/services/tutorial_service.dart';
import 'dart:ui' as dart_ui;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_score_fab.dart';
import '../../../../core/widgets/insights_card.dart';
import '../../../../core/widgets/safety_button.dart';
import 'widgets/report_dialog.dart';

class MapView extends StatefulWidget {
  final String userId;
  final LatLng? initialLocation;
  const MapView({super.key, required this.userId, this.initialLocation});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng? _currentPosition;
  LatLng? _realUserPosition;
  final MapController _mapController = MapController();
  final PanelController _panelController = PanelController();
  dynamic _selectedZona;

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  List<dynamic> _zonasRiesgo = [];
  List<dynamic> _puntosExactos = [];
  List<dynamic> _puntosHistorial = [];
  List<ReportModel> _misReportesPendientes = [];

  bool _showZonasRiesgo = true;
  bool _showReportesValidados = true;
  bool _showMisReportes = true;
  bool _isFilterMenuOpen = false;
  int? _filterYear;
  int? _filterMonth;
  double _currentZoom = 15.0;

  // ── Predictive Context Engine ──
  Map<String, dynamic>? _safetyScoreData;
  List<Map<String, dynamic>> _insightsData = [];
  bool _showInsightsPanel = false;

  // ── TEST MODE JOYSTICK ──
  final bool _isTestMode = true; // Cambiar a false cuando terminemos las pruebas

  void _moveJoystick(double dLat, double dLng) {
    if (_realUserPosition == null) return;
    setState(() {
      _realUserPosition = LatLng(
        _realUserPosition!.latitude + dLat,
        _realUserPosition!.longitude + dLng,
      );
      _currentPosition = _realUserPosition;
      _mapController.move(_realUserPosition!, _mapController.camera.zoom);
    });
    // Volver a cargar el motor predictivo y notificaciones en base a la nueva posición
    _loadPredictiveData(forceRefresh: true);

    // Y probamos si entramos a la zona (Bypass = true para que el mensaje siempre salga en las pruebas)
    GeofenceService.checkManualLocation(
      _realUserPosition!.latitude,
      _realUserPosition!.longitude,
      bypassCooldown: true,
    );
  }

  /// Helper robusto para extraer y guardar la fecha de cualquier estructura (ArcGis o Ciudadana)
  DateTime? _extractDate(dynamic punto) {
    if (punto is! Map) return null;
    if (punto.containsKey('_dt') && punto['_dt'] is DateTime) {
      return punto['_dt'];
    }

    // Buscar propiedades donde podría venir la fecha
    final rawString =
        punto['fecha_hora_hecho'] ??
        punto['fecha_hecho'] ??
        punto['fecha'] ??
        punto['creado_en'];

    if (rawString != null) {
      try {
        // En caso que el backend devuelva un entero (timestamp en milisegundos de ArcGIS directo)
        if (rawString is int) {
          final dt = DateTime.fromMillisecondsSinceEpoch(rawString);
          punto['_dt'] = dt;
          return dt;
        }

        // Formato string ISO
        if (rawString is String) {
          final dt = DateTime.parse(rawString).toLocal();
          punto['_dt'] = dt; // Memoizado / Caché
          return dt;
        }
      } catch (e) {
        debugPrint("Error parseando fecha: $rawString - $e");
      }
    }

    // Al subir el backend, Railway ya mandará las fechas reales.
    // Retornamos null estrictamente en lugar de forzar un año.
    return null;
  }

  List<int> get _availableYears {
    final Set<int> years = {};
    for (var p in _puntosHistorial) {
      final dt = _extractDate(p);
      if (dt != null) years.add(dt.year);
    }
    for (var p in _puntosExactos) {
      final dt = _extractDate(p);
      if (dt != null) years.add(dt.year);
    }
    for (var r in _misReportesPendientes) {
      try {
        final raw = r.fechaCompleta?.toString() ?? r.creadoEn?.toString();
        if (raw != null) {
          final dt = DateTime.parse(raw);
          years.add(dt.year);
        }
      } catch (_) {}
    }
    if (years.isEmpty) years.add(DateTime.now().year);
    final sorted = years.toList()..sort();
    return sorted.reversed.toList(); // Newest first
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocationJump(widget.initialLocation!);
    } else {
      _determinePosition();
    }
    _loadZonasRiesgo();
    _loadPuntosExactos();
    _loadPuntosHistorial();
    _loadMisReportes();

    TutorialService.triggerTutorialNotifier.addListener(_tutorialListener);
    ReportService.reportsUpdatedNotifier.addListener(_reportsUpdatedListener);
  }

  /// Carga el Safety Score y los Insights para la posición actual del usuario.
  Future<void> _loadPredictiveData({bool forceRefresh = false}) async {
    if (_realUserPosition == null) return;
    try {
      // Inyectamos la hora local del dispositivo para evitar problemas con la zona horaria del servidor
      final int currentHour = DateTime.now().hour;

      final score = await PredictiveService.fetchSafetyScore(
        lat: _realUserPosition!.latitude,
        lng: _realUserPosition!.longitude,
        hora: currentHour,
        forceRefresh: forceRefresh,
      );
      final insights = await PredictiveService.fetchContextInsights(
        lat: _realUserPosition!.latitude,
        lng: _realUserPosition!.longitude,
        hora: currentHour,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _safetyScoreData = score;
          _insightsData = insights;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos predictivos: $e');
    }
  }

  Future<void> _loadPuntosHistorial() async {
    try {
      final puntos = await MapService.fetchPuntosHistorial();

      // Inyección de _dt
      for (var p in puntos) {
        final raw = p['fecha_hora_hecho'] ?? p['fecha_hecho'];
        if (raw is String) {
          try {
            p['_dt'] = DateTime.parse(raw);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _puntosHistorial = puntos;
        });
      }
    } catch (e) {
      debugPrint("❌ Error cargando puntos historiales: $e");
    }
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation &&
        widget.initialLocation != null) {
      _currentLocationJump(widget.initialLocation!);
    }
  }

  void _currentLocationJump(LatLng target) {
    setState(() {
      _currentPosition = target;
      _isLoading = false;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        try {
          _mapController.move(target, 17.0);
        } catch (_) {}
      }
    });
  }

  Future<void> _loadMisReportes() async {
    try {
      final reportes = await ReportService.getMyReports(widget.userId);
      if (mounted) {
        setState(() {
          _misReportesPendientes = reportes
              .where((r) => r.latitud != null && r.longitud != null)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando mis reportes pendientes: $e');
    }
  }

  void _tutorialListener() {
    final tutorialType = TutorialService.triggerTutorialNotifier.value;
    if (tutorialType != null) {
      if (mounted && showcaseContext != null) {
        if (tutorialType == 'all') {
          ShowCaseWidget.of(showcaseContext!).startShowCase([
            TutorialService.mapFilterBtnKey,
            TutorialService.mapReportBtnKey,
          ]);
        } else if (tutorialType == 'report') {
          ShowCaseWidget.of(
            showcaseContext!,
          ).startShowCase([TutorialService.mapReportBtnKey]);
        } else if (tutorialType == 'filter') {
          ShowCaseWidget.of(
            showcaseContext!,
          ).startShowCase([TutorialService.mapFilterBtnKey]);
        }
      }
    }
  }

  void _reportsUpdatedListener() {
    if (mounted) {
      _loadMisReportes();
      _loadPuntosExactos();
    }
  }

  Future<void> _loadPuntosExactos() async {
    try {
      final puntos = await MapService.fetchPuntosExactos();

      // Inyección de _dt
      for (var p in puntos) {
        final raw = p['fecha_hora_hecho'] ?? p['fecha'];
        if (raw is String) {
          try {
            p['_dt'] = DateTime.parse(raw);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _puntosExactos = puntos;
        });
      }
    } catch (e) {
      debugPrint("❌ Error cargando puntos exactos: $e");
    }
  }

  Future<void> _loadZonasRiesgo() async {
    try {
      final zonas = await MapService.fetchZonasRiesgo();
      if (!mounted) return;
      setState(() {
        _zonasRiesgo = zonas;
      });
      // Sincronizamos directamente con el servicio de geocerca para pruebas locales
      GeofenceService.syncZonesDirectly(_zonasRiesgo);
    } catch (e) {
      debugPrint("❌ Error cargando zonas de riesgo: $e");
    }
  }

  Color _getColorForNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return AppTheme.successGreen.withValues(alpha: 0.15);
      case 'medio':
        return AppTheme.alertAmber.withValues(alpha: 0.2);
      case 'alto':
        return Colors.redAccent.withValues(alpha: 0.25);
      case 'critico':
        return AppTheme.alertRed.withValues(alpha: 0.35);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  Color _getSolidColorForNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return AppTheme.successGreen;
      case 'medio':
        return AppTheme.alertAmber;
      case 'alto':
        return Colors.redAccent;
      case 'critico':
        return AppTheme.alertRed;
      default:
        return Colors.grey;
    }
  }

  void _useFallbackLocation({bool userForced = false}) {
    if (!mounted) return;
    setState(() {
      if (widget.initialLocation != null && !userForced) {
        _currentPosition = widget.initialLocation;
      } else {
        _currentPosition ??= const LatLng(-18.0146, -70.2536);
      }
      _isLoading = false;
    });

    if (userForced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ No se pudo obtener ubicación exacta tan rapido. Esperando actualizacion...',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: AppTheme.alertAmber,
        ),
      );
    }
  }

  Future<void> _determinePosition({bool userForced = false}) async {
    if (userForced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buscando ubicación actual, por favor espera...'),
          duration: Duration(seconds: 4),
        ),
      );
      setState(() => _isLoading = true);
    }
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation(userForced: userForced);
        if (userForced) await Geolocator.openLocationSettings();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation(userForced: userForced);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation(userForced: userForced);
        if (userForced) await Geolocator.openAppSettings();
        return;
      }

      _iniciarRastreoUbicacion();

      Position? position;
      if (!userForced) {
        try {
          if (!kIsWeb) {
            position = await Geolocator.getLastKnownPosition();
          }
        } catch (_) {}
      }

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
            ),
          ).timeout(const Duration(seconds: 15));
        } catch (e) {
          debugPrint('Aviso GPS: $e');
        }
      }

      if (mounted && position != null) {
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _realUserPosition = newPos;
          if (widget.initialLocation == null || userForced) {
            _currentPosition = newPos;
          }
          _isLoading = false;
        });

        // Cargar datos predictivos cuando se obtiene la posición
        _loadPredictiveData();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          try {
            if (widget.initialLocation == null || userForced) {
              _mapController.move(newPos, 16.0);
            } else {
              _mapController.move(widget.initialLocation!, 16.0);
            }
          } catch (e) {
            debugPrint('Error map: $e');
          }
        });
      } else if (mounted) {
        if (_realUserPosition == null) {
          _useFallbackLocation(userForced: userForced);
        } else {
          setState(() => _isLoading = false);
          if (userForced && _realUserPosition != null) {
            try {
              _mapController.move(_realUserPosition!, 16.0);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Error crítico geolocator: $e');
      _useFallbackLocation(userForced: userForced);
    }
  }

  void _abrirFormularioReporte(LatLng coordenada) async {
    final reportado = await showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        latitud: coordenada.latitude,
        longitud: coordenada.longitude,
        userId: widget.userId,
      ),
    );

    if (reportado == true) {
      _loadPuntosExactos();
      _loadMisReportes();
    }
  }

  void _iniciarRastreoUbicacion() {
    _positionStreamSubscription ??=
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
          ),
        ).listen((Position position) {
          if (mounted) {
            final newPos = LatLng(position.latitude, position.longitude);
            setState(() {
              _realUserPosition = newPos;
              if (_currentPosition == null ||
                  _currentPosition == const LatLng(-18.0146, -70.2536)) {
                _currentPosition = newPos;
                _isLoading = false;
                Future.delayed(const Duration(milliseconds: 300), () {
                  try {
                    _mapController.move(newPos, 16.0);
                  } catch (_) {}
                });
              }
            });
          }
        });
  }

  void _handleMapTap(TapPosition _, LatLng tapLatLng) {
    const Distance distance = Distance();

    for (var zona in _zonasRiesgo) {
      if (zona['centroide'] == null ||
          zona['centroide']['coordinates'] == null) {
        continue;
      }

      final coords = zona['centroide']['coordinates'];
      final lat = (coords[1] as num).toDouble();
      final lng = (coords[0] as num).toDouble();
      final radius = (zona['radio_metros'] as num?)?.toDouble() ?? 500.0;

      final zoneLatLng = LatLng(lat, lng);
      final distToTap = distance.as(LengthUnit.Meter, zoneLatLng, tapLatLng);

      if (distToTap <= radius) {
        _showZoneInfo(zona);
        return;
      }
    }
  }

  void _showZoneInfo(dynamic zona) {
    setState(() {
      _selectedZona = zona;
    });
    _panelController.open();
  }

  Widget _buildPanelContent() {
    if (_selectedZona == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zona = _selectedZona;
    final nivel = zona['nivel_riesgo'].toString().toUpperCase();
    final colorNivel = _getSolidColorForNivel(nivel);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.textMuted : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorNivel.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.whatshot, color: colorNivel, size: 28),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zona de Riesgo $nivel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.textPrimary : null,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
                    if (zona['distrito'] != null)
                      Text(
                        zona['distrito'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textSecondary
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPanelTile(
            icon: Icons.security,
            iconColor: AppTheme.accentBlue,
            title:
                'Incidentes registrados: ${zona['total_incidentes'] ?? "Varios"}',
            subtitle: 'Basado en denuncias y reportes policiales.',
            isDark: isDark,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
          if (zona['delito_predominante'] != null)
            _buildPanelTile(
              icon: Icons.warning_rounded,
              iconColor: AppTheme.alertRed,
              title: 'Delito frecuente: ${zona['delito_predominante']}',
              isDark: isDark,
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
          _buildPanelTile(
            icon: Icons.trending_up,
            iconColor: AppTheme.alertAmber,
            title: 'Tendencia: ${zona['tendencia'] ?? "Desconocida"}',
            isDark: isDark,
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildPanelTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgDeep : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textPrimary : null,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textSecondary : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  BuildContext? showcaseContext;

  @override
  void dispose() {
    TutorialService.triggerTutorialNotifier.removeListener(_tutorialListener);
    ReportService.reportsUpdatedNotifier.removeListener(
      _reportsUpdatedListener,
    );
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      builder: (ctx) {
        showcaseContext = ctx;

        return Scaffold(
          body: SlidingUpPanel(
            controller: _panelController,
            minHeight: 0,
            maxHeight: 380,
            backdropEnabled: true,
            backdropOpacity: 0.4,
            backdropColor: Colors.black,
            color: Colors
                .transparent, // Transparente porque el container tiene decoracion
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            panel: _buildPanelContent(),
            body: Stack(
              children: [
                _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition!,
                          initialZoom: 15.0,
                          onPositionChanged: (position, hasGesture) {
                            if (mounted) {
                              // Optimización Fase 3: Solo redibujar la vista si el zoom cruza el umbral de 15.5
                              // para evitar consumir recursos de GPU llamando a setState decenas de veces por segundo.
                              bool wasThresh = _currentZoom > 15.5;
                              bool isThresh = position.zoom > 15.5;
                              if (wasThresh != isThresh) {
                                setState(() {
                                  _currentZoom = position.zoom;
                                });
                              } else {
                                _currentZoom = position
                                    .zoom; // Actualizar el valor en memoria sin re-renderizar todo
                              }
                            }
                          },
                          onTap: (tapPosition, latLng) {
                            _handleMapTap(tapPosition, latLng);
                          },
                          onLongPress: (tapPosition, latLng) {
                            _abrirFormularioReporte(latLng);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.example.sgeo_pp',
                          ),
                          if (_showZonasRiesgo && _zonasRiesgo.isNotEmpty)
                            CircleLayer(
                              circles: _zonasRiesgo.map<CircleMarker>((zona) {
                                final coords = zona['centroide']['coordinates'];
                                final lat = (coords[1] as num).toDouble();
                                final lng = (coords[0] as num).toDouble();
                                final radius =
                                    (zona['radio_metros'] as num?)
                                        ?.toDouble() ??
                                    500.0;

                                return CircleMarker(
                                  point: LatLng(lat, lng),
                                  color: _getColorForNivel(
                                    zona['nivel_riesgo'],
                                  ),
                                  borderStrokeWidth: isDark ? 1 : 2,
                                  borderColor: _getColorForNivel(
                                    zona['nivel_riesgo'],
                                  ).withValues(alpha: isDark ? 0.4 : 0.8),
                                  useRadiusInMeter: true,
                                  radius: radius,
                                );
                              }).toList(),
                            ),
                          MarkerLayer(
                            markers: [
                              // 0. Puntos históricos (SIDPOL + Ciudadanos) al hacer zoom
                              if (_currentZoom > 15.5)
                                ..._puntosHistorial
                                    .where((punto) {
                                      final fuente =
                                          punto['fuente'] ?? 'sidpol';
                                      if (fuente == 'ciudadano' &&
                                          !_showReportesValidados) {
                                        return false;
                                      }

                                      if (_filterYear != null ||
                                          _filterMonth != null) {
                                        final dt = _extractDate(punto);
                                        if (dt != null) {
                                          if (_filterYear != null &&
                                              dt.year != _filterYear) {
                                            return false;
                                          }
                                          if (_filterMonth != null &&
                                              dt.month != _filterMonth) {
                                            return false;
                                          }
                                        } else {
                                          return false; // Si no hay fecha, lo ocultamos bajo filtro
                                        }
                                      }
                                      return true;
                                    })
                                    .map((punto) {
                                      final coords =
                                          punto['ubicacion']['coordinates'];
                                      final subTipo =
                                          punto['subtipo_hecho'] ??
                                          punto['sub_tipo'] ??
                                          'Desconocido';
                                      final fuente =
                                          punto['fuente'] ?? 'sidpol';

                                      final dt = _extractDate(punto);
                                      String fechaHecho = 'Fecha no disponible';
                                      if (dt != null) {
                                        fechaHecho =
                                            "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                      }

                                      final modalidad =
                                          punto['modalidad_hecho'] ??
                                          punto['modalidad'] ??
                                          'No especificada';
                                      final isCitizen = fuente == 'ciudadano';

                                      return Marker(
                                        point: LatLng(
                                          (coords[1] as num).toDouble(),
                                          (coords[0] as num).toDouble(),
                                        ),
                                        width: 50,
                                        height: 50,
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            _showIncidentDetailsBottomSheet(context, {
                                              'title': 'Detalle Histórico',
                                              'subTipo': subTipo,
                                              'modalidad': modalidad,
                                              'fechaHecho': fechaHecho,
                                              'origen': isCitizen ? "Reporte validado (App)" : "Registro Policial SIDPOL",
                                              'isCitizen': isCitizen,
                                            });
                                          },
                                          child: _buildAnimatedMarker(
                                            isCitizen ? AppTheme.accentBlue : AppTheme.alertRed,
                                            isCitizen ? Icons.person_pin_circle : Icons.local_police,
                                          ),
                                        ),
                                      );
                                    }),

                              // 1. Puntos exactos reportados
                              if (_showReportesValidados)
                                ..._puntosExactos
                                    .where((punto) {
                                      if (_filterYear != null ||
                                          _filterMonth != null) {
                                        final dt = _extractDate(punto);
                                        if (dt != null) {
                                          if (_filterYear != null &&
                                              dt.year != _filterYear) {
                                            return false;
                                          }
                                          if (_filterMonth != null &&
                                              dt.month != _filterMonth) {
                                            return false;
                                          }
                                        } else {
                                          return false; // Si no hay fecha, no pasa el filtro
                                        }
                                      }
                                      return true;
                                    })
                                    .map((punto) {
                                      final coords =
                                          punto['ubicacion']['coordinates'];
                                      final estadoStr = (punto['estado'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final colorPunto =
                                          estadoStr.contains('pendiente')
                                          ? AppTheme.alertAmber
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black);
                                      final subTipo =
                                          punto['subtipo_hecho'] ?? 'Incidente';

                                      final dt = _extractDate(punto);
                                      String fechaHecho = 'Fecha no disponible';
                                      if (dt != null) {
                                        fechaHecho =
                                            "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                      }

                                      return Marker(
                                        point: LatLng(
                                          (coords[1] as num).toDouble(),
                                          (coords[0] as num).toDouble(),
                                        ),
                                        width: 50,
                                        height: 50,
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showIncidentDetailsBottomSheet(context, {
                                              'title': 'Alerta Ciudadana',
                                              'subTipo': subTipo,
                                              'fechaHecho': fechaHecho,
                                              'origen': 'Reporte en curso (Validado)',
                                              'isCitizen': true,
                                              'estadoStr': estadoStr,
                                              'estadoColor': colorPunto,
                                              'color': colorPunto,
                                              'icon': Icons.report_problem_rounded,
                                            });
                                          },
                                          child: _buildAnimatedMarker(
                                            colorPunto,
                                            Icons.report_problem_rounded,
                                          ),
                                        ),
                                      );
                                    }),

                              // 1.5. Propios reportes pendientes del usuario (Azul tactico)
                              if (_showMisReportes)
                                ..._misReportesPendientes
                                    .where((reporte) {
                                      if (_filterYear != null ||
                                          _filterMonth != null) {
                                        final fechaRaw =
                                            reporte.fechaCompleta ??
                                            reporte.creadoEn;
                                        if (fechaRaw != null) {
                                          try {
                                            final dt = DateTime.parse(
                                              fechaRaw.toString(),
                                            );
                                            if (_filterYear != null &&
                                                dt.year != _filterYear) {
                                              return false;
                                            }
                                            if (_filterMonth != null &&
                                                dt.month != _filterMonth) {
                                              return false;
                                            }
                                          } catch (_) {
                                            return false;
                                          }
                                        } else {
                                          return false;
                                        }
                                      }
                                      return true;
                                    })
                                    .map((reporte) {
                                      return Marker(
                                        point: LatLng(
                                          reporte.latitud!,
                                          reporte.longitud!,
                                        ),
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                          onTap: () {
                                            final rawDate =
                                                reporte.fechaCompleta ??
                                                reporte.creadoEn.toString();
                                            String fechaTexto = 'Desconocida';
                                            try {
                                              final d = DateTime.parse(
                                                rawDate,
                                              ).toLocal();
                                              fechaTexto =
                                                  "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
                                            } catch (_) {}

                                            _showIncidentDetailsBottomSheet(context, {
                                              'title': 'Mi Reporte',
                                              'subTipo': reporte.subTipo,
                                              'modalidad': reporte.descripcion ?? 'Sin descripción.',
                                              'fechaHecho': fechaTexto,
                                              'origen': 'Reporte Pendiente',
                                              'isCitizen': true,
                                              'estadoStr': reporte.estado,
                                              'estadoColor': AppTheme.accentBlue,
                                              'color': AppTheme.accentBlue,
                                              'icon': Icons.person_pin_circle_rounded,
                                            });
                                          },
                                          child: _buildAnimatedMarker(
                                            AppTheme.accentBlue,
                                            Icons.person_pin_circle_rounded,
                                          ),
                                        ),
                                      );
                                    }),

                              // 2. Posicion actual REAL del usuario
                              if (_realUserPosition != null)
                                Marker(
                                  point: _realUserPosition!,
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentBlue.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentBlue.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentBlue,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                // ── HUD SUPERIOR PREMIUM (Buscador y Filtros en Glassmorphism) ──
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // 1. Barra de Búsqueda Flotante
                      // 1. Barra de Búsqueda y Botón Reportar
                      SizedBox(
                        height: 52,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: dart_ui.ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.bgSurface.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppTheme.borderTactical
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.menu,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Buscar zonas...",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: isDark
                                            ? AppTheme.borderTactical
                                            : Colors.grey.shade300,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          Icons.search,
                                          color: AppTheme.accentBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 140,
                            child: Showcase(
                              key: TutorialService.mapReportBtnKey,
                              title: 'Reportar Incidente',
                              description:
                                  'Presiona aquí para reportar un incidente en tu ubicación actual.',
                              targetPadding: const EdgeInsets.all(8),
                              tooltipBackgroundColor: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              textColor: isDark ? Colors.white : Colors.black87,
                              child: SafetyButton.danger(
                                label: 'REPORTAR',
                                icon: Icons.campaign_rounded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                fontSize: 13,
                                borderRadius: 16,
                                onPressed: () {
                                  if (_realUserPosition != null) {
                                    _abrirFormularioReporte(_realUserPosition!);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Esperando tu ubicación GPS...'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),

                      const SizedBox(height: 12),

                      // 2. Chips de Filtros (Scroll Horizontal Deslizable)
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildGlassChip(
                              title: "Zonas de Riesgo",
                              icon: Icons.warning_amber_rounded,
                              isActive: _showZonasRiesgo,
                              onTap: () => setState(
                                () => _showZonasRiesgo = !_showZonasRiesgo,
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildGlassChip(
                              title: "Reportes",
                              icon: Icons.shield,
                              isActive: _showReportesValidados,
                              onTap: () => setState(
                                () => _showReportesValidados =
                                    !_showReportesValidados,
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildGlassChip(
                              title: "Mis Aportes",
                              icon: Icons.person_pin_circle,
                              isActive: _showMisReportes,
                              onTap: () => setState(
                                () => _showMisReportes = !_showMisReportes,
                              ),
                              isDark: isDark,
                            ),
                            // Se incluye filtro de fecha si se necesita
                            const SizedBox(width: 8),
                            _buildGlassChip(
                              title: "Año ${_filterYear ?? 'Todos'}",
                              icon: Icons.calendar_month,
                              isActive: _filterYear != null,
                              onTap: () => setState(() {
                                _isFilterMenuOpen = !_isFilterMenuOpen;
                              }),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      // Contenedor extra si se da tap en "Fechas"
                      if (_isFilterMenuOpen)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.bgSurface.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildDateFilters(isDark),
                        ).animate().fadeIn(),
                    ],
                  ),
                ),

                // ====== JOYSTICK PARA TEST DE NOTIFICACIONES ======
                if (_isTestMode)
                  Positioned(
                    bottom:
                        120, // Aumentado significativamente para saltar la barra de navegación del celular
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.bgElevated.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: AppTheme.accentBlue.withValues(alpha: 0.3),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up, size: 28),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppTheme.accentBlue,
                            onPressed: () => _moveJoystick(0.0005, 0),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_left,
                                  size: 28,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: AppTheme.accentBlue,
                                onPressed: () => _moveJoystick(0, -0.0005),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.adjust_rounded,
                                size: 22,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_right,
                                  size: 28,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: AppTheme.accentBlue,
                                onPressed: () => _moveJoystick(0, 0.0005),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppTheme.accentBlue,
                            onPressed: () => _moveJoystick(-0.0005, 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── SAFETY SCORE FAB (Compacto, flotante a la derecha) ──
                if (_safetyScoreData != null && !_isLoading)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    top: MediaQuery.of(context).padding.top +
                        (_isFilterMenuOpen ? 210 : 132),
                    right: 16,
                    child: SafetyScoreFab(
                      score:
                          (_safetyScoreData!['score'] as num?)?.toDouble() ??
                          65.0,
                      nivel: _safetyScoreData!['nivel'] ?? 'precaucion',
                      mensaje: _safetyScoreData!['mensaje'] ?? '',
                      diameter: 52,
                      onExpandInsights: () {
                        if (_insightsData.isNotEmpty) {
                          _showInsightsBottomSheet(context);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'map_location',
            mini: false,
            backgroundColor: isDark
                ? AppTheme.bgSurface.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
            foregroundColor: isDark ? AppTheme.accentBlue : Colors.black87,
            elevation: 4,
            onPressed: () => _determinePosition(userForced: true),
            child: const Icon(Icons.my_location, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildDateFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtro por Fecha',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textSecondary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  initialValue: _filterYear,
                  hint: const Text('Año', style: TextStyle(fontSize: 12)),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos', style: TextStyle(fontSize: 12)),
                    ),
                    ..._availableYears.map(
                      (y) => DropdownMenuItem<int?>(
                        value: y,
                        child: Text(
                          y.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filterYear = val),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  dropdownColor: isDark ? AppTheme.bgSurface : Colors.white,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  initialValue: _filterMonth,
                  hint: const Text('Mes', style: TextStyle(fontSize: 12)),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos', style: TextStyle(fontSize: 12)),
                    ),
                    ...List.generate(12, (i) {
                      const meses = [
                        'Ene',
                        'Feb',
                        'Mar',
                        'Abr',
                        'May',
                        'Jun',
                        'Jul',
                        'Ago',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dic',
                      ];
                      return DropdownMenuItem<int?>(
                        value: i + 1,
                        child: Text(
                          meses[i],
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _filterMonth = val),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  dropdownColor: isDark ? AppTheme.bgSurface : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper para los chips de Glassmorphism Premium ──
  Widget _buildGlassChip({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentBlue.withValues(alpha: 0.2)
              : (isDark
                    ? AppTheme.bgSurface.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.accentBlue
                : (isDark ? AppTheme.borderTactical : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppTheme.accentBlue
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? AppTheme.accentBlue
                    : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Sheet táctico para Insights de Seguridad ──
  void _showInsightsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = _getScoreColorForInsights();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.bgSurface.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppTheme.borderTactical : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.purpleAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insights de Seguridad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.textPrimary : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Análisis predictivo de tu zona',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMuted : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Score badge en el header
                    if (_safetyScoreData != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scoreColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Score: ${(_safetyScoreData!['score'] as num?)?.toStringAsFixed(0) ?? '--'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              // Lista de insights
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  shrinkWrap: true,
                  itemCount: _insightsData.length,
                  itemBuilder: (ctx, index) {
                    final insight = _insightsData[index];
                    final severidad = insight['severidad'] ?? 'info';
                    final color = _severityColorForInsight(severidad);
                    final bgColor = color.withValues(alpha: 0.08);
                    final icon = _resolveInsightIcon(insight['icono']);

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                insight['mensaje'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.textPrimary : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColorForInsights() {
    final score = (_safetyScoreData?['score'] as num?)?.toDouble() ?? 50;
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 50) return AppTheme.alertAmber;
    return AppTheme.alertRed;
  }

  Color _severityColorForInsight(String severidad) {
    switch (severidad) {
      case 'danger': return AppTheme.alertRed;
      case 'warning': return AppTheme.alertAmber;
      case 'info': return AppTheme.accentBlue;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _resolveInsightIcon(String? iconName) {
    switch (iconName) {
      case 'schedule': return Icons.schedule_rounded;
      case 'verified_user': return Icons.verified_user_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'trending_down': return Icons.trending_down_rounded;
      case 'warning': return Icons.warning_rounded;
      case 'event': return Icons.event_rounded;
      default: return Icons.info_rounded;
    }
  }

  void _showIncidentDetailsBottomSheet(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = data['color'] as Color? ?? (data['isCitizen'] == true ? AppTheme.accentBlue : AppTheme.alertRed);
    final icon = data['icon'] as IconData? ?? (data['isCitizen'] == true ? Icons.person_pin_circle : Icons.local_police);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderTactical, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Detalle del Incidente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.warning_rounded, 'Tipo', data['subTipo'], isDark),
              if (data['modalidad'] != null) _buildDetailRow(Icons.info_outline_rounded, 'Modalidad', data['modalidad'], isDark),
              _buildDetailRow(Icons.access_time_rounded, 'Fecha', data['fechaHecho'], isDark),
              _buildDetailRow(Icons.source_rounded, 'Origen', data['origen'], isDark, valueColor: color),
              if (data['estadoStr'] != null)
                _buildDetailRow(Icons.check_circle_outline_rounded, 'Estado', data['estadoStr'].toString().toUpperCase(), isDark, valueColor: data['estadoColor']),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.bgDeep : Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : Colors.black54,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDark ? AppTheme.textMuted : Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMarker(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5), duration: 1500.ms)
         .fade(begin: 0.8, end: 0.0, duration: 1500.ms),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ],
    );
  }
}
