// Se actualiza el manejo de respuesta de crearReporte para mostrar el mensaje especifico del backend (incluye limite diario).
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui' as dart_ui;
import 'package:http/http.dart' as http;
import '../../../../../core/services/map_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/safety_button.dart';

class ReportDialog extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String userId;

  const ReportDialog({super.key, required this.latitud, required this.longitud, required this.userId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  // Mapa de opciones tácticas -> Valores esperados por el backend (SIDPOL Compatible)
  final Map<String, String> _tiposDelitoMap = {
    'Robo (Asalto con violencia / amenaza)': 'ROBO',
    'Hurto (Sustracción sin violencia)': 'HURTO',
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
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${widget.latitud}&lon=${widget.longitud}&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'SgeoApp/1.0',
        'Accept-Language': 'es-PE,es;q=0.9',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          
          final calle = address['road'] ?? address['pedestrian'] ?? address['neighbourhood']  ?? "Calle desconocida";
          final ciudad = address['city'] ?? address['town'] ?? address['village'] ?? "";
          
          setState(() {
             _direccionDetectada = "$calle ${ciudad.isNotEmpty ? ', $ciudad' : ''}".trim();
             if (_direccionDetectada == "Calle desconocida" && data['display_name'] != null) {
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

    if (mounted) {
      setState(() {
        _direccionDetectada = "Dirección aproximada (Lat: ${widget.latitud.toStringAsFixed(4)})";
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _enviarReporte() async {
    setState(() { _isSubmitting = true; });

    final now = DateTime.now();
    final offsetHours = now.timeZoneOffset.inHours;
    final offsetStr = '${offsetHours < 0 ? '-' : '+'}${offsetHours.abs().toString().padLeft(2, '0')}:00';

    final datos = {
        "subtipo_hecho": _tiposDelitoMap[_subTipoSeleccionadoAmigable],
        "latitud": widget.latitud,
        "longitud": widget.longitud,
        "descripcion": _descripcionController.text.trim(),
        "direccion_hecho": _direccionDetectada,
        "usuario_id": widget.userId,
        
        // --- Nuevos campos estrictos (QA & ML Ready) ---
        "distrito_hecho": "TACNA",
        "provincia_hecho": "TACNA",
        "departamento_hecho": "TACNA",
        "precision_gps": 10.0,
        "fuente": "CIUDADANO_APP",
        "gravedad": "MEDIA",
        "device_timestamp": now.toIso8601String(),
        "timezone": "America/Lima",
        "metadata_contextual": {
            "plataforma": "Flutter App",
            "version": "1.0.0",
            "tipo_conexion": "Desconocido",
            "offset_local": offsetStr
        },
    };

    final resultado = await MapService.crearReporte(datos);

    if (mounted) {
      if (resultado['success'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('¡Reporte enviado exitosamente!'), backgroundColor: AppTheme.successGreen),
        );
      } else {
        final mensaje = resultado['message'] ?? 'Error al enviar el reporte. Intenta de nuevo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: AppTheme.alertRed),
        );
      }
    }

    if (mounted) {
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertBgColor = isDark ? AppTheme.alertRed.withValues(alpha: 0.1) : Colors.red.shade50;
    final alertBorderColor = isDark ? AppTheme.alertRed.withValues(alpha: 0.3) : Colors.red.shade200;
    
    return Dialog(
      backgroundColor: Colors.transparent, // Fondo manejado por el Container interno
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: AppTheme.borderTactical.withValues(alpha: 0.5), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // --- HEADER DE ALERTA ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgDeep.withValues(alpha: 0.5) : Colors.grey.shade50.withValues(alpha: 0.5),
                border: Border(bottom: BorderSide(color: isDark ? AppTheme.borderSubtle : Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.alertRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.campaign_rounded, color: AppTheme.alertRed, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reportar Incidente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.textPrimary : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // --- CUERPO ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalla el incidente de forma breve y precisa. Esta información se integrará directamente al motor predictivo.',
                      style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta de ubicación (estilo táctico)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: alertBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: alertBorderColor)
                      ),
                      child: Row(
                        children: [
                           Icon(Icons.location_on, size: 20, color: AppTheme.alertRed),
                           const SizedBox(width: 12),
                           Expanded(
                             child: _isLoadingAddress 
                               ? Row(
                                   children: [
                                     SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.alertRed)),
                                     const SizedBox(width: 10),
                                     Text("Detectando...", style: TextStyle(fontSize: 13, color: AppTheme.alertRed)),
                                   ],
                                 )
                               : Text(
                                   _direccionDetectada, 
                                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textPrimary : Colors.red.shade900),
                                   maxLines: 2,
                                   overflow: TextOverflow.ellipsis,
                                 )
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Títulos tácticos (uppercase, small, spaced)
                    Text(
                      "TIPO DE INCIDENTE", 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        fontSize: 11, 
                        letterSpacing: 1.2, 
                        color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue
                      )
                    ),
                    const SizedBox(height: 8),
                    
                    // Dropdown estilizado por el Theme global
                    DropdownButtonFormField<String>(
                      initialValue: _subTipoSeleccionadoAmigable,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      dropdownColor: isDark ? AppTheme.bgElevated : Colors.white,
                      items: _tiposDelitoMap.keys.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo, 
                          child: Text(tipo, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() { _subTipoSeleccionadoAmigable = val; });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "DETALLES (OPCIONAL)", 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        fontSize: 11, 
                        letterSpacing: 1.2, 
                        color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue
                      )
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descripcionController,
                      style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textPrimary : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Ej: Moto lineal negra, 2 sujetos armados...',
                        hintStyle: TextStyle(color: isDark ? AppTheme.textSecondary.withValues(alpha: 0.5) : Colors.grey.shade400),
                        filled: true,
                        fillColor: isDark ? AppTheme.bgDeep : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppTheme.borderTactical : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppTheme.borderTactical : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accentBlue),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),

            // --- ACCIONES ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SafetyButton.outline(
                    label: 'CANCELAR',
                    expand: false,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SafetyButton.danger(
                      label: 'ENVIAR ALERTA',
                      icon: Icons.send_rounded,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _enviarReporte,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
