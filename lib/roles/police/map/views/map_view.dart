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
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/theme/app_theme.dart';

class PoliceMapView extends StatefulWidget {
  final String userId;
  final LatLng? initialLocation;
  const PoliceMapView({super.key, required this.userId, this.initialLocation});

  @override
  State<PoliceMapView> createState() => _PoliceMapViewState();
}

class _PoliceMapViewState extends State<PoliceMapView> {
  LatLng? _currentPosition;
  LatLng? _realUserPosition;
  final MapController _mapController = MapController();
  final PanelController _panelController = PanelController();
  dynamic _selectedZona;

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  List<dynamic> _zonasRiesgo = [];
  List<dynamic> _puntosExactos = [];

  bool _showZonasRiesgo = true;
  bool _showReportesValidados = true;
  bool _isFilterMenuOpen = false;

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

    TutorialService.triggerTutorialNotifier.addListener(_tutorialListener);
    ReportService.reportsUpdatedNotifier.addListener(_reportsUpdatedListener);
  }

  @override
  void didUpdateWidget(PoliceMapView oldWidget) {
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

  void _tutorialListener() {
    final tutorialType = TutorialService.triggerTutorialNotifier.value;
    if (tutorialType != null) {
      if (mounted && showcaseContext != null) {
        if (tutorialType == 'all' || tutorialType == 'filter') {
          ShowCaseWidget.of(showcaseContext!).startShowCase([
            TutorialService.mapFilterBtnKey,
          ]);
        }
      }
    }
  }

  void _reportsUpdatedListener() {
    if (mounted) {
      _loadPuntosExactos();
    }
  }

  Future<void> _loadPuntosExactos() async {
    try {
      final puntos = await MapService.fetchPuntosPolicia();
      if (mounted) {
        setState(() {
          _puntosExactos = puntos;
        });
      }
    } catch (e) {
      debugPrint("Error cargando puntos exactos: $e");
    }
  }

  Future<void> _loadZonasRiesgo() async {
    try {
      final zonas = await MapService.fetchZonasRiesgo();
      setState(() {
        _zonasRiesgo = zonas;
      });
    } catch (e) {
      debugPrint("Error cargando zonas de riesgo: $e");
    }
  }

  Color _getColorForNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return AppTheme.successGreen.withValues(alpha: 0.3);
      case 'medio':
        return AppTheme.alertAmber.withValues(alpha: 0.4);
      case 'alto':
        return Colors.redAccent.withValues(alpha: 0.5);
      case 'critico':
        return AppTheme.alertRed.withValues(alpha: 0.7);
      default:
        return Colors.grey.withValues(alpha: 0.5);
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
          content: const Text('No se pudo obtener ubicación exacta tan rapido.'),
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

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          try {
            if (widget.initialLocation == null || userForced) {
              _mapController.move(newPos, 16.0);
            } else {
              _mapController.move(widget.initialLocation!, 16.0);
            }
          } catch (e) {}
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
      _useFallbackLocation(userForced: userForced);
    }
  }

  void _iniciarRastreoUbicacion() {
    _positionStreamSubscription ??= Geolocator.getPositionStream(
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

  void _moveFakeGps(double dLat, double dLng) {
    if (_realUserPosition == null) return;
    setState(() {
      _realUserPosition = LatLng(
        _realUserPosition!.latitude + dLat,
        _realUserPosition!.longitude + dLng,
      );
    });
    _mapController.move(_realUserPosition!, 16.0);
    GeofenceService.checkManualLocation(
      _realUserPosition!.latitude,
      _realUserPosition!.longitude,
    );
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
            color: Colors.transparent,
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
                          onTap: (tapPosition, latLng) {
                            _handleMapTap(tapPosition, latLng);
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
                                // Puntos exactos (reportes ciudadanos) con animación y filtro de proximidad
                                if (_showReportesValidados)
                                  ..._puntosExactos.where((punto) {
                                    if (_realUserPosition == null) return true;
                                    final coords = punto['ubicacion']['coordinates'];
                                    final lat = (coords[1] as num).toDouble();
                                    final lng = (coords[0] as num).toDouble();
                                    final distance = Geolocator.distanceBetween(
                                      _realUserPosition!.latitude,
                                      _realUserPosition!.longitude,
                                      lat,
                                      lng,
                                    );
                                    // Mostrar reportes si están a 3km o menos
                                    return distance <= 3000;
                                  }).map((punto) {
                                  final coords = punto['ubicacion']['coordinates'];
                                  final estadoStr = (punto['estado'] ?? '').toString().toLowerCase();
                                  final isPending = estadoStr.contains('pendiente');
                                  
                                  final colorPunto = isPending ? AppTheme.alertAmber : (isDark ? Colors.white : Colors.black);
                                  final subTipo = punto['sub_tipo'] ?? 'Incidente';

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
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: Row(
                                              children: [
                                                Icon(
                                                  Icons.security,
                                                  color: colorPunto,
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Atención Inmediata',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? AppTheme.textPrimary : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Delito: $subTipo',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: isDark ? AppTheme.textPrimary : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  punto['direccion'] ?? 'Dirección no especificada.',
                                                  style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondary : Colors.grey[700]),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(),
                                                child: Text('Cerrar', style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.grey)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: colorPunto,
                                        size: 36.0,
                                        shadows: [
                                          Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
                                        ],
                                      )
                                      .animate(
                                        onPlay: (controller) => isPending ? controller.repeat(reverse: true) : null,
                                      )
                                      .scale(
                                        duration: 600.ms,
                                        curve: Curves.easeInOut,
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.2, 1.2),
                                      ),
                                    ),
                                  );
                                }),

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

                Positioned(
                  top: 50,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Showcase(
                        key: TutorialService.mapFilterBtnKey,
                        title: 'Filtros Operativos',
                        description: 'Filtra zonas y reportes ciudadanos.',
                        targetPadding: const EdgeInsets.all(8),
                        tooltipBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
                        child: FloatingActionButton(
                          heroTag: 'map_filter_btn_police',
                          mini: true,
                          elevation: 4,
                          onPressed: () {
                            setState(() {
                              _isFilterMenuOpen = !_isFilterMenuOpen;
                            });
                          },
                          backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
                          child: Icon(
                            Icons.layers,
                            color: _isFilterMenuOpen ? AppTheme.accentBlue : (isDark ? Colors.white : Colors.black87),
                            size: 20,
                          ),
                        ),
                      ),
                      if (_isFilterMenuOpen)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppTheme.borderTactical : Colors.grey.shade200, width: 0.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4)),
                            ],
                          ),
                          width: 220,
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
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .scaleXY(begin: 0.9, end: 1.0, alignment: Alignment.topLeft, duration: 200.ms),
                    ],
                  ),
                ),

                if (_realUserPosition != null)
                  Positioned(
                    bottom: 110,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppTheme.borderTactical : Colors.transparent),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.keyboard_arrow_up, color: isDark ? Colors.white : Colors.black87),
                            onPressed: () => _moveFakeGps(0.0005, 0),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_left, color: isDark ? Colors.white : Colors.black87),
                                onPressed: () => _moveFakeGps(0, -0.0005),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                              Icon(Icons.control_camera, color: AppTheme.accentBlue, size: 20),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_right, color: isDark ? Colors.white : Colors.black87),
                                onPressed: () => _moveFakeGps(0, 0.0005),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white : Colors.black87),
                            onPressed: () => _moveFakeGps(-0.0005, 0),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'map_location_police',
            mini: true,
            backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
            foregroundColor: isDark ? AppTheme.textPrimary : Colors.black87,
            elevation: 4,
            onPressed: () => _determinePosition(userForced: true),
            child: const Icon(Icons.my_location, size: 20),
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
}
