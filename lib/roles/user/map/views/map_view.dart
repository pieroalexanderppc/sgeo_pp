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
import '../../../../core/models/report_model.dart';
import '../../../../core/services/tutorial_service.dart';
import 'dart:ui' as dart_ui;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_score_gauge.dart';
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

  /// Helper robusto para extraer y guardar la fecha de cualquier estructura (ArcGis o Ciudadana)
  DateTime? _extractDate(dynamic punto) {
    if (punto is! Map) return null;
    if (punto.containsKey('_dt') && punto['_dt'] is DateTime) {
      return punto['_dt'];
    }
    
    // Buscar propiedades donde podría venir la fecha
    final rawString = punto['fecha_hora_hecho'] ?? punto['fecha_hecho'] ?? punto['fecha'] ?? punto['creado_en'];
    
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
  Future<void> _loadPredictiveData() async {
    if (_realUserPosition == null) return;
    try {
      final score = await PredictiveService.fetchSafetyScore(
        lat: _realUserPosition!.latitude,
        lng: _realUserPosition!.longitude,
      );
      final insights = await PredictiveService.fetchContextInsights(
        lat: _realUserPosition!.latitude,
        lng: _realUserPosition!.longitude,
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
          try { p['_dt'] = DateTime.parse(raw); } catch (_) {}
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
          ShowCaseWidget.of(showcaseContext!).startShowCase([TutorialService.mapReportBtnKey]);
        } else if (tutorialType == 'filter') {
          ShowCaseWidget.of(showcaseContext!).startShowCase([TutorialService.mapFilterBtnKey]);
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
          try { p['_dt'] = DateTime.parse(raw); } catch (_) {}
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
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 800.ms, curve: Curves.easeInOut, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
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
                          color: isDark ? AppTheme.textSecondary : Colors.grey[600],
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
            title: 'Incidentes registrados: ${zona['total_incidentes'] ?? "Varios"}',
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
                ]
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
    ReportService.reportsUpdatedNotifier.removeListener(_reportsUpdatedListener);
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
            color: Colors.transparent, // Transparente porque el container tiene decoracion
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            panel: _buildPanelContent(),
            body: Stack(
              children: [
                _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.location_on,
                                size: 40,
                                color: AppTheme.accentBlue,
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                .scale(duration: 800.ms, curve: Curves.easeInOut)
                                .tint(color: AppTheme.accentBlueLight, duration: 800.ms),
                            const SizedBox(height: 24),
                            Text(
                              "Ubicando señal GPS...",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textSecondary : Colors.grey[700],
                              ),
                            ).animate().fadeIn(duration: 500.ms),
                          ],
                        ),
                      )
                    : _currentPosition == null
                    ? const Center(
                        child: Text(
                          'No se pudo inicializar el mapa. Revisar permisos.',
                        ),
                      )
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
                                _currentZoom = position.zoom; // Actualizar el valor en memoria sin re-renderizar todo
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
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.example.sgeo_pp',
                          ),
                          if (_showZonasRiesgo && _zonasRiesgo.isNotEmpty)
                            CircleLayer(
                              circles: _zonasRiesgo.map<CircleMarker>((zona) {
                                final coords = zona['centroide']['coordinates'];
                                final lat = (coords[1] as num).toDouble();
                                final lng = (coords[0] as num).toDouble();
                                final radius = (zona['radio_metros'] as num?)?.toDouble() ?? 500.0;

                                return CircleMarker(
                                  point: LatLng(lat, lng),
                                  color: _getColorForNivel(zona['nivel_riesgo']),
                                  borderStrokeWidth: isDark ? 1 : 2,
                                  borderColor: _getColorForNivel(zona['nivel_riesgo']).withValues(alpha: isDark ? 0.4 : 0.8),
                                  useRadiusInMeter: true,
                                  radius: radius,
                                );
                              }).toList(),
                            ),
                          MarkerLayer(
                            markers: [
                              // 0. Puntos históricos (SIDPOL + Ciudadanos) al hacer zoom
                              if (_currentZoom > 15.5)
                                ..._puntosHistorial.where((punto) {
                                  final fuente = punto['fuente'] ?? 'sidpol';
                                  if (fuente == 'ciudadano' && !_showReportesValidados) return false;
                                  
                                  if (_filterYear != null || _filterMonth != null) {
                                    final dt = _extractDate(punto);
                                    if (dt != null) {
                                      if (_filterYear != null && dt.year != _filterYear) return false;
                                      if (_filterMonth != null && dt.month != _filterMonth) return false;
                                    } else {
                                      return false; // Si no hay fecha, lo ocultamos bajo filtro
                                    }
                                  }
                                  return true;
                                }).map((punto) {
                                  final coords = punto['ubicacion']['coordinates'];
                                  final subTipo = punto['subtipo_hecho'] ?? punto['sub_tipo'] ?? 'Desconocido';
                                  final fuente = punto['fuente'] ?? 'sidpol';
                                  
                                  final dt = _extractDate(punto);
                                  String fechaHecho = 'Fecha no disponible';
                                  if (dt != null) {
                                    fechaHecho = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                  }
                                  
                                  final modalidad = punto['modalidad_hecho'] ?? punto['modalidad'] ?? 'No especificada';
                                  final isCitizen = fuente == 'ciudadano';

                                  return Marker(
                                    point: LatLng(
                                      (coords[1] as num).toDouble(),
                                      (coords[0] as num).toDouble(),
                                    ),
                                    width: 36, // Area táctil más grande
                                    height: 36,
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: BackdropFilter(
                                                filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                                child: Container(
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: isDark ? AppTheme.borderTactical : Colors.grey.shade300, width: 1),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            isCitizen ? Icons.person_pin_circle : Icons.local_police,
                                                            color: isCitizen ? AppTheme.accentBlue : AppTheme.alertRed,
                                                            size: 28,
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              'Detalle Histórico',
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                                color: isDark ? Colors.white : Colors.black87,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 20),
                                                      Text('Delito: $subTipo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                                                      const SizedBox(height: 10),
                                                      Text('Modalidad: $modalidad', style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondary : Colors.grey[800])),
                                                      const SizedBox(height: 10),
                                                      Text('Fecha: $fechaHecho', style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondary : Colors.grey[800])),
                                                      const SizedBox(height: 10),
                                                      Text('Origen: ${isCitizen ? "Reporte validado (App)" : "Registro Policial SIDPOL"}', 
                                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isCitizen ? AppTheme.accentBlue : AppTheme.alertRed)),
                                                      const SizedBox(height: 24),
                                                      Align(
                                                        alignment: Alignment.centerRight,
                                                        child: TextButton(
                                                          style: TextButton.styleFrom(
                                                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                          ),
                                                          onPressed: () => Navigator.of(ctx).pop(),
                                                          child: Text('Cerrar', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Center(
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: isCitizen ? AppTheme.accentBlue : AppTheme.alertRed,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                              // 1. Puntos exactos reportados
                              if (_showReportesValidados)
                                ..._puntosExactos.where((punto) {
                                  if (_filterYear != null || _filterMonth != null) {
                                    final dt = _extractDate(punto);
                                    if (dt != null) {
                                      if (_filterYear != null && dt.year != _filterYear) return false;
                                      if (_filterMonth != null && dt.month != _filterMonth) return false;
                                    } else {
                                      return false; // Si no hay fecha, no pasa el filtro
                                    }
                                  }
                                  return true;
                                }).map((punto) {
                                  final coords = punto['ubicacion']['coordinates'];
                                  final estadoStr = (punto['estado'] ?? '').toString().toLowerCase();
                                  final colorPunto = estadoStr.contains('pendiente')
                                      ? AppTheme.alertAmber
                                      : (isDark ? Colors.white : Colors.black);
                                  final subTipo = punto['subtipo_hecho'] ?? 'Incidente';
                                  
                                  final dt = _extractDate(punto);
                                  String fechaHecho = 'Fecha no disponible';
                                  if (dt != null) {
                                    fechaHecho = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                  }

                                  return Marker(
                                    point: LatLng(
                                      (coords[1] as num).toDouble(),
                                      (coords[0] as num).toDouble(),
                                    ),
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: BackdropFilter(
                                                filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                                                    border: Border.all(color: colorPunto.withValues(alpha: 0.5), width: 1),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                                          color: colorPunto.withValues(alpha: 0.15),
                                                          border: Border(bottom: BorderSide(color: colorPunto.withValues(alpha: 0.3))),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.report_problem_rounded, color: colorPunto, size: 24),
                                                            const SizedBox(width: 12),
                                                            const Expanded(
                                                              child: Text('Alerta Ciudadana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(20),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('Delito: $subTipo', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                                            const SizedBox(height: 12),
                                                            Text('Fecha: $fechaHecho', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[800])),
                                                            const SizedBox(height: 12),
                                                            Text(
                                                              punto['descripcion'] ?? 'Reporte validado y confirmado en esta zona.',
                                                              style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[800], height: 1.4),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: estadoStr.contains('pendiente') ? AppTheme.alertAmber.withValues(alpha: 0.1) : AppTheme.successGreen.withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: estadoStr.contains('pendiente') ? AppTheme.alertAmber.withValues(alpha: 0.3) : AppTheme.successGreen.withValues(alpha: 0.3)),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(estadoStr.contains('pendiente') ? Icons.pending_actions : Icons.check_circle_outline, 
                                                                       size: 14, 
                                                                       color: estadoStr.contains('pendiente') ? AppTheme.alertAmber : AppTheme.successGreen),
                                                                  const SizedBox(width: 6),
                                                                  Text(
                                                                    'Estado: ${punto['estado'] ?? 'Desconocido'}'.toUpperCase(),
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w800,
                                                                      letterSpacing: 1.0,
                                                                      color: estadoStr.contains('pendiente') ? AppTheme.alertAmber : AppTheme.successGreen,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                                        child: SizedBox(
                                                          width: double.infinity,
                                                          child: SafetyButton.outline(
                                                            label: 'CERRAR',
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            onPressed: () => Navigator.of(ctx).pop(),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: colorPunto,
                                        size: 28.0,
                                        shadows: [
                                          Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              // 1.5. Propios reportes pendientes del usuario (Azul tactico)
                              if (_showMisReportes)
                                ..._misReportesPendientes.where((reporte) {
                                  if (_filterYear != null || _filterMonth != null) {
                                    final fechaRaw = reporte.fechaCompleta ?? reporte.creadoEn;
                                    if (fechaRaw != null) {
                                      try {
                                        final dt = DateTime.parse(fechaRaw.toString());
                                        if (_filterYear != null && dt.year != _filterYear) return false;
                                        if (_filterMonth != null && dt.month != _filterMonth) return false;
                                      } catch (_) {
                                      	return false;
                                      }
                                    } else {
                                    	return false;
                                    }
                                  }
                                  return true;
                                }).map((reporte) {
                                  return Marker(
                                    point: LatLng(reporte.latitud!, reporte.longitud!),
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () {
                                        final rawDate = reporte.fechaCompleta ?? reporte.creadoEn.toString();
                                        String fechaTexto = 'Desconocida';
                                        try {
                                          final d = DateTime.parse(rawDate).toLocal();
                                          fechaTexto = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
                                        } catch (_) {}

                                        showDialog(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: BackdropFilter(
                                                filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                                                    border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.5), width: 1),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accentBlue.withValues(alpha: 0.15),
                                                          border: Border(bottom: BorderSide(color: AppTheme.accentBlue.withValues(alpha: 0.3))),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(Icons.person_pin_circle_rounded, color: AppTheme.accentBlue, size: 24),
                                                            const SizedBox(width: 12),
                                                            const Expanded(
                                                              child: Text('Mi Reporte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.all(20),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('Delito: ${reporte.subTipo}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                                            const SizedBox(height: 12),
                                                            Text('Fecha: $fechaTexto', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[800])),
                                                            const SizedBox(height: 12),
                                                            Text(
                                                              reporte.descripcion ?? 'Sin descripción.',
                                                              style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[800], height: 1.4),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.accentBlue),
                                                                  const SizedBox(width: 6),
                                                                  Text(
                                                                    'Estado: ${reporte.estado}'.toUpperCase(),
                                                                    style: const TextStyle(
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w800,
                                                                      letterSpacing: 1.0,
                                                                      color: AppTheme.accentBlue,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                                        child: SizedBox(
                                                          width: double.infinity,
                                                          child: SafetyButton.outline(
                                                            label: 'CERRAR',
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            onPressed: () => Navigator.of(ctx).pop(),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentBlue.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
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
                                          color: AppTheme.accentBlue.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentBlue.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentBlue,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
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

                // -- MENU DE FILTROS LATERAL --
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Showcase(
                        key: TutorialService.mapFilterBtnKey,
                        title: 'Filtros del Mapa',
                        description: 'Puedes configurar cuáles zonas de riesgo o reportes ver en el mapa.',
                        targetPadding: const EdgeInsets.all(8),
                        tooltipBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFilterMenuOpen = !_isFilterMenuOpen;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: _isFilterMenuOpen ? AppTheme.accentBlue : (isDark ? AppTheme.borderTactical : Colors.grey.shade300), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.layers_rounded,
                              color: _isFilterMenuOpen ? AppTheme.accentBlue : (isDark ? Colors.white : Colors.black87),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      
                      // Menu desplegable del Filtro
                      if (_isFilterMenuOpen)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.85),
                                  border: Border.all(color: isDark ? AppTheme.borderTactical.withValues(alpha: 0.5) : Colors.grey.shade200, width: 1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 350),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    _buildFilterSwitch(
                                      title: 'Zonas de Riesgo',
                                      value: _showZonasRiesgo,
                                      onChanged: (val) => setState(() => _showZonasRiesgo = val),
                                      isDark: isDark,
                                    ),
                                    Divider(height: 1, color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200, indent: 16, endIndent: 16),
                                    _buildFilterSwitch(
                                      title: 'Reportes Ciudadanos',
                                      value: _showReportesValidados,
                                      onChanged: (val) => setState(() => _showReportesValidados = val),
                                      isDark: isDark,
                                    ),
                                    Divider(height: 1, color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200, indent: 16, endIndent: 16),
                                    _buildFilterSwitch(
                                      title: 'Mis Reportes',
                                      value: _showMisReportes,
                                      onChanged: (val) => setState(() => _showMisReportes = val),
                                      isDark: isDark,
                                    ),
                                    Divider(height: 1, color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200, indent: 16, endIndent: 16),
                                    _buildDateFilters(isDark),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .scaleXY(begin: 0.95, end: 1.0, alignment: Alignment.topLeft, duration: 200.ms, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),

                // ====== SE ELIMINÓ EL JOYSTICK FALSO TEMPORAL ======


                // -- BOTON PARA REPORTAR (SafetyButton Premium) --
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: Showcase(
                    key: TutorialService.mapReportBtnKey,
                    title: 'Reportar Incidente',
                    description: 'Presiona aquí para reportar un incidente en tu ubicación actual.',
                    targetPadding: const EdgeInsets.all(8),
                    tooltipBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    textColor: isDark ? Colors.white : Colors.black87,
                    child: SizedBox(
                      width: 150,
                      child: SafetyButton.danger(
                        label: 'REPORTAR',
                        icon: Icons.campaign_rounded,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        fontSize: 13,
                        borderRadius: 24,
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
                ),

                // ── SAFETY SCORE GAUGE (Debajo del botón reportar) ──
                if (_safetyScoreData != null && !_isLoading)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 76,
                    right: 16,
                    width: 165,
                    child: GestureDetector(
                      onTap: () => setState(() => _showInsightsPanel = !_showInsightsPanel),
                      child: SafetyScoreGauge(
                        score: (_safetyScoreData!['score'] as num?)?.toDouble() ?? 65.0,
                        nivel: _safetyScoreData!['nivel'] ?? 'precaucion',
                        turno: _safetyScoreData!['turno_actual'] ?? '',
                        mensaje: _safetyScoreData!['mensaje'] ?? '',
                        size: 95,
                      ),
                    ),
                  ),

                // ── INSIGHTS PANEL (expandable) ──
                if (_showInsightsPanel && _insightsData.isNotEmpty)
                  Positioned(
                    bottom: 150,
                    left: 16,
                    right: 16,
                    child: InsightsCard(insights: _insightsData),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'map_location',
            mini: false,
            backgroundColor: isDark ? AppTheme.bgSurface.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
            foregroundColor: isDark ? AppTheme.accentBlue : Colors.black87,
            elevation: 4,
            onPressed: () => _determinePosition(userForced: true),
            child: const Icon(Icons.my_location, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildFilterSwitch({required String title, required bool value, required ValueChanged<bool> onChanged, required bool isDark}) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppTheme.textPrimary : Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      dense: true,
      activeTrackColor: Colors.white,
      activeThumbColor: AppTheme.accentBlue,
      inactiveThumbColor: isDark ? Colors.grey.shade400 : Colors.grey.shade300,
      inactiveTrackColor: isDark ? AppTheme.bgDeep : Colors.grey.shade400,
      onChanged: onChanged,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  initialValue: _filterYear,
                  hint: const Text('Año', style: TextStyle(fontSize: 12)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todos', style: TextStyle(fontSize: 12))),
                    ..._availableYears.map((y) => DropdownMenuItem<int?>(value: y, child: Text(y.toString(), style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (val) => setState(() => _filterYear = val),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black),
                  dropdownColor: isDark ? AppTheme.bgSurface : Colors.white,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  initialValue: _filterMonth,
                  hint: const Text('Mes', style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos', style: TextStyle(fontSize: 12))),
                      ...List.generate(12, (i) {
                        const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                        return DropdownMenuItem<int?>(value: i + 1, child: Text(meses[i], style: const TextStyle(fontSize: 12)));
                      }),
                    ],
                  onChanged: (val) => setState(() => _filterMonth = val),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black),
                  dropdownColor: isDark ? AppTheme.bgSurface : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}