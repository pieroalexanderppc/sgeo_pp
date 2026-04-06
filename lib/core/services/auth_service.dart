import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Enlace directo a tu servidor Railway
  static const String _baseUrl =
      'https://sgeo-backend-production.up.railway.app';

  // --- LOGIN ---
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['usuario'];
        
        // Guardar sesión en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userData['id'] ?? userData['_id'] ?? '');
        await prefs.setString('user_name', userData['nombre'] ?? '');
        await prefs.setString('user_role', userData['rol'] ?? 'ciudadano');
        await prefs.setBool('is_logged_in', true);

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = 'Error desconocido';
        if (error['detail'] != null) {
          if (error['detail'] is List) {
            errorMessage = error['detail'][0]['msg'] ?? 'Error de validación';
          } else {
            errorMessage = error['detail'].toString();
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      debugPrint('AuthService login error: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor.',
      };
    }
  }

  // --- REGISTER ---
  static Future<Map<String, dynamic>> register(
    String nombre,
    String email,
    String password, {
    String rol = 'ciudadano',
    bool isActive = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,
          'is_active': isActive,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = 'Error de registro';
        if (error['detail'] != null) {
          if (error['detail'] is List) {
            errorMessage = error['detail'][0]['msg'] ?? 'Error de validación';
          } else {
            errorMessage = error['detail'].toString();
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      debugPrint('AuthService register error: $e');
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor.',
      };
    }
  }

  // --- LOGOUT ---
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Borra todos los datos de sesión
    } catch (e) {
      debugPrint('AuthService logout error: $e');
    }
  }
}
