// Mapa operativo para el rol policía: muestra solo reportes ciudadanos dentro del radio
// de patrullaje (1 km). Efecto sonar/radar animado indica zona activa. HUD en tiempo real
// muestra estado y reportes pendientes. Auto-refresca cada 30 s.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as dart_ui;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/map_service.dart';
import '../../../../core/services/police_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_button.dart';

class PoliceMapView extends StatefulWidget {
  final String userId;
  final LatLng? initialLocation;
  const PoliceMapView({super.key, required this.userId, this.initialLocation});

  @override
  State<PoliceMapView> createState() => _PoliceMapViewState();
}

class _PoliceMapViewState extends State<PoliceMapView>
    with SingleTickerProviderStateMixin {
  LatLng? _currentPosition;
  LatLng? _realUserPosition;
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _refreshTimer;

  // Controlador del sonar — tres ondas desfasadas 120° del ciclo (0, 1/3, 2/3).
  late AnimationController _sonarController;

  List<dynamic> _puntosExactos = [];

  static const double _patrolRadiusMeters = 1000.0;

  int get _pendingInZone {
    final base = _realUserPosition;
    return _puntosExactos.where((punto) {
      final estado = (punto['estado'] ?? '').toString().toLowerCase();
      if (estado != 'pendiente') return false;
      if (base == null) return true;
      final coords = punto['ubicacion']['coordinates'];
      final lat = (coords[1] as num).toDouble();
      final lng = (coords[0] as num).toDouble();
      return Geolocator.distanceBetween(
            base.latitude, base.longitude, lat, lng) <=
          _patrolRadiusMeters;
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    if (widget.initialLocation != null) {
      _currentLocationJump(widget.initialLocation!);
    } else {
      _determinePosition();
    }
    _loadPuntosExactos();

    ReportService.reportsUpdatedNotifier.addListener(_reportsUpdatedListener);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadPuntosExactos(),
    );
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
    setState(() => _currentPosition = target);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        try {
          _mapController.move(target, 17.0);
        } catch (_) {}
      }
    });
  }

  void _reportsUpdatedListener() {
    if (mounted) _loadPuntosExactos();
  }

  Future<void> _loadPuntosExactos() async {
    try {
      final puntos = await MapService.fetchPuntosPolicia();
      if (mounted) setState(() => _puntosExactos = puntos);
    } catch (e) {
      debugPrint("Error cargando puntos exactos: $e");
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
          if (!kIsWeb) position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.best),
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
        } else if (userForced && _realUserPosition != null) {
          try {
            _mapController.move(_realUserPosition!, 16.0);
          } catch (_) {}
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

  @override
  void dispose() {
    _sonarController.dispose();
    ReportService.reportsUpdatedNotifier.removeListener(_reportsUpdatedListener);
    _refreshTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // Construye una onda sonar basada en `phase` ∈ [0,1].
  // Escala easeOut de 0→1 y opacidad 0.65→0, creando el efecto de propagación.
  Widget _sonarRingWidget(double phase) {
    final scale = Curves.easeOut.transform(phase);
    final opacity = ((1.0 - phase) * 0.65).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.alertAmber.withValues(alpha: opacity),
            width: 1.8,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = _pendingInZone;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa base ──
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.sgeo_pp',
                    ),
                    // Borde sutil del radio de patrullaje (referencia geográfica real 1 km).
                    if (_realUserPosition != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _realUserPosition!,
                            radius: _patrolRadiusMeters,
                            useRadiusInMeter: true,
                            color: AppTheme.alertAmber.withValues(alpha: 0.03),
                            borderColor: AppTheme.alertAmber
                                .withValues(alpha: isDark ? 0.25 : 0.35),
                            borderStrokeWidth: 1.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Sonar radar animado centrado en la posición del agente.
                        // AnimatedBuilder actualiza solo este sub-árbol a 60 fps.
                        if (_realUserPosition != null)
                          Marker(
                            key: const ValueKey('police_sonar'),
                            point: _realUserPosition!,
                            width: 220,
                            height: 220,
                            child: AnimatedBuilder(
                              animation: _sonarController,
                              builder: (ctx, _) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  _sonarRingWidget(_sonarController.value),
                                  _sonarRingWidget(
                                      (_sonarController.value + 0.333) % 1.0),
                                  _sonarRingWidget(
                                      (_sonarController.value + 0.667) % 1.0),
                                ],
                              ),
                            ),
                          ),

                        // Reportes ciudadanos dentro del radio de patrullaje
                        ..._puntosExactos
                            .where((punto) {
                              final estado = (punto['estado'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              if (estado == 'rechazado') return false;

                              final base = _realUserPosition;
                              if (base == null) return true;

                              final coords =
                                  punto['ubicacion']['coordinates'];
                              final lat = (coords[1] as num).toDouble();
                              final lng = (coords[0] as num).toDouble();
                              return Geolocator.distanceBetween(
                                    base.latitude,
                                    base.longitude,
                                    lat,
                                    lng,
                                  ) <=
                                  _patrolRadiusMeters;
                            })
                            .map((punto) {
                              final coords =
                                  punto['ubicacion']['coordinates'];
                              final estadoStr = (punto['estado'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final isPending =
                                  estadoStr.contains('pendiente');
                              final colorPunto = isPending
                                  ? AppTheme.alertAmber
                                  : AppTheme.successGreen;
                              final subTipo =
                                  punto['subtipo_hecho'] ?? 'Incidente';

                              return Marker(
                                key: ValueKey('rep_${punto['_id']}'),
                                point: LatLng(
                                  (coords[1] as num).toDouble(),
                                  (coords[0] as num).toDouble(),
                                ),
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showIncidentDetailsBottomSheet(
                                          context, {
                                    'title': 'Atención Inmediata',
                                    'subTipo': subTipo,
                                    'modalidad': punto['direccion_hecho'] ??
                                        'Dirección no especificada.',
                                    'fechaHecho':
                                        punto['fecha_hora_hecho'] ?? 'Reciente',
                                    'gravedad': punto['gravedad'],
                                    'origen': 'Reporte en curso',
                                    'isCitizen': true,
                                    'estadoStr': estadoStr,
                                    'estadoColor': colorPunto,
                                    'color': colorPunto,
                                    'icon': Icons.security,
                                    'reporteId': punto['_id']?.toString(),
                                    'isPending': isPending,
                                  }),
                                  child: _buildAnimatedMarker(
                                      colorPunto, Icons.security),
                                ),
                              );
                            }),

                        // Punto de posición del agente (encima del sonar)
                        if (_realUserPosition != null)
                          Marker(
                            key: const ValueKey('police_dot'),
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
                                    color: AppTheme.accentBlue
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accentBlue
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accentBlue,
                                    border: Border.all(
                                        color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.3),
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

          // ── HUD: estado de patrullaje + contador de pendientes ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 72,
            child: Row(
              children: [
                // Chip "Patrullando"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.bgSurface.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppTheme.borderSubtle, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.alertAmber,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(
                              onPlay: (c) => c.repeat(reverse: true))
                          .fade(
                              begin: 1.0,
                              end: 0.2,
                              duration: 900.ms,
                              curve: Curves.easeInOut),
                      const SizedBox(width: 7),
                      Text(
                        'Patrullando · 1 km',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.textPrimary
                              : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chip de pendientes (visible solo cuando hay reportes sin atender)
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.alertAmber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              AppTheme.alertAmber.withValues(alpha: 0.5),
                          width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active,
                            color: AppTheme.alertAmber, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          '$pending pendiente${pending > 1 ? "s" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.alertAmber,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 300.ms,
                          curve: Curves.elasticOut)
                      .fade(duration: 200.ms),
              ],
            ),
          ),

          // ── Leyenda de colores (esquina inferior izquierda) ──
          Positioned(
            bottom: 90,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.bgSurface.withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendRow(AppTheme.alertAmber, 'Pendiente', isDark),
                  const SizedBox(height: 5),
                  _legendRow(AppTheme.successGreen, 'Confirmado', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_location_police',
        mini: false,
        backgroundColor: isDark
            ? AppTheme.bgSurface.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        foregroundColor:
            isDark ? AppTheme.accentBlue : Colors.black87,
        elevation: 4,
        onPressed: () => _determinePosition(userForced: true),
        child: const Icon(Icons.my_location, size: 24),
      ),
    );
  }

  Widget _legendRow(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), width: 1),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.textSecondary
                : Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  void _showIncidentDetailsBottomSheet(
      BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = data['color'] as Color? ??
        (data['isCitizen'] == true
            ? AppTheme.accentBlue
            : AppTheme.alertRed);
    final icon = data['icon'] as IconData? ??
        (data['isCitizen'] == true
            ? Icons.person_pin_circle
            : Icons.local_police);

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
            color: isDark
                ? AppTheme.bgSurface.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
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
              _buildDetailRow(
                  Icons.warning_rounded, 'Tipo', data['subTipo'], isDark),
              if (data['modalidad'] != null)
                _buildDetailRow(Icons.info_outline_rounded, 'Modalidad',
                    data['modalidad'], isDark),
              _buildDetailRow(Icons.access_time_rounded, 'Fecha',
                  data['fechaHecho'], isDark),
              if (data['gravedad'] != null)
                _buildDetailRow(
                    Icons.priority_high_rounded,
                    'Gravedad',
                    data['gravedad'].toString().toUpperCase(),
                    isDark),
              _buildDetailRow(
                  Icons.source_rounded, 'Origen', data['origen'], isDark,
                  valueColor: color),
              if (data['estadoStr'] != null)
                _buildDetailRow(
                    Icons.check_circle_outline_rounded,
                    'Estado',
                    data['estadoStr'].toString().toUpperCase(),
                    isDark,
                    valueColor: data['estadoColor']),
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
                          _confirmarORechazarDesdeMapa(
                              data['reporteId'].toString(),
                              confirmar: false);
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
                          _confirmarORechazarDesdeMapa(
                              data['reporteId'].toString(),
                              confirmar: true);
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
                      backgroundColor:
                          isDark ? AppTheme.bgDeep : Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'CERRAR',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondary
                            : Colors.black54,
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

  Future<void> _confirmarORechazarDesdeMapa(String reporteId,
      {required bool confirmar}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        confirmar ? AppTheme.successGreen : AppTheme.alertRed;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
        title:
            Text(confirmar ? 'Confirmar incidente' : 'Rechazar incidente'),
        content: Text(
          confirmar
              ? '¿Confirmas este reporte? Será visible para todos los ciudadanos.'
              : '¿Estás seguro de rechazar este reporte?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white),
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
        SnackBar(
            content: Text(resultado['message']),
            backgroundColor: accentColor),
      );
      PoliceService.pendingReportsNotifier.value =
          (PoliceService.pendingReportsNotifier.value - 1)
              .clamp(0, 999999);
      _loadPuntosExactos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              resultado['message'] ?? 'No se pudo procesar el reporte.'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color:
                  isDark ? AppTheme.textMuted : Colors.grey.shade500),
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
                    color: isDark
                        ? AppTheme.textMuted
                        : Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ??
                        (isDark ? Colors.white : Colors.black87),
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
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.5, 1.5),
                duration: 1500.ms)
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
