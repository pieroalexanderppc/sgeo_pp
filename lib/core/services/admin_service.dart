// Nuevo servicio: centraliza las llamadas a /api/admin/* (dashboard, gestion de usuarios,
// flujo de aprobacion policial), incluyendo el header X-User-Role que ahora exige el backend.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sgeo_pp/core/config/api_config.dart';

class AdminService {
  /// Notifica a la UI (badge del tab "Solicitudes") cuantos policias estan pendientes.
  static final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    return {'Content-Type': 'application/json', 'X-User-Role': role};
  }

  /// Extrae un mensaje legible del campo `detail` de FastAPI (string o lista de errores Pydantic).
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

  /// Vuelve a calcular el conteo de policias pendientes para el badge del shell admin.
  static Future<void> refreshPendingCount() async {
    final resultado = await getUsuarios(pendiente: true);
    if (resultado['success'] == true) {
      final usuarios = resultado['usuarios'] as List;
      pendingCountNotifier.value = usuarios.length;
    }
  }

  // --- Dashboard ---

  static Future<Map<String, dynamic>> getDashboardStats({String filtroTiempo = 'Todos'}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.dashboardStats}?filtro_tiempo=$filtroTiempo'),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'stats': data['stats']};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo cargar el dashboard.')};
    } catch (e) {
      debugPrint('AdminService.getDashboardStats error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> getSidpolStats() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.sidpolStats), headers: await _headers());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'stats': data['stats']};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo cargar estadísticas SIDPOL.')};
    } catch (e) {
      debugPrint('AdminService.getSidpolStats error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> getSidpolPredict() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.sidpolPredict), headers: await _headers());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo cargar la predicción.')};
    } catch (e) {
      debugPrint('AdminService.getSidpolPredict error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  // --- Gestión de usuarios ---

  static Future<Map<String, dynamic>> getUsuarios({String? rol, bool? pendiente}) async {
    try {
      final queryParams = <String, String>{};
      if (rol != null) queryParams['rol'] = rol;
      if (pendiente != null) queryParams['pendiente'] = pendiente.toString();
      final uri = Uri.parse(ApiConfig.adminUsuarios)
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri, headers: await _headers());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'usuarios': data['usuarios'] ?? []};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo cargar la lista de usuarios.')};
    } catch (e) {
      debugPrint('AdminService.getUsuarios error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> aprobarUsuario(String userId) async {
    try {
      final response = await http.put(Uri.parse(ApiConfig.adminAprobar(userId)), headers: await _headers());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['mensaje'] ?? 'Cuenta aprobada.'};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo aprobar la cuenta.')};
    } catch (e) {
      debugPrint('AdminService.aprobarUsuario error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> rechazarUsuario(String userId, String motivo) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.adminRechazar(userId)),
        headers: await _headers(),
        body: jsonEncode({'motivo': motivo}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['mensaje'] ?? 'Solicitud rechazada.'};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo rechazar la cuenta.')};
    } catch (e) {
      debugPrint('AdminService.rechazarUsuario error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> eliminarUsuario(String userId) async {
    try {
      final response = await http.delete(Uri.parse(ApiConfig.adminEliminar(userId)), headers: await _headers());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['mensaje'] ?? 'Usuario eliminado.'};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo eliminar el usuario.')};
    } catch (e) {
      debugPrint('AdminService.eliminarUsuario error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> suspenderUsuario(String userId) async {
    try {
      final response = await http.put(Uri.parse(ApiConfig.adminSuspender(userId)), headers: await _headers());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'activo': data['activo'] == true};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo cambiar el estado del usuario.')};
    } catch (e) {
      debugPrint('AdminService.suspenderUsuario error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }
}
