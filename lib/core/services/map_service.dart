import 'dart:convert';
import 'package:http/http.dart' as http;

class MapService {
  // Enlace directo a tu servidor Railway
  static const String _baseUrl = 'https://sgeo-backend-production.up.railway.app';

  // --- OBTENER ZONAS DE RIESGO (Generadas por IA/SIDPOL) ---
  static Future<List<dynamic>> fetchZonasRiesgo() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/map/zonas_riesgo'));
    
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      if (decodedData['status'] == 'success') {
        return decodedData['zonas'] ?? [];
      } else {
        throw Exception("Error del servidor: ${decodedData['detail']}");
      }
    } else {
      throw Exception('Error al conectar con el servidor (${response.statusCode})');
    }
  }

  // --- OBTENER PUNTOS EXACTOS (Reportes/Incidentes) ---
  static Future<List<dynamic>> fetchPuntosExactos() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/map/puntos_exactos'));
    
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      if (decodedData['status'] == 'success') {
        return decodedData['puntos'] ?? [];
      } else {
        throw Exception("Error del servidor: ${decodedData['detail']}");
      }
    } else {
      throw Exception('Error al conectar con el servidor (${response.statusCode})');
    }
  }

  // --- ENVIAR REPORTE CIUDADANO ---
  static Future<bool> crearReporte(Map<String, dynamic> datosReporte) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/reportes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datosReporte),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}

