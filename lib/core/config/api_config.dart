class ApiConfig {
  static const String baseUrl = "https://sgeo-backend-production.up.railway.app";

  // Auth
  static const String login    = "$baseUrl/api/auth/login";
  static const String register = "$baseUrl/api/auth/register";

  // Usuarios
  static String usuario(String id)  => "$baseUrl/api/usuarios/$id";
  static const String usuariosBase = "$baseUrl/api/usuarios";

  // Reportes
  static const String crearReporte     = "$baseUrl/api/reportes";
  static const String reportesPolicia  = "$baseUrl/api/reportes/policia";
  static String misReportes(String id) => "$baseUrl/api/reportes/mis_reportes/$id";
  static String confirmar(String id)   => "$baseUrl/api/reportes/confirmar/$id";
  static String rechazar(String id)    => "$baseUrl/api/reportes/rechazar/$id";
  static String eliminar(String id)    => "$baseUrl/api/reportes/$id";

  // Mapa e IA
  static const String zonasRiesgo   = "$baseUrl/api/map/zonas_riesgo";
  static const String puntosExactos = "$baseUrl/api/map/puntos_exactos";
  static const String historial     = "$baseUrl/api/map/historial_puntos";
  static const String generarIA     = "$baseUrl/api/map/generar_zonas_ia";

  // Admin
  static const String dashboardStats = "$baseUrl/api/admin/dashboard_stats";
  static const String sidpolStats    = "$baseUrl/api/admin/sidpol_stats";
  static const String sidpolPredict  = "$baseUrl/api/admin/sidpol_predict";
}