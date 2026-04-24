import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/services/map_service.dart';

class ReportDialog extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String userId;

  const ReportDialog({super.key, required this.latitud, required this.longitud, required this.userId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  // Mapa de opciones amigables -> Valores esperados por el backend
  final Map<String, String> _tiposDelitoMap = {
    'Robo (Asalto con violencia, armas o arrebato)': 'ROBO',
    'Hurto (Sustracción sin violencia, a escondidas)': 'HURTO',
  };

  late String _subTipoSeleccionadoAmigable;
  final TextEditingController _descripcionController = TextEditingController();
  bool _isSubmitting = false;

  String _direccionDetectada = "Buscando dirección...";
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _subTipoSeleccionadoAmigable = _tiposDelitoMap.keys.first;
    _obtenerDireccionFisica();
  }

  Future<void> _obtenerDireccionFisica() async {
    try {
      // Usamos el geocoder público gratuito de OpenStreetMap (Nominatim)
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${widget.latitud}&lon=${widget.longitud}&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'SgeoApp/1.0', // Buena práctica para evitar bloqueos
        'Accept-Language': 'es-PE,es;q=0.9', // Para priorizar nombres en español
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          
          // Extraemos vía, calle o barrio para dar una idea clara (ej: "Av. Los Incas")
          final calle = address['road'] ?? address['pedestrian'] ?? address['neighbourhood']  ?? "Calle desconocida";
          final ciudad = address['city'] ?? address['town'] ?? address['village'] ?? "";
          
          setState(() {
             _direccionDetectada = "$calle ${ciudad.isNotEmpty ? ', $ciudad' : ''}".trim();
             if (_direccionDetectada == "Calle desconocida" && data['display_name'] != null) {
                // Fallback a un pedazo del nombre mostrado
               List<String> partes = data['display_name'].toString().split(',');
               _direccionDetectada = partes.isNotEmpty ? partes[0] : "Dirección aproximada";
             }
             _isLoadingAddress = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }

    // Fallback si falla el servicio
    if (mounted) {
      setState(() {
        _direccionDetectada = "Dirección aproximada (Lat: ${widget.latitud.toStringAsFixed(4)})";
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _enviarReporte() async {
    setState(() { _isSubmitting = true; });

    final datos = {
        "sub_tipo": _tiposDelitoMap[_subTipoSeleccionadoAmigable],
        "latitud": widget.latitud,
        "longitud": widget.longitud,
        "descripcion": _descripcionController.text.trim().isEmpty 
            ? "Reporte ciudadano sin descripción" 
            : _descripcionController.text.trim(),
        "direccion": _direccionDetectada, // Ahora mandamos la dirección de verdad
        "usuario_id": widget.userId,
    };

    try {
      final success = await MapService.crearReporte(datos);
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Cerrar dialogo y devolver 'true' de exito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Reporte enviado exitosamente!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Error del servidor");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el reporte. Intenta de nuevo.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos si el entorno es modo oscuro o claro para asignar colores legibles
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    
    // Contenedor de alerta (Ubicación)
    final alertBgColor = isDark ? const Color(0xFF1E2A38) : Colors.blue.shade50;
    final alertBorderColor = isDark ? Colors.blue.shade800 : Colors.blue.shade200;
    final alertIconColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final alertTextColor = isDark ? Colors.blue.shade100 : Colors.black87;

    return AlertDialog(
      // Márgenes adaptativos para no chocar bruscamente con los bordes de diferentes dispositivos
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 28),
          SizedBox(width: 10),
          Expanded(child: Text('Reportar Incidente', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite, // Método recomendado en Flutter para expandir un dialog al máximo permitido por los insets
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayuda a mejorar la seguridad ciudadana indicando qué ocurrió detalladamente.',
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 16),

              // Tarjeta de ubicación
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: alertBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: alertBorderColor)
                ),
                child: Row(
                  children: [
                     Icon(Icons.location_on, size: 24, color: alertIconColor),
                     const SizedBox(width: 10),
                     Expanded(
                       child: _isLoadingAddress 
                         ? SizedBox(
                             height: 20, 
                             child: Row(
                               children: [
                                 SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: alertIconColor)),
                                 const SizedBox(width: 8),
                                 Text("Obteniendo dirección...", style: TextStyle(fontSize: 13, color: alertTextColor)),
                               ],
                             )
                           )
                         : Text(
                             _direccionDetectada, 
                             style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: alertTextColor)
                           )
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dropdown amigable
              const Text("¿Qué ocurrió?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _subTipoSeleccionadoAmigable,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF333333) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: _tiposDelitoMap.keys.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() { _subTipoSeleccionadoAmigable = val; });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Descripción opcional
              const Text("Detalles (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _descripcionController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ej: Moto lineal negra con 2 sujetos, arrebato de celular...',
                  hintStyle: TextStyle(color: hintColor, fontSize: 13),
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 20, right: 20),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _enviarReporte,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600, 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Botón más grande
            elevation: 0,
          ),
          child: _isSubmitting 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Enviar Reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }
}
