import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sgeo_pp/core/config/api_config.dart';

/// ============================================================================
/// PredictiveService — Servicio Flutter para el módulo de seguridad contextual
/// ============================================================================
/// Consume los endpoints /api/predictive/* del backend FastAPI.
/// Implementa caché local en memoria para evitar llamadas redundantes.
/// ============================================================================

class PredictiveService {
  // ── Caché en memoria ──
  static Map<String, dynamic>? _cachedScore;
  static DateTime? _lastScoreFetch;
  static Map<String, dynamic>? _cachedInsights;
  static DateTime? _lastInsightsFetch;

  /// Limpia la caché del servicio predictivo.
  static void clearCache() {
    _cachedScore = null;
    _lastScoreFetch = null;
    _cachedInsights = null;
    _lastInsightsFetch = null;
  }

  /// Obtiene el Safety Score dinámico para una ubicación y hora.
  /// Retorna: { score, nivel, color, mensaje, turno_actual, factores }
  static Future<Map<String, dynamic>> fetchSafetyScore({
    required double lat,
    required double lng,
    int? hora,
    bool forceRefresh = false,
  }) async {
    // Caché de 30 segundos
    if (!forceRefresh && _cachedScore != null && _lastScoreFetch != null) {
      if (DateTime.now().difference(_lastScoreFetch!).inSeconds < 30) {
        return _cachedScore!;
      }
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/predictive/safety_score').replace(
        queryParameters: {
          'lat': lat.toStringAsFixed(5),
          'lng': lng.toStringAsFixed(5),
          if (hora != null) 'hora': hora.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _cachedScore = data;
          _lastScoreFetch = DateTime.now();
          return data;
        }
      }
    } catch (e) {
      debugPrint('PredictiveService safety_score error: $e');
    }

    // Fallback seguro
    return {
      'score': 65.0,
      'nivel': 'precaucion',
      'color': '#FFB300',
      'mensaje': 'Sin datos disponibles',
      'turno_actual': 'desconocido',
      'factores': {},
    };
  }

  /// Obtiene los insights contextuales para una ubicación.
  /// Retorna lista de { tipo, icono, mensaje, severidad }
  static Future<List<Map<String, dynamic>>> fetchContextInsights({
    required double lat,
    required double lng,
    int? hora,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedInsights != null && _lastInsightsFetch != null) {
      if (DateTime.now().difference(_lastInsightsFetch!).inSeconds < 60) {
        final list = _cachedInsights!['insights'] as List?;
        return list?.cast<Map<String, dynamic>>() ?? [];
      }
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/predictive/context_insights').replace(
        queryParameters: {
          'lat': lat.toStringAsFixed(5),
          'lng': lng.toStringAsFixed(5),
          if (hora != null) 'hora': hora.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _cachedInsights = data;
          _lastInsightsFetch = DateTime.now();
          final list = data['insights'] as List?;
          return list?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        }
      }
    } catch (e) {
      debugPrint('PredictiveService context_insights error: $e');
    }

    return [];
  }

  /// Obtiene el análisis temporal completo.
  static Future<Map<String, dynamic>> fetchTemporalAnalysis({
    String? distrito,
    int dias = 365,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/predictive/temporal_analysis').replace(
        queryParameters: {
          'dias': dias.toString(),
          'distrito': ?distrito,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      debugPrint('PredictiveService temporal_analysis error: $e');
    }
    return {};
  }

  /// Obtiene el pronóstico de riesgo.
  static Future<Map<String, dynamic>> fetchRiskForecast({String? distrito}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/predictive/risk_forecast').replace(
        queryParameters: {
          'distrito': ?distrito,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      debugPrint('PredictiveService risk_forecast error: $e');
    }
    return {};
  }

  /// Obtiene los horarios seguros recomendados.
  static Future<Map<String, dynamic>> fetchSafeHours({String? distrito}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/predictive/safe_hours').replace(
        queryParameters: {
          'distrito': ?distrito,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      debugPrint('PredictiveService safe_hours error: $e');
    }
    return {};
  }
}
