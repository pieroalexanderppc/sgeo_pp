// Nuevo servicio: centraliza GET/PUT de perfil de usuario siguiendo el patron de AuthService/ReportService.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:sgeo_pp/core/config/api_config.dart';

/// Servicio encargado de consultar y actualizar el perfil del usuario
/// (GET /api/usuarios/{id} y PUT /api/usuarios/{id}).
class UserService {
  /// Extrae un mensaje legible del campo `detail` de FastAPI, que puede ser
  /// un string (HTTPException) o una lista de errores de validación (Pydantic 422).
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

  static Future<Map<String, dynamic>> getUsuario(String userId) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.usuario(userId)));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': _extractDetail(data, 'No se pudo cargar el perfil.')};
    } catch (e) {
      debugPrint('UserService.getUsuario error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> actualizarUsuario(
    String userId, {
    required String nombre,
    required String email,
    required String telefono,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.usuario(userId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'email': email, 'telefono': telefono}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'] ?? 'Perfil actualizado con éxito.'};
      }
      return {'success': false, 'message': _extractDetail(data, 'Error al actualizar datos.')};
    } catch (e) {
      debugPrint('UserService.actualizarUsuario error: $e');
      return {'success': false, 'message': 'Error de red al actualizar el perfil.'};
    }
  }
}
