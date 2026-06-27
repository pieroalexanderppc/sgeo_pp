// deleteReport ahora retorna mensaje/detalle del backend en vez de un bool plano; se corrige tambien un comentario con encoding corrupto.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import 'package:sgeo_pp/core/config/api_config.dart';

/// Servicio responsable de la comunicación directa con la API del servidor
/// para todo lo relacionado al Módulo de Reportes de Incidentes.
class ReportService {

  /// Obtiene la lista de reportes asociados a un usuario en específico
  /// Retorna una Lista de [ReportModel] fuertemente tipada.
  static Future<List<ReportModel>> getMyReports(String userId) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.misReportes(userId)));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> reportesJson = data['reportes'] ?? [];
          // Mapeamos los JSON dynamicos a Instancias de Clase
          return reportesJson.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return []; // Si no es success, retorna vacío
    } catch (e) {
      debugPrint("Error fetching reports in ReportService: $e");
      return []; // Error de Red, retorna vacío
    }
  }
  /// Permite al ciudadano eliminar un reporte que todavía está pendiente.
  static final ValueNotifier<bool> reportsUpdatedNotifier = ValueNotifier<bool>(false);

  static void notifyReportsUpdated() {
    reportsUpdatedNotifier.value = !reportsUpdatedNotifier.value;
  }

  /// Elimina un reporte y retorna el detalle (incluye el mensaje real del backend si falla,
  /// por ejemplo cuando el reporte ya no esta en estado 'pendiente').
  static Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      final response = await http.delete(Uri.parse(ApiConfig.eliminar(reportId)));
      final decoded = response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        notifyReportsUpdated();
        return {'success': true, 'message': decoded['message'] ?? 'Reporte eliminado exitosamente.'};
      }

      final mensaje = response.statusCode >= 500
          ? 'Error del servidor, intenta más tarde'
          : (decoded['detail']?.toString() ?? 'No se pudo eliminar el reporte.');
      return {'success': false, 'message': mensaje};
    } catch (e) {
      debugPrint("Error deleting report: $e");
      return {'success': false, 'message': 'Error de red al eliminar el reporte.'};
    }
  }
}
