/// Representa la estructura de un reporte de incidente creado por el ciudadano.
class ReportModel {
  final String id;
  final String estado;
  final String subTipo;
  final String? creadoEn;
  final String? direccion;
  final String? descripcion;
  final double? latitud;
  final double? longitud;

  ReportModel({
    required this.id,
    required this.estado,
    required this.subTipo,
    this.creadoEn,
    this.direccion,
    this.descripcion,
    this.latitud,
    this.longitud,
  });

  /// Transforma el JSON del servidor (Map dinámico) a un Objeto Dart tipado.
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;

    if (json['ubicacion'] != null && json['ubicacion']['coordinates'] != null) {
      try {
        final coords = json['ubicacion']['coordinates'];
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      } catch (e) {
        // Ignorar o manejar error de coordenadas
      }
    }

    return ReportModel(
      id: json['_id']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'desconocido',
      subTipo: json['sub_tipo']?.toString() ?? 'DESCONOCIDO',
      creadoEn: json['creado_en']?.toString(),
      direccion: json['direccion']?.toString(),
      descripcion: json['descripcion']?.toString(),
      latitud: lat,
      longitud: lng,
    );
  }
}
