import 'dart:convert';
import 'package:http/http.dart' as http;

class MapService {
  /// Enlace base apuntando al entorno de producción hospedado en Railway.
  static const String _baseUrl = 'https://sgeo-backend-production.up.railway.app';

  /// Conjunto de variables relativas a la gestión de memoria (Caché local). 
  /// Esta estrategia restringe desbordamientos de peticiones HTTP en escenarios de alto tráfico.
  static List<dynamic>? _cachedZonas;
  static DateTime? _lastZonasFetch;
  static Future<List<dynamic>>? _ongoingFetchZonas; 

  /// Limpia forzadamente la caché en la instancia para futuras peticiones.
  /// Provocado principalmente por la detección contextual de eventos críticos en las notificaciones.
  static void clearCache() {
    _cachedZonas = null;
    _lastZonasFetch = null;
    _ongoingFetchZonas = null;
  }

  /// Recupera de forma asíncrona la lista de Zonas de Riesgo procesadas por 
  /// la Inteligencia IA / Modelamiento geoespacial.
  static Future<List<dynamic>> fetchZonasRiesgo({bool forceRefresh = false}) async {
    // 1. Evaluación temporal de caducidad en memoria (Lifespan: 15 minutos).
    if (!forceRefresh && _cachedZonas != null && _lastZonasFetch != null) {
      if (DateTime.now().difference(_lastZonasFetch!).inMinutes < 15) {
        return _cachedZonas!;
      }
    }

    // 2. Control de concurrencia: Prevenir invocación colapsada o llamadas 
    // desincronizadas redundantes mediante bloqueo temporal por Futuro.
    if (_ongoingFetchZonas != null) {
      return _ongoingFetchZonas!;
    }

    _ongoingFetchZonas = _doFetchZonas();
    try {
      final result = await _ongoingFetchZonas!;
      _cachedZonas = result;
      _lastZonasFetch = DateTime.now();
      return result;
    } finally {
      _ongoingFetchZonas = null; // Limpiar para futuros llamados
    }
  }

  static Future<List<dynamic>> _doFetchZonas() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/map/zonas_riesgo'));
    
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      if (decodedData['status'] == 'success') {
        return decodedData['zonas'] ?? [];
      } else {
        throw Exception("Error del servidor: ${decodedData['detail']}");
      }
    } else {
      throw Exception('Error al conectar con el servidor (${response.statusCode})');
    }
  }

  // --- OBTENER PUNTOS EXACTOS (Reportes/Incidentes) ---
  static Future<List<dynamic>> fetchPuntosExactos() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/map/puntos_exactos'));
    
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      if (decodedData['status'] == 'success') {
        return decodedData['puntos'] ?? [];
      } else {
        throw Exception("Error del servidor: ${decodedData['detail']}");
      }
    } else {
      throw Exception('Error al conectar con el servidor (${response.statusCode})');
    }
  }

  // --- ENVIAR REPORTE CIUDADANO ---
  static Future<bool> crearReporte(Map<String, dynamic> datosReporte) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/reportes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datosReporte),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}

