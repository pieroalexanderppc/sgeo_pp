import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notifications_storage_service.dart';
import 'map_service.dart';

/// Instancia independiente de notificaciones locales preconfigurada en el ámbito global
/// para evitar inyección de dependencias redundante con main.dart de Flutter.
final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

class GeofenceService {
  static StreamSubscription<Position>? _positionStream;
  static bool _isRunning = false;

  /// Variables de estado destinadas a la limitación temporal (cooldown) y contención de alertas 
  /// para impedir envíos repetitivos por fluctuación del satélite GPS.
  static DateTime? _lastAlertTime;
  static const int _alertCooldownMinutes = 30;

  /// Almacén en memoria volátil conteniendo datos de las Zonas de Riesgo actuales
  static List<dynamic> _realRiskZones = [];

  static Future<void> startTracking() async {
    if (_isRunning) return;

    // Obtención delegada de Zonas de Riesgo sincronizadas desde el back-end
    try {
      _realRiskZones = await MapService.fetchZonasRiesgo();
      debugPrint("Instancias de Riesgo cargadas exitosamente: ${_realRiskZones.length}");
    } catch (e) {
      debugPrint("Excepción al cargar Geocercas remota: $e");
    }

    // Inicialización y revalidación asíncrona de permisos de geolocalización.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Configuración estructural para el proveedor de posición;
    // filtrado restrictivo en metros de acuerdo a variaciones estables.
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _isRunning = true;
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _checkIfInsideRiskZone(position);
    });

    debugPrint("Seguimiento del módulo de Geocerca (Geofence) iniciado correctamente.");
  }

  static void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isRunning = false;
    debugPrint("Seguimiento del módulo de Geocerca interrumpido y destruido.");
  }

  /// Método auxiliar creado con fines de desarrollo para evaluar triggers de notificación local
  /// al sobreescribir y enrutar las coordinadas deseadas a través de flujos manuales.
  static Future<void> checkManualLocation(double lat, double lng) async {
    _lastAlertTime = null; // Reiniciar iteraciones cronológicas preventivas para fase de testing.
    final fakePosition = Position(
      longitude: lng,
      latitude: lat,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    await _checkIfInsideRiskZone(fakePosition);
  }

  static Future<void> _checkIfInsideRiskZone(Position currentPosition) async {
    // Suspensión activa para evadir saturación de notificaciones de la misma Geocerca.
    if (_lastAlertTime != null && 
        DateTime.now().difference(_lastAlertTime!).inMinutes < _alertCooldownMinutes) {
      return; 
    }

    if (_realRiskZones.isEmpty) return;

    for (var zone in _realRiskZones) {
      double lat = 0.0;
      double lng = 0.0;

      // Acceso validado al modelo de datos emitido de backend independientemente
      // del protocolo empleado, sea GeoJSON para IA o arreglo referencial crudo.
      if (zone.containsKey('centroide') && zone['centroide'] != null && zone['centroide']['coordinates'] != null) {
        final coords = zone['centroide']['coordinates'];
        lat = (coords[1] as num).toDouble();
        lng = (coords[0] as num).toDouble();
      } else if (zone.containsKey('poligono') && (zone['poligono'] as List).isNotEmpty) {
        lat = (zone['poligono'][0][1] as num).toDouble();
        lng = (zone['poligono'][0][0] as num).toDouble();
      } else {
        continue;
      }

      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      // Conversión del rango periférico proveniente del origen de datos,
      // fallback estricto predeterminado adaptado.
      double radiusWarning = (zone['radio_metros'] as num?)?.toDouble() ?? 300.0;

      // Evento de intrusión geográfica detectado, emitir disparador y detener el ciclo condicionado. 
      if (distanceInMeters <= radiusWarning) {
        String zoneName = zone['nivel_riesgo']?.toString().toUpperCase() ?? 'ALTA';
        _triggerLocalAlert(zoneName);
        _lastAlertTime = DateTime.now();
        break;
      }
    }
  }

  static Future<void> _triggerLocalAlert(String zoneName) async {
    // Encapsulación del objeto contenedor para uniformizar con 
    // la estructura proveniente nativamente de Firebase Cloud Messaging.
    final String title = '¡Precaución! Nivel de Riesgo: $zoneName';
    final String body = 'Se ha detectado que estás ingresando a una zona de riesgo. Mantente alerta a tu entorno.';
    
    final fakeMessage = RemoteMessage(
      notification: RemoteNotification(
        title: title,
        body: body,
      ),
      data: {
        'type': 'risk_zone'
      }
    );
    
    // Transcodificación local al servicio de persistencia offline
    await NotificationsStorageService.saveFromRemoteMessage(fakeMessage);

    // Activación acústica y vibración local ejecutada de forma dependiente al canal.
    await _localPlugin.show(
      id: DateTime.now().millisecond, // Asignación de ID aleatorizado consecutivo
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sgeo_alertas_urgentes',
          'Alertas de Seguridad',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
