import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';

/// Servicio responsable de la comunicación directa con la API del servidor
/// para todo lo relacionado al Módulo de Reportes de Incidentes.
class ReportService {
  // Reutilizamos el endpoint base de Producción declarado en MapService
  // Podrías extraerlo a un 'api_constants.dart' despues, pero ahora sirve bien.
  static const String _baseUrl = 'https://sgeo-backend-production.up.railway.app';

  /// Obtiene la lista de reportes asociados a un usuario en específico
  /// Retorna una Lista de [ReportModel] fuertemente tipada.
  static Future<List<ReportModel>> getMyReports(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/reportes/mis_reportes/$userId'));
      
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
      final response = await http.delete(Uri.parse('$_baseUrl/api/reportes/$reportId'));
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
