// Nuevo servicio: centraliza confirmar/rechazar reportes (usado por el mapa y por Validaciones)
// y el contador de pendientes para el badge del shell policial.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sgeo_pp/core/config/api_config.dart';
import 'map_service.dart';
import 'report_service.dart';

class PoliceService {
  static final ValueNotifier<int> pendingReportsNotifier = ValueNotifier<int>(0);

  static String _extractDetail(Map<String, dynamic> body, String fallback) {
    final detail = body['detail'];
    if (detail == null) return fallback;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
      return fallback;
    }
    return detail.toString();
  }

  static Future<Map<String, dynamic>> confirmarReporte(String reporteId) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.confirmar(reporteId)));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        ReportService.notifyReportsUpdated();
        return {'success': true, 'message': data['mensaje'] ?? 'Reporte confirmado.'};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo confirmar el reporte.')};
    } catch (e) {
      debugPrint('PoliceService.confirmarReporte error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> rechazarReporte(String reporteId) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.rechazar(reporteId)));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        ReportService.notifyReportsUpdated();
        return {'success': true, 'message': data['mensaje'] ?? 'Reporte rechazado.'};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo rechazar el reporte.')};
    } catch (e) {
      debugPrint('PoliceService.rechazarReporte error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  /// Recalcula el contador de reportes pendientes para el badge del tab "Validar".
  static Future<void> refreshPendingCount() async {
    try {
      final reportes = await MapService.fetchPuntosPolicia();
      final pendientes = reportes.where((r) => (r['estado'] ?? '').toString().toLowerCase() == 'pendiente').length;
      pendingReportsNotifier.value = pendientes;
    } catch (e) {
      debugPrint('PoliceService.refreshPendingCount error: $e');
    }
  }
}
