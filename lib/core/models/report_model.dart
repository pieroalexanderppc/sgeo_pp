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
  
  // Nuevos campos
  final String? rangoHorario;
  final String? gravedad;
  final String? fechaCompleta;
  final String? diaSemana;
  final double? precisionGps;
  final String? timestampUtc;

  ReportModel({
    required this.id,
    required this.estado,
    required this.subTipo,
    this.creadoEn,
    this.direccion,
    this.descripcion,
    this.latitud,
    this.longitud,
    this.rangoHorario,
    this.gravedad,
    this.fechaCompleta,
    this.diaSemana,
    this.precisionGps,
    this.timestampUtc,
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
      subTipo: json['subtipo_hecho']?.toString() ?? 'DESCONOCIDO',
      creadoEn: json['creado_en']?.toString(),
      direccion: json['direccion_hecho']?.toString(),
      descripcion: json['descripcion']?.toString(),
      latitud: lat,
      longitud: lng,
      rangoHorario: json['turno_hecho']?.toString(),
      gravedad: json['gravedad']?.toString(),
      fechaCompleta: json['fecha_hora_hecho']?.toString(),
      diaSemana: json['dia_semana']?.toString(),
      precisionGps: (json['precision_gps'] as num?)?.toDouble(),
      timestampUtc: json['timestamp_utc']?.toString(),
    );
  }
}
