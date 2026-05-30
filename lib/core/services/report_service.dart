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
  /// Permite al ciudadano eliminar un reporte que todavÃa estÃ¡ pendiente.
  static final ValueNotifier<bool> reportsUpdatedNotifier = ValueNotifier<bool>(false);

  static void notifyReportsUpdated() {
    reportsUpdatedNotifier.value = !reportsUpdatedNotifier.value;
  }

  static Future<bool> deleteReport(String reportId) async {
    try {
      final response = await http.delete(Uri.parse(ApiConfig.eliminar(reportId)));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          notifyReportsUpdated();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting report: $e");
      return false;
    }
  }}
