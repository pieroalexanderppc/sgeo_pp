import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/models/report_model.dart';
import '../../../../core/services/report_service.dart';

class MyReportsView extends StatefulWidget {
  final String userId;
  final Function(LatLng) onNavigateToMap; 
  
  const MyReportsView({super.key, required this.userId, required this.onNavigateToMap});

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    setState(() => _isLoading = true);
    
    final reports = await ReportService.getMyReports(widget.userId);
    
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text('¿Estás seguro de que deseas eliminar permanentemente este reporte? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminando reporte...')));
    }

    final success = await ReportService.deleteReport(report.id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte eliminado con éxito.'), backgroundColor: Colors.green));
        _fetchMyReports(); // Reload list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hubo un error al eliminar el reporte.'), backgroundColor: Colors.red));
      }
    }
  }

  void _showMapPreview(ReportModel report) {
    if (report.latitud == null || report.longitud == null) return;
    final latLng = LatLng(report.latitud!, report.longitud!);
    
    // Navegamos usando la función que viene desde HomeView hacia el mapa original
    widget.onNavigateToMap(latLng);
  }

  void _showReportDetails(BuildContext context, ReportModel report, String formattedDate, String direccionStr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = report.estado.toLowerCase() == 'pendiente';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Head
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.subTipo,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.estado.toUpperCase(),
                      style: TextStyle(
                        color: isPending ? Colors.orange.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 10),
                  Text(formattedDate, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(child: Text(direccionStr, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.descripcion != null && report.descripcion!.isNotEmpty 
                          ? report.descripcion! 
                          : "Sin descripción", 
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontStyle: report.descripcion == null ? FontStyle.italic : FontStyle.normal)
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Ver zona en el Mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showMapPreview(report);
                  },
                ),
              ),
              
              if (isPending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar Mi Reporte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteReport(report);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20), // Bottom safe space
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyReports,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text('No has realizado ningún reporte aún.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final isPending = report.estado.toLowerCase() == 'pendiente';
                    
                    DateTime? date;
                    if (report.creadoEn != null) {
                      try {
                        date = DateTime.parse(report.creadoEn!).toLocal();
                      } catch (e) {
                        debugPrint('Error parseando fecha: $e');
                      }
                    }
                    final formattedDate = date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : 'Fecha desconocida';

                    String direccionStr = report.direccion ?? '';
                    if (direccionStr.trim().isEmpty) {
                      if (report.latitud != null && report.longitud != null) {
                        final lat = report.latitud!.toStringAsFixed(5);
                        final lng = report.longitud!.toStringAsFixed(5);
                        direccionStr = 'GPS: Lat $lat, Lng $lng';
                      } else {
                        direccionStr = 'Ubicación por mapa';
                      }
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showReportDetails(context, report, formattedDate, direccionStr),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: ListTile(
                            leading: Icon(
                              isPending ? Icons.access_time_filled : Icons.check_circle,
                              color: isPending ? Colors.orange : Colors.green,
                              size: 32,
                            ),
                            title: Text(
                              report.subTipo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                '$direccionStr\n$formattedDate',
                                style: const TextStyle(height: 1.4),
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  report.estado.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
