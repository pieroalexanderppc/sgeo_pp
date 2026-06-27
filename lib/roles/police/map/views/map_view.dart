// Se agrega circulo de 3km, joystick de simulacion (solo rol policia) y Confirmar/Rechazar
// desde el bottom sheet del mapa. Se corrigen campos que no coincidian con el backend
// (sub_tipo/direccion -> subtipo_hecho/direccion_hecho). No se modifica el widget FlutterMap.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as dart_ui;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/services/police_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_button.dart';

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
  List<dynamic> _zonasRiesgo = [];
  List<dynamic> _puntosExactos = [];
  List<dynamic> _puntosHistorial = [];

  bool _showZonasRiesgo = true;
  bool _showReportesValidados = true;
  bool _isFilterMenuOpen = false;
  int? _filterYear;
  int? _filterMonth;
  double _currentZoom = 15.0;

  // ── Joystick de simulacion (solo rol policia) ──
  // _simulatedPosition reemplaza al GPS real en filtros/distancias mientras este activo,
  // pero nunca se usa para mover la camara ni el initialCenter de FlutterMap.
  bool _isTestMode = false;
  LatLng? _simulatedPosition;

  LatLng? get _effectivePosition => (_isTestMode && _simulatedPosition != null) ? _simulatedPosition : _realUserPosition;

  void _toggleTestMode() {
    setState(() {
      _isTestMode = !_isTestMode;
      _simulatedPosition = _isTestMode ? (_realUserPosition ?? _currentPosition) : null;
    });
  }

  void _moveSimulatedPosition(double dLat, double dLng) {
    if (_simulatedPosition == null) return;
    setState(() {
      _simulatedPosition = LatLng(_simulatedPosition!.latitude + dLat, _simulatedPosition!.longitude + dLng);
    });
  }

  List<int> get _availableYears {
    final Set<int> years = {};
    for (var p in _puntosHistorial) {
      final dateStr = p['fecha_hora_hecho'] ?? p['fecha_hecho'];
      if (dateStr != null) {
        try {
          years.add(DateTime.parse(dateStr).year);
        } catch (_) {}
      }
    }
    for (var p in _puntosExactos) {
      final dateStr = p['fecha_hora_hecho'] ?? p['fecha'];
      if (dateStr != null) {
        try {
          years.add(DateTime.parse(dateStr).year);
        } catch (_) {}
      }
    }
    if (years.isEmpty) years.add(DateTime.now().year);
    final sorted = years.toList()..sort();
    return sorted.reversed.toList();
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

    TutorialService.triggerTutorialNotifier.addListener(_tutorialListener);
    ReportService.reportsUpdatedNotifier.addListener(_reportsUpdatedListener);
  }

  Future<void> _loadPuntosHistorial() async {
    try {
      final puntos = await MapService.fetchPuntosHistorial();
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
          ShowCaseWidget.of(
            showcaseContext!,
          ).startShowCase([TutorialService.mapFilterBtnKey]);
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
      if (!mounted) return;
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
      
    });

    if (userForced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo obtener ubicación exacta tan rapido.',
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
          
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          try {
            if (widget.initialLocation == null || userForced) {
              _mapController.move(newPos, 16.0);
            } else {
              _mapController.move(widget.initialLocation!, 16.0);
            }
          } catch (e) {
            debugPrint("Error moviendo la cámara del mapa (Polícia): $e");
          }
        });
      } else if (mounted) {
        if (_realUserPosition == null) {
          _useFallbackLocation(userForced: userForced);
        } else {
          
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
            color: Colors.transparent,
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
                              // para evitar agotar batería llamando a setState en cada frame al arrastrar el mapa.
                              bool wasThresh = _currentZoom > 15.5;
                              bool isThresh = position.zoom > 15.5;
                              if (wasThresh != isThresh) {
                                setState(() {
                                  _currentZoom = position.zoom;
                                });
                              } else {
                                _currentZoom =
                                    position.zoom; // Actualizar valor silente
                              }
                            }
                          },
                          onTap: (tapPosition, latLng) {
                            _handleMapTap(tapPosition, latLng);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.example.sgeo_pp',
                          ),
                          // Perimetro visual de 3km alrededor de la posicion del policia
                          // (usa _effectivePosition: real o simulada por el joystick, nunca la camara)
                          if (_effectivePosition != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _effectivePosition!,
                                  radius: 3000,
                                  useRadiusInMeter: true,
                                  color: AppTheme.accentBlue.withValues(alpha: 0.04),
                                  borderColor: AppTheme.accentBlue.withValues(alpha: isDark ? 0.35 : 0.5),
                                  borderStrokeWidth: 1.5,
                                ),
                              ],
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
                                        final fechaRaw =
                                            punto['fecha_hecho'] as String?;
                                        if (fechaRaw != null) {
                                          try {
                                            final dt = DateTime.parse(fechaRaw);
                                            if (_filterYear != null &&
                                                dt.year != _filterYear) {
                                              return false;
                                            }
                                            if (_filterMonth != null &&
                                                dt.month != _filterMonth) {
                                              return false;
                                            }
                                          } catch (_) {}
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
                                      final fechaHecho =
                                          punto['fecha_hora_hecho'] ??
                                          punto['fecha_hecho'] ??
                                          'Fecha no disponible';
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
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: GestureDetector(
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
                              // Puntos exactos (reportes ciudadanos) con animación y filtro de proximidad (3km)
                              if (_showReportesValidados)
                                ..._puntosExactos
                                    .where((punto) {
                                      final estado = (punto['estado'] ?? '').toString().toLowerCase();
                                      // Los rechazados no se muestran como marcador operativo (solo en Historial)
                                      if (estado == 'rechazado') return false;

                                      if (_filterYear != null ||
                                          _filterMonth != null) {
                                        final fechaRaw =
                                            punto['fecha_hora_hecho']
                                                as String?;
                                        if (fechaRaw != null) {
                                          try {
                                            final dt = DateTime.parse(fechaRaw);
                                            if (_filterYear != null &&
                                                dt.year != _filterYear) {
                                              return false;
                                            }
                                            if (_filterMonth != null &&
                                                dt.month != _filterMonth) {
                                              return false;
                                            }
                                          } catch (_) {}
                                        }
                                      }
                                      final base = _effectivePosition;
                                      if (base == null) {
                                        return true;
                                      }
                                      final coords =
                                          punto['ubicacion']['coordinates'];
                                      final lat = (coords[1] as num).toDouble();
                                      final lng = (coords[0] as num).toDouble();
                                      final distance =
                                          Geolocator.distanceBetween(
                                            base.latitude,
                                            base.longitude,
                                            lat,
                                            lng,
                                          );
                                      // Mostrar reportes si están a 3km o menos
                                      return distance <= 3000;
                                    })
                                    .map((punto) {
                                      final coords =
                                          punto['ubicacion']['coordinates'];
                                      final estadoStr = (punto['estado'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final isPending = estadoStr.contains(
                                        'pendiente',
                                      );

                                      final colorPunto = isPending
                                          ? AppTheme.alertAmber
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black);
                                      final subTipo =
                                          punto['subtipo_hecho'] ?? 'Incidente';

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
                                              'title': 'Atención Inmediata',
                                              'subTipo': subTipo,
                                              'modalidad': punto['direccion_hecho'] ?? 'Dirección no especificada.',
                                              'fechaHecho': punto['fecha_hora_hecho'] ?? 'Reciente',
                                              'gravedad': punto['gravedad'],
                                              'origen': 'Reporte en curso',
                                              'isCitizen': true,
                                              'estadoStr': estadoStr,
                                              'estadoColor': colorPunto,
                                              'color': colorPunto,
                                              'icon': Icons.security,
                                              'reporteId': punto['_id']?.toString(),
                                              'isPending': isPending,
                                            });
                                          },
                                          child: _buildAnimatedMarker(
                                            colorPunto,
                                            Icons.security,
                                          ),
                                        ),
                                      );
                                    }),

                              if (_effectivePosition != null)
                                Marker(
                                  point: _effectivePosition!,
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
                                          color: (_isTestMode ? AppTheme.alertAmber : AppTheme.accentBlue).withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (_isTestMode ? AppTheme.alertAmber : AppTheme.accentBlue).withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isTestMode ? AppTheme.alertAmber : AppTheme.accentBlue,
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
                        tooltipBackgroundColor: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
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
                          backgroundColor: isDark
                              ? AppTheme.bgSurface
                              : Colors.white,
                          child: Icon(
                            Icons.layers,
                            color: _isFilterMenuOpen
                                ? AppTheme.accentBlue
                                : (isDark ? Colors.white : Colors.black87),
                            size: 20,
                          ),
                        ),
                      ),
                      if (_isFilterMenuOpen)
                        Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.bgSurface.withValues(alpha: 0.95)
                                    : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.borderTactical
                                      : Colors.grey.shade200,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              width: 220,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterSwitch(
                                    title: 'Zonas de Riesgo',
                                    value: _showZonasRiesgo,
                                    onChanged: (val) =>
                                        setState(() => _showZonasRiesgo = val),
                                    isDark: isDark,
                                  ),
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? AppTheme.borderSubtle
                                        : Colors.grey.shade200,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                  _buildFilterSwitch(
                                    title: 'Reportes Ciudadanos',
                                    value: _showReportesValidados,
                                    onChanged: (val) => setState(
                                      () => _showReportesValidados = val,
                                    ),
                                    isDark: isDark,
                                  ),
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? AppTheme.borderSubtle
                                        : Colors.grey.shade200,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                  _buildDateFilters(isDark),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .scaleXY(
                              begin: 0.9,
                              end: 1.0,
                              alignment: Alignment.topLeft,
                              duration: 200.ms,
                            ),
                    ],
                  ),
                ),

                // ====== JOYSTICK DE SIMULACION (rol policia) ======
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'joystick_toggle_police',
                    mini: true,
                    elevation: 4,
                    backgroundColor: _isTestMode
                        ? AppTheme.alertAmber
                        : (isDark ? AppTheme.bgSurface : Colors.white),
                    onPressed: _toggleTestMode,
                    tooltip: _isTestMode ? 'Desactivar simulación de posición' : 'Simular posición (pruebas)',
                    child: Icon(
                      Icons.sports_esports_rounded,
                      color: _isTestMode ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                      size: 20,
                    ),
                  ),
                ),
                if (_isTestMode)
                  Positioned(
                    bottom: 160,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.bgElevated.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: AppTheme.alertAmber.withValues(alpha: 0.4)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up, size: 26),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppTheme.alertAmber,
                            onPressed: () => _moveSimulatedPosition(0.0005, 0),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_left, size: 26),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: AppTheme.alertAmber,
                                onPressed: () => _moveSimulatedPosition(0, -0.0005),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.adjust_rounded, size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right, size: 26),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: AppTheme.alertAmber,
                                onPressed: () => _moveSimulatedPosition(0, 0.0005),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down, size: 26),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppTheme.alertAmber,
                            onPressed: () => _moveSimulatedPosition(-0.0005, 0),
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

  Widget _buildFilterSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
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
              if (data['gravedad'] != null) _buildDetailRow(Icons.priority_high_rounded, 'Gravedad', data['gravedad'].toString().toUpperCase(), isDark),
              _buildDetailRow(Icons.source_rounded, 'Origen', data['origen'], isDark, valueColor: color),
              if (data['estadoStr'] != null)
                _buildDetailRow(Icons.check_circle_outline_rounded, 'Estado', data['estadoStr'].toString().toUpperCase(), isDark, valueColor: data['estadoColor']),
              const SizedBox(height: 24),
              if (data['isPending'] == true && data['reporteId'] != null)
                Row(
                  children: [
                    Expanded(
                      child: SafetyButton.outline(
                        label: 'Rechazar',
                        icon: Icons.close_rounded,
                        isDanger: true,
                        foregroundColor: AppTheme.alertRed,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmarORechazarDesdeMapa(data['reporteId'].toString(), confirmar: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SafetyButton(
                        label: 'Confirmar',
                        icon: Icons.check_rounded,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmarORechazarDesdeMapa(data['reporteId'].toString(), confirmar: true);
                        },
                      ),
                    ),
                  ],
                )
              else
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

  Future<void> _confirmarORechazarDesdeMapa(String reporteId, {required bool confirmar}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = confirmar ? AppTheme.successGreen : AppTheme.alertRed;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
        title: Text(confirmar ? 'Confirmar incidente' : 'Rechazar incidente'),
        content: Text(
          confirmar
              ? '¿Confirmas este reporte? Será visible para todos los ciudadanos.'
              : '¿Estás seguro de rechazar este reporte?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
            child: Text(confirmar ? 'Confirmar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final resultado = confirmar
        ? await PoliceService.confirmarReporte(reporteId)
        : await PoliceService.rechazarReporte(reporteId);

    if (!mounted) return;

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message']), backgroundColor: accentColor),
      );
      PoliceService.pendingReportsNotifier.value = (PoliceService.pendingReportsNotifier.value - 1).clamp(0, 999999);
      _loadPuntosExactos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['message'] ?? 'No se pudo procesar el reporte.'), backgroundColor: AppTheme.alertRed),
      );
    }
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
