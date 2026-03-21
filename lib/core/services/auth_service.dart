import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  // Enlace directo a tu servidor Railway
  static const String _baseUrl = 'https://sgeo-backend-production.up.railway.app';

  // --- LOGIN ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail'] ?? 'Error desconocido'};
      }
    } catch (e) {
      debugPrint('AuthService login error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }

  // --- REGISTER ---
  static Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail'] ?? 'Error de registro'};
      }
    } catch (e) {
      debugPrint('AuthService register error: $e');
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }
}
