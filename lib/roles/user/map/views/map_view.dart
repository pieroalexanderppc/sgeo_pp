import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/map_service.dart';
import 'widgets/report_dialog.dart';

class MapView extends StatefulWidget {
  final String userId;
  const MapView({super.key, required this.userId});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng? _currentPosition; // La posici?n inicial del mapa o donde enfoca
  LatLng? _realUserPosition; // La ubicaci?n EXACTA por GPS del usuario
  final MapController _mapController = MapController();
  final PanelController _panelController = PanelController(); // Panel deslizante
  dynamic _selectedZona; // Info de la zona actual tocada
  
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  List<dynamic> _zonasRiesgo = [];
  List<dynamic> _puntosExactos = []; // <--- NUEVO: para reportes ciudadanos

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadZonasRiesgo();
    _loadPuntosExactos(); // <--- NUEVO
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
      case 'bajo': return Colors.green.withAlpha(76); // 0.3 opacity ~ 76
      case 'medio': return Colors.orange.withAlpha(102); // 0.4 opacity ~ 102
      case 'alto': return Colors.redAccent.withAlpha(127); // 0.5 opacity ~ 127
      case 'critico': return Colors.red.withAlpha(178); // 0.7 opacity ~ 178
      default: return Colors.grey.withAlpha(127); // 0.5 opacity ~ 127
    }
  }

/// Define una ubicacion por defecto (ej. Centro de Tacna) si falla el GPS
  void _useFallbackLocation({bool userForced = false}) {
    if (!mounted) return;
    setState(() {
      _currentPosition ??= const LatLng(-18.0146, -70.2536);
      _isLoading = false;
    });

    if (userForced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('?? No se pudo obtener ubicacion exacta tan rapido. Esperando actualizacion...'),
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
          content: Text('Buscando ubicación actual, por favor espera...'),
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
      
      // 1. Obtener la ubicación cacheadísima en celulares (Web crashea con esto)
      if (!userForced) {
        try {
          if (!kIsWeb) {
            position = await Geolocator.getLastKnownPosition();
          }
        } catch (_) {}
      }
      
      // 2. Si forzamos, o no hay caché, pedir la ubicación con ALTA precisión y SIN ahogarlo
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.best) // Mejor precisión satelital
          ).timeout(const Duration(seconds: 15)); // Un margen decente de 15 segundos para el GPS
        } catch (e) {
          debugPrint('Aviso GPS: $e');
        }
      }

      // Si nos dio posicion puntual
      if (mounted && position != null) {
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _realUserPosition = newPos;
          _currentPosition = newPos;
          _isLoading = false;
        });
        
        // Con una ligera espera para asegurar que el map_controller haya cargado en UI
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          try { _mapController.move(newPos, 16.0); } catch (e) { debugPrint('Error map: $e'); }
        });
      } else if (mounted) {
        // Si el stream de rastreo todavia no obtuvo nada
        if (_realUserPosition == null) {
          _useFallbackLocation(userForced: userForced); 
        } else {
          // Ya tiene posici?n por el stream de rastreo, solo quitamos loading y centramos si forz?
          setState(() => _isLoading = false);
          if (userForced && _realUserPosition != null) {
             try { _mapController.move(_realUserPosition!, 16.0); } catch (_) {}
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
    _positionStreamSubscription ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      if (mounted) {
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _realUserPosition = newPos;
          // Si el mapa estaba en ubicacion por defecto, lo enfocamos de inmediato
          if (_currentPosition == null || _currentPosition == const LatLng(-18.0146, -70.2536)) {
            _currentPosition = newPos;
            _isLoading = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              try { _mapController.move(newPos, 16.0); } catch (_) {}
            });
          }
        });
      }
    });
  }

  void _handleMapTap(TapPosition _, LatLng tapLatLng) {
    const Distance distance = Distance();
    
    // Buscar si el tap ocurrió dentro de alguna zona de calor
    for (var zona in _zonasRiesgo) {
      if (zona['centroide'] == null || zona['centroide']['coordinates'] == null) continue;
      
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
                   .animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(duration: 800.ms, curve: Curves.easeInOut, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
               const SizedBox(width: 8),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                      'Zona de Riesgo $nivel',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.security, color: Colors.white)),
            title: Text('Incidentes registrados: ${zona['total_incidentes'] ?? "Varios"}'),
            subtitle: const Text('Basado en denuncias y reportes policiales.'),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          if (zona['delito_predominante'] != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning, color: Colors.white)),
              title: Text('Delito frecuente: ${zona['delito_predominante']}'),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.trending_up, color: Colors.white)),
            title: Text('Tendencia: ${zona['tendencia'] ?? "Desconocida"}'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          BoxShadow(blurRadius: 10, color: Colors.black.withAlpha(25))
        ],
        panel: _buildPanelContent(),
        body: Stack(
          children: [
            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 60, color: Colors.blue)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(duration: 800.ms, curve: Curves.easeInOut)
                            .tint(color: Colors.lightBlueAccent, duration: 800.ms),
                        const SizedBox(height: 16),
                        const Text("Ubicando señal GPS...").animate().fadeIn(duration: 500.ms),
                      ],
                    ),
                  )
                : _currentPosition == null
                    ? const Center(child: Text('No se pudo inicializar el mapa. Revisar permisos.'))
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
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.sgeo_pp',
                        ),
                        if (_zonasRiesgo.isNotEmpty)
                          CircleLayer(
                            circles: _zonasRiesgo.map<CircleMarker>((zona) {
                              final coords = zona['centroide']['coordinates'];
                              final lat = (coords[1] as num).toDouble();
                              final lng = (coords[0] as num).toDouble();
                              final radius = (zona['radio_metros'] as num?)?.toDouble() ?? 500.0;
                              
                              return CircleMarker(
                                point: LatLng(lat, lng), // GeoJSON es [lon, lat], pero LatLng es (lat, lon)
                                color: _getColorForNivel(zona['nivel_riesgo']),
                                borderStrokeWidth: 2,
                                borderColor: _getColorForNivel(zona['nivel_riesgo']).withAlpha(204), // 0.8 opacity ~ 204
                                useRadiusInMeter: true,
                                radius: radius, // Radio de calor
                              );
                            }).toList(),
                          ),
                        MarkerLayer(
                          markers: [
                            // 1. Puntos exactos reportados
                            ..._puntosExactos.map((punto) {
                              final coords = punto['ubicacion']['coordinates'];
                              // Estado pendiente = purpura (Pendiente de validar), confirmado = negro
                              final colorPunto = punto['estado'] == 'pendiente' ? Colors.deepPurple : Colors.black;
                              
                              return Marker(
                                point: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
                                width: 40,
                                height: 40,
                                alignment: Alignment.center, // Centrado para que la 'X' de la alerta quede exactamente en el punto
                                child: Icon(Icons.warning_amber_rounded, color: colorPunto, size: 30.0),
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
                                        border: Border.all(color: Colors.white, width: 2.5),
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

          // -- BOT?N PARA REPORTAR (Esquina Superior Derecha) --
          Positioned(
            top: 40,
            right: 20,
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
                      content: Text('Esperando tu ubicación GPS. Tambien puedes mantener presionado en el mapa para reportar manualmente.'),
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Icon(Icons.campaign, size: 28),
              
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
  }
}






