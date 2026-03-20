import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
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

      // Obtenemos la posicion base con un timeout para evitar bucles infinitos en simuladores
      Position position = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      print('Error geolocator: $e');
      _useFallbackLocation(); // Si ocurre un timeout o error (ej en Windows o emuladores), carga Tacna
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
                      ),
                      children: [
                        TileLayer(
                          // Usamos OpenStreetMap por defecto (No requiere API Key y es libre)
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.sgeo_pp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition!,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
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
