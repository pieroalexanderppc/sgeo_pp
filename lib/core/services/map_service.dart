// crearReporte ahora retorna detalle (status/mensaje) para distinguir el limite diario (429) de otros errores.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'report_service.dart';
import 'geofence_service.dart';
import 'package:sgeo_pp/core/config/api_config.dart';

// --- FUNCIÓN TOP-LEVEL PARA ISOLATE ---
// Al sacar el parseo del Hilo Principal (Main UI Thread) usando compute, 
// evitamos que la interfaz crashee o se congele durante milisegundos
// cuando se procesan listas masivas de puntos o zonas poligonales complejas.
Map<String, dynamic> _parseJsonData(String responseBody) {
  return json.decode(responseBody) as Map<String, dynamic>;
}

class MapService {
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
    GeofenceService.refreshZones(); // Sincronizar el motor de alertas en tiempo real
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

  // Se envuelve en try/catch (rethrow) para registrar el error y evitar que una excepcion
  // cruda de I/O (sin traduccion) se propague sin diagnostico; el cacheo de exito no cambia.
  static Future<List<dynamic>> _doFetchZonas() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.zonasRiesgo));

      if (response.statusCode == 200) {
        final decodedData = await compute(_parseJsonData, response.body);
        if (decodedData['status'] == 'success') {
          return decodedData['zonas'] ?? [];
        } else {
          throw Exception("Error del servidor: ${decodedData['detail']}");
        }
      } else {
        throw Exception('Error al conectar con el servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error en MapService._doFetchZonas: $e');
      rethrow;
    }
  }

  // --- OBTENER TODOS LOS PUNTOS HISTORICOS (Zoom in detallado) ---
  static Future<List<dynamic>> fetchPuntosHistorial() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.historial));

      if (response.statusCode == 200) {
        final decodedData = await compute(_parseJsonData, response.body);
        if (decodedData['status'] == 'success') {
          return decodedData['puntos'] ?? [];
        } else {
          throw Exception("Error del servidor: ${decodedData['detail']}");
        }
      } else {
        throw Exception('Error al conectar con el servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error en MapService.fetchPuntosHistorial: $e');
      rethrow;
    }
  }

  // --- OBTENER PUNTOS EXACTOS (Reportes/Incidentes) ---
  static Future<List<dynamic>> fetchPuntosExactos() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.puntosExactos));

      if (response.statusCode == 200) {
        final decodedData = await compute(_parseJsonData, response.body);
        if (decodedData['status'] == 'success') {
          return decodedData['puntos'] ?? [];
        } else {
          throw Exception("Error del servidor: ${decodedData['detail']}");
        }
      } else {
        throw Exception('Error al conectar con el servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error en MapService.fetchPuntosExactos: $e');
      rethrow;
    }
  }

  // --- OBTENER REPORTES POLICIA (Pendientes y Confirmados) ---
  static Future<List<dynamic>> fetchPuntosPolicia() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.reportesPolicia));

      if (response.statusCode == 200) {
        final decodedData = await compute(_parseJsonData, response.body);
        if (decodedData['status'] == 'success') {
          return decodedData['puntos'] ?? [];
        } else {
          throw Exception("Error del servidor: ${decodedData['detail']}");
        }
      } else {
        throw Exception('Error al conectar con el servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error en MapService.fetchPuntosPolicia: $e');
      rethrow;
    }
  }

  // --- ENVIAR REPORTE CIUDADANO ---
  // Retorna detalle (statusCode/mensaje del backend) en lugar de un bool plano,
  // para que la UI distinga el limite diario (429) de otros errores.
  static Future<Map<String, dynamic>> crearReporte(Map<String, dynamic> datosReporte) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.crearReporte),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datosReporte),
      );

      final decoded = response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode == 200) {
        ReportService.notifyReportsUpdated();
        return {
          'success': true,
          'statusCode': 200,
          'message': decoded['mensaje'] ?? 'Reporte enviado con éxito',
        };
      }

      final statusCode = response.statusCode;
      String mensaje;
      if (statusCode == 429) {
        // Limite diario de 5 reportes (backend: services/report_service.py:validar_limite_diario)
        mensaje = 'Límite de reportes alcanzado por hoy';
      } else if (statusCode >= 500) {
        mensaje = 'Error del servidor, intenta más tarde';
      } else {
        mensaje = decoded['detail']?.toString() ?? 'Error del servidor ($statusCode)';
      }

      return {'success': false, 'statusCode': statusCode, 'message': mensaje};
    } catch (e) {
      debugPrint('Error en MapService.crearReporte: $e');
      return {
        'success': false,
        'statusCode': null,
        'message': 'No se pudo conectar con el servidor.',
      };
    }
  }
}

