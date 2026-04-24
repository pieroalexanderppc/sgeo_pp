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
import '../../../../core/models/report_model.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/tutorial_service.dart';
import 'widgets/report_dialog.dart';

class MapView extends StatefulWidget {
  final String userId;
  final LatLng? initialLocation;
  const MapView({super.key, required this.userId, this.initialLocation});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng? _currentPosition; // La posici?n inicial del mapa o donde enfoca
  LatLng? _realUserPosition; // La ubicaci?n EXACTA por GPS del usuario
  final MapController _mapController = MapController();
  final PanelController _panelController =
      PanelController(); // Panel deslizante
  dynamic _selectedZona; // Info de la zona actual tocada

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  List<dynamic> _zonasRiesgo = [];
  List<dynamic> _puntosExactos = []; // <--- NUEVO: para reportes ciudadanos
  List<ReportModel> _misReportesPendientes = [];

  // Opciones de visualizacion (Filtros de mapa)
  bool _showZonasRiesgo = true;
  bool _showReportesValidados = true;
  bool _showMisReportes = true;
  bool _isFilterMenuOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocationJump(
        widget.initialLocation!,
      ); // Como ya tenemos ubicaciÃ³n de destino
    } else {
      _determinePosition();
    }
    _loadZonasRiesgo();
    _loadPuntosExactos(); // <--- NUEVO
    _loadMisReportes();

    TutorialService.triggerTutorialNotifier.addListener(_tutorialListener);
    ReportService.reportsUpdatedNotifier.addListener(_reportsUpdatedListener);
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
      if (mounted) {
        setState(() {
          _puntosExactos = puntos;
        });
      }
    } catch (e) {
      debugPrint("? Error cargando puntos exactos: $e");
    }
  }

  Future<void> _loadZonasRiesgo() async {
    try {
      final zonas = await MapService.fetchZonasRiesgo();
      setState(() {
        _zonasRiesgo = zonas;
      });
      debugPrint("? Zonas de riesgo cargadas: ${_zonasRiesgo.length}");
    } catch (e) {
      debugPrint("? Error cargando zonas de riesgo: $e");
    }
  }

  Color _getColorForNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return Colors.green.withAlpha(76); // 0.3 opacity ~ 76
      case 'medio':
        return Colors.orange.withAlpha(102); // 0.4 opacity ~ 102
      case 'alto':
        return Colors.redAccent.withAlpha(127); // 0.5 opacity ~ 127
      case 'critico':
        return Colors.red.withAlpha(178); // 0.7 opacity ~ 178
      default:
        return Colors.grey.withAlpha(127); // 0.5 opacity ~ 127
    }
  }

  /// Define una ubicacion por defecto (ej. Centro de Tacna) si falla el GPS
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
        const SnackBar(
          content: Text(
            '?? No se pudo obtener ubicacion exacta tan rapido. Esperando actualizacion...',
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.orange, // Cambiado de error a aviso temporal
        ),
      );
    }
  }

  /// Solicita permisos y obtiene la ubicacion actual del usuario
  Future<void> _determinePosition({bool userForced = false}) async {
    if (userForced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buscando ubicaciÃ³n actual, por favor espera...'),
          duration: Duration(seconds: 4),
        ),
      );
      setState(() => _isLoading = true);
    }
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Verifica si el servicio de ubicacion esta habilitado.
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

      // Iniciamos el stream de rastreo de inmediato si tenemos permisos
      _iniciarRastreoUbicacion();

      Position? position;

      // 1. Obtener la ubicaciÃ³n cacheadÃ­sima en celulares (Web crashea con esto)
      if (!userForced) {
        try {
          if (!kIsWeb) {
            position = await Geolocator.getLastKnownPosition();
          }
        } catch (_) {}
      }

      // 2. Si forzamos, o no hay cachÃ©, pedir la ubicaciÃ³n con ALTA precisiÃ³n y SIN ahogarlo
      if (position == null) {
        try {
          position =
              await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.best,
                ), // Mejor precisiÃ³n satelital
              ).timeout(
                const Duration(seconds: 15),
              ); // Un margen decente de 15 segundos para el GPS
        } catch (e) {
          debugPrint('Aviso GPS: $e');
        }
      }

      // Si nos dio posicion puntual
      if (mounted && position != null) {
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _realUserPosition = newPos;
          if (widget.initialLocation == null || userForced) {
            _currentPosition = newPos;
          }
          _isLoading = false;
        });

        // Con una ligera espera para asegurar que el map_controller haya cargado en UI
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          try {
            if (widget.initialLocation == null || userForced) {
              _mapController.move(newPos, 16.0);
            } else {
              _mapController.move(
                widget.initialLocation!,
                16.0,
              ); // Mueve a lugar del incidente
            }
          } catch (e) {
            debugPrint('Error map: $e');
          }
        });
      } else if (mounted) {
        // Si el stream de rastreo todavia no obtuvo nada
        if (_realUserPosition == null) {
          _useFallbackLocation(userForced: userForced);
        } else {
          // Ya tiene posici?n por el stream de rastreo, solo quitamos loading y centramos si forz?
          setState(() => _isLoading = false);
          if (userForced && _realUserPosition != null) {
            try {
              _mapController.move(_realUserPosition!, 16.0);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Error cr?tico geolocator: $e');
      _useFallbackLocation(userForced: userForced);
    }
  }

  // Ahora recibe la coordenada como parametro
  void _abrirFormularioReporte(LatLng coordenada) async {
    // Abre el dialogo
    final reportado = await showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        latitud: coordenada.latitude,
        longitud: coordenada.longitude,
        userId: widget.userId, // <- PASAR EL USUARIO
      ),
    );

    // Si el reporte fue exitoso, refrescamos los puntos exactos para que aparezca
    if (reportado == true) {
      _loadPuntosExactos();
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
              // Si el mapa estaba en ubicacion por defecto, lo enfocamos de inmediato
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

    // Buscar si el tap ocurriÃ³ dentro de alguna zona de calor
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

  // --- HACK TEMPORAL DE GPS (Solo pruebas manuales) ---
  void _moveFakeGps(double dLat, double dLng) {
    if (_realUserPosition == null) return;
    setState(() {
      _realUserPosition = LatLng(
        _realUserPosition!.latitude + dLat,
        _realUserPosition!.longitude + dLng,
      );
    });
    _mapController.move(_realUserPosition!, 16.0); // Mover camara tambien
    GeofenceService.checkManualLocation(
      _realUserPosition!.latitude,
      _realUserPosition!.longitude,
    );
  }
  // ----------------------------------------------------

  Widget _buildPanelContent() {
    if (_selectedZona == null) return const SizedBox.shrink();

    final zona = _selectedZona;
    final nivel = zona['nivel_riesgo'].toString().toUpperCase();
    Color colorNivel = Colors.grey;
    if (nivel == 'CRITICO' || nivel == 'ALTO') colorNivel = Colors.red;
    if (nivel == 'MEDIO') colorNivel = Colors.orange;
    if (nivel == 'BAJO') colorNivel = Colors.green;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.whatshot, color: colorNivel, size: 28)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                  ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zona de Riesgo $nivel',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    if (zona['distrito'] != null)
                      Text(
                        zona['distrito'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.security, color: Colors.white),
            ),
            title: Text(
              'Incidentes registrados: ${zona['total_incidentes'] ?? "Varios"}',
            ),
            subtitle: const Text('Basado en denuncias y reportes policiales.'),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          if (zona['delito_predominante'] != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.warning, color: Colors.white),
              ),
              title: Text('Delito frecuente: ${zona['delito_predominante']}'),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.trending_up, color: Colors.white),
            ),
            title: Text('Tendencia: ${zona['tendencia'] ?? "Desconocida"}'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
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
    return ShowCaseWidget(
      builder: (ctx) {
        showcaseContext = ctx;

        return Scaffold(
          body: SlidingUpPanel(
            controller: _panelController,
            minHeight: 0,
            maxHeight: 380,
            backdropEnabled: true,
            backdropOpacity: 0.3,
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(blurRadius: 10, color: Colors.black.withAlpha(25)),
            ],
            panel: _buildPanelContent(),
            body: Stack(
              children: [
                _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                                  Icons.location_on,
                                  size: 60,
                                  color: Colors.blue,
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .scale(
                                  duration: 800.ms,
                                  curve: Curves.easeInOut,
                                )
                                .tint(
                                  color: Colors.lightBlueAccent,
                                  duration: 800.ms,
                                ),
                            const SizedBox(height: 16),
                            const Text(
                              "Ubicando seÃ±al GPS...",
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
                          // Al tocar un punto (tap normal), detectamos si es una zona de riesgo para mostrar info
                          onTap: (tapPosition, latLng) {
                            _handleMapTap(tapPosition, latLng);
                          },
                          // Permitir a la persona presionar largo en una calle especifica para reportar
                          onLongPress: (tapPosition, latLng) {
                            _abrirFormularioReporte(latLng);
                          },
                        ),
                        children: [
                          TileLayer(
                            // Capa de mapa base CARTO voyager (Minimalista, moderna, basada en OpenStreetMap)
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
                                  point: LatLng(
                                    lat,
                                    lng,
                                  ), // GeoJSON es [lon, lat], pero LatLng es (lat, lon)
                                  color: _getColorForNivel(
                                    zona['nivel_riesgo'],
                                  ),
                                  borderStrokeWidth: 2,
                                  borderColor: _getColorForNivel(
                                    zona['nivel_riesgo'],
                                  ).withAlpha(204), // 0.8 opacity ~ 204
                                  useRadiusInMeter: true,
                                  radius: radius, // Radio de calor
                                );
                              }).toList(),
                            ),
                          MarkerLayer(
                            markers: [
                              // 1. Puntos exactos reportados
                              if (_showReportesValidados)
                                ..._puntosExactos.map((punto) {
                                  final coords =
                                      punto['ubicacion']['coordinates'];
                                  final estadoStr = (punto['estado'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final colorPunto =
                                      estadoStr.contains('pendiente')
                                      ? Colors.deepPurple
                                      : Colors.black;
                                  final subTipo =
                                      punto['sub_tipo'] ?? 'Incidente';

                                  return Marker(
                                    point: LatLng(
                                      (coords[1] as num).toDouble(),
                                      (coords[0] as num).toDouble(),
                                    ),
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment
                                        .center, // Centrado para que la 'X' de la alerta quede exactamente en el punto
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Row(
                                              children: [
                                                Icon(
                                                  Icons.report_problem_rounded,
                                                  color: colorPunto,
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 10),
                                                const Expanded(
                                                  child: Text(
                                                    'Alerta Ciudadana',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Delito: $subTipo',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  punto['descripcion'] ??
                                                      'Reporte validado y confirmado en esta zona.',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  'Estado: ${punto['estado'] ?? 'Desconocido'}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors
                                                        .blueGrey
                                                        .shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                                child: const Text('Cerrar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: colorPunto,
                                        size: 30.0,
                                      ),
                                    ),
                                  );
                                }),

                              // 1.5. Propios reportes pendientes del usuario (Morado real)
                              if (_showMisReportes)
                                ..._misReportesPendientes.map((reporte) {
                                  return Marker(
                                    point: LatLng(
                                      reporte.latitud!,
                                      reporte.longitud!,
                                    ),
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurpleAccent
                                                .withAlpha(150),
                                            blurRadius: 4,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              // 2. Posici?n actual REAL del usuario (solo si existe)
                              if (_realUserPosition != null)
                                Marker(
                                  point: _realUserPosition!,
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Sombra / Pulso (Halo)
                                      Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue.withAlpha(50),
                                        ),
                                      ),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue.withAlpha(100),
                                        ),
                                      ),
                                      // Punto central blanco con anillo azul
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(80),
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
                  top: 40,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Showcase(
                        key: TutorialService.mapFilterBtnKey,
                        title: 'Filtros del Mapa',
                        description:
                            'Puedes configurar cuÃ¡les zonas de riesgo o reportes ver en el mapa.',
                        targetPadding: const EdgeInsets.all(8),
                        tooltipBackgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        textColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        child: FloatingActionButton(
                          heroTag: 'map_filter_btn',
                          onPressed: () {
                            setState(() {
                              _isFilterMenuOpen = !_isFilterMenuOpen;
                            });
                          },
                          backgroundColor: _isFilterMenuOpen
                              ? Colors.blue.shade100
                              : Colors.blue.shade200,
                          child: Icon(
                            Icons.layers,
                            color: _isFilterMenuOpen
                                ? Colors.indigo
                                : Colors.indigo.shade900,
                          ),
                        ),
                      ),
                      // Menu desplegable del Filtro (Estilo Moderno & Switch)
                      if (_isFilterMenuOpen)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1A1D24,
                            ), // Fondo oscuro sutil
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          width: 250,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: const Text(
                                  'Zonas de Riesgo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                value: _showZonasRiesgo,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                activeThumbColor: Colors.deepPurpleAccent,
                                activeTrackColor: Colors.deepPurple.shade900,
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade800,
                                onChanged: (val) =>
                                    setState(() => _showZonasRiesgo = val),
                              ),
                              Divider(
                                height: 8,
                                color: Colors.grey.shade800,
                                indent: 16,
                                endIndent: 16,
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Reportes Ciudadanos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                value: _showReportesValidados,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                activeThumbColor: Colors.deepPurpleAccent,
                                activeTrackColor: Colors.deepPurple.shade900,
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade800,
                                onChanged: (val) => setState(
                                  () => _showReportesValidados = val,
                                ),
                              ),
                              Divider(
                                height: 8,
                                color: Colors.grey.shade800,
                                indent: 16,
                                endIndent: 16,
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Mis Reportes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                value: _showMisReportes,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                activeThumbColor: Colors.deepPurpleAccent,
                                activeTrackColor: Colors.deepPurple.shade900,
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade800,
                                onChanged: (val) =>
                                    setState(() => _showMisReportes = val),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ====== JOYSTICK FALSO TEMPORAL ======
                if (_realUserPosition != null)
                  Positioned(
                    bottom:
                        110, // Subimos el joystick para que no moleste la barra de abajo
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        shape: BoxShape
                            .circle, // Hacemos que sea un cÃ­rculo perfecto
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(
                        12,
                      ), // MÃ¡s espacio para que mantenga la forma circular
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: () => _moveFakeGps(0.0005, 0),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => _moveFakeGps(0, -0.0005),
                              ),
                              const Icon(
                                Icons.control_camera,
                                color: Colors.blue,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () => _moveFakeGps(0, 0.0005),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: () => _moveFakeGps(-0.0005, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                // =====================================

                // -- BOT?N PARA REPORTAR (Esquina Superior Derecha) --
                Positioned(
                  top: 40,
                  right: 20,
                  child: Showcase(
                    key: TutorialService.mapReportBtnKey,
                    title: 'Reportar Incidente',
                    description:
                        'Presiona aquÃ­ para reportar un incidente en tu ubicaciÃ³n actual. TambiÃ©n puedes mantener presionado cualquier punto del mapa para enviar un reporte allÃ­.',
                    targetPadding: const EdgeInsets.all(8),
                    tooltipBackgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    textColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    child: FloatingActionButton(
                      heroTag: 'btn_reportar_incidente',
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      // Al presionar reportamos EXACTAMENTE en la ubicaci?n GPS actual
                      onPressed: () {
                        if (_realUserPosition != null) {
                          _abrirFormularioReporte(_realUserPosition!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Esperando tu ubicaciÃ³n GPS. Tambien puedes mantener presionado en el mapa para reportar manualmente.',
                              ),
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.campaign, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'map_location',
            onPressed: () {
              // Al presionar este bot?n, obl?gamos a pedir una nueva ubicaci?n real
              _determinePosition(userForced: true);
            },
            child: const Icon(Icons.my_location),
          ),
        );
      },
    );
  }
}
