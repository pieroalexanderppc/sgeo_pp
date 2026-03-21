import 'package:flutter/material.dart';
import '../../../../core/services/map_service.dart';

class ReportDialog extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String userId;

  const ReportDialog({super.key, required this.latitud, required this.longitud, required this.userId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _subTipoSeleccionado = 'HURTO'; // Valor default
  String _relacionSeleccionada = 'Fui testigo presencial'; 
  final TextEditingController _descripcionController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _tiposDelito = ['HURTO', 'ROBO', 'EXTORSION'];
  final List<String> _tiposRelacion = ['Fui testigo presencial', 'Familiar / Conocido']; 

  Future<void> _enviarReporte() async {
    setState(() { _isSubmitting = true; });

    final datos = {
        "sub_tipo": _subTipoSeleccionado,
        "latitud": widget.latitud,
        "longitud": widget.longitud,
        "descripcion": _descripcionController.text,
        "direccion": "", // Ya no necesitamos enviarla por form si va implícito en coord
        "relacion_incidente": _relacionSeleccionada,
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
    return AlertDialog(
      title: const Text('🚨 Reportar Incidente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Está a punto de enviar una alerta ciudadana. Por favor, indique el tipo de incidente:'),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _subTipoSeleccionado,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo de Incidente', border: OutlineInputBorder()),
              items: _tiposDelito.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _subTipoSeleccionado = val!;
                });
              },
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _relacionSeleccionada,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '¿Quién reporta?', border: OutlineInputBorder()),
              items: _tiposRelacion.map((relacion) {
                return DropdownMenuItem(value: relacion, child: Text(relacion));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _relacionSeleccionada = val!;
                });
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción detallada',
                hintText: 'Ej: Me arrebataron el celular en la esquina...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _enviarReporte,
          icon: _isSubmitting 
              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send),
          label: const Text('Enviar Reporte'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
