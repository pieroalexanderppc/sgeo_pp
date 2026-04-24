import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio encargado de manejar las operaciones de autenticación de usuarios.
/// Interactúa directamente con la API del backend para procesos de login,
/// registro y manejo de sesión local.
class AuthService {
  static const String _baseUrl =
      'https://sgeo-backend-production.up.railway.app';

  /// Autentica a un usuario utilizando su [email] y [password].
  /// 
  /// Retorna un [Map] indicando el estado de la petición. En caso de éxito,
  /// persiste los datos de la sesión del usuario de forma local.
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

  /// Registra una nueva cuenta de usuario en la plataforma.
  /// 
  /// Por defecto, el [rol] asignado es 'ciudadano'. Se requiere autorización
  /// explícita o lógica del backend para asignar roles administrativos o policiales.
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

  /// Finaliza la sesión actual eliminando todas las credenciales almacenadas.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('AuthService logout error: $e');
    }
  }
}
