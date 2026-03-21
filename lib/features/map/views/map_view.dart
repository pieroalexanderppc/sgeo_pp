import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/map_service.dart';
import 'widgets/report_dialog.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
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
      debugPrint("❌ Error cargando puntos exactos: $e");
    }
  }

  Future<void> _loadZonasRiesgo() async {
    try {
      final zonas = await MapService.fetchZonasRiesgo();
      setState(() {
        _zonasRiesgo = zonas;
      });
      debugPrint("✅ Zonas de riesgo cargadas: ${_zonasRiesgo.length}");
    } catch (e) {
      debugPrint("❌ Error cargando zonas de riesgo: $e");
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
  void _useFallbackLocation() {
    if (!mounted) return;
    setState(() {
      _currentPosition = const LatLng(-18.0146, -70.2536);
      _isLoading = false;
    });
    // Se intenta mover el mapa, aunque puede que no este listo aun,
    // pero initialCenter lo tomara de todos modos.
  }

  /// Solicita permisos y obtiene la ubicacion actual del usuario
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Verifica si el servicio de ubicacion esta habilitado.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      } 

      // Intentamos obtener la última posición conocida por rapidez
      Position? position = await Geolocator.getLastKnownPosition();
      
      // Si no hay última posición, esperamos la actual (amplié el tiempo a 15 segundos para móviles un poco lentos)
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position!.latitude, position.longitude);
          _isLoading = false;
        });
        // Con una ligera espera para asegurar que el map_controller haya cargado en UI
        Future.delayed(const Duration(milliseconds: 300), () {
          _mapController.move(_currentPosition!, 16.0);
        });
      }
    } catch (e) {
      debugPrint('Error geolocator: $e');
      _useFallbackLocation(); // Falla si el GPS está apagado o en Web sin permisos
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
      ),
    );

    // Si el reporte fue exitoso, refrescamos los puntos exactos para que aparezca
    if (reportado == true) {
      _loadPuntosExactos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading 
              ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Obteniendo ubicacion...'))
              : _currentPosition == null
                  ? const Center(child: Text('No se pudo inicializar el mapa. Revisar permisos.'))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 15.0,
                        // Permitir a la persona presionar largo en una calle especifica para reportar
                        onLongPress: (tapPosition, latLng) {
                          _abrirFormularioReporte(latLng);
                        },
                      ),
                      children: [
                        TileLayer(
                          // Usamos OpenStreetMap por defecto (No requiere API Key y es libre)
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                child: Icon(Icons.warning_amber_rounded, color: colorPunto, size: 30.0),
                              );
                            }),
                            
                            // 2. Posición actual del usuario
                            Marker(
                              point: _currentPosition!,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.blue,
                                size: 45.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

          // -- BOTÓN PARA REPORTAR (Esquina Superior Derecha) --
          Positioned(
            top: 40,
            right: 20,
            child: FloatingActionButton.extended(
              heroTag: 'btn_reportar_incidente',
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              // Al presionar solicitamos dónde reportarlo con instrucciones
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mantén presionado sobre la calle en el mapa para ubicar tu reporte.'),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.campaign, size: 28),
              label: const Text("Reportar Incidente"),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_location',
        onPressed: () {
          if (_currentPosition != null) {
            // Un pequeño truco que el usuario puede usar para ir a las zonas IA
            // Si el usuario mantiene pulsado o pulsa normal
            _mapController.move(_currentPosition!, 15.0);
          } else {
            setState(() => _isLoading = true);
            _determinePosition();
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
