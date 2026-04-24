import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ValidationsView extends StatefulWidget {
  final String userId;
  final Function(LatLng)? onNavigateToMap;
  
  const ValidationsView({super.key, required this.userId, this.onNavigateToMap});

  @override
  State<ValidationsView> createState() => _ValidationsViewState();
}

class _ValidationsViewState extends State<ValidationsView> {
  bool _isLoading = true;
  List<dynamic> _pendingReports = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingReports();
  }

  Future<void> _fetchPendingReports() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/reportes/policia',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          final allPending = (data['reportes'] as List)
              .where((r) => r['estado'].toString().toLowerCase() == 'pendiente')
              .toList();

          // Agrupación visual en la UI (500 metros)
          List<dynamic> grouped = [];
          for (var report in allPending) {
            bool added = false;
            for (var group in grouped) {
              if (group['sub_tipo'] == report['sub_tipo']) {
                try {
                  final c1 = report['ubicacion']['coordinates'];
                  final c2 = group['ubicacion']['coordinates'];
                  final distance = Geolocator.distanceBetween(
                    c1[1] as double, c1[0] as double,
                    c2[1] as double, c2[0] as double,
                  );
                  if (distance <= 500) {
                    group['cantidad_agrupada'] = (group['cantidad_agrupada'] ?? 1) + 1;
                    if (group['agrupados_list'] == null) {
                      group['agrupados_list'] = [Map.from(group)]; // Add self to list if first time
                    }
                    group['agrupados_list'].add(report);
                    added = true;
                    break;
                  }
                } catch (_) {}
              }
            }
            if (!added) {
              report['cantidad_agrupada'] = 1;
              
              // Evitar referencia circular copiando el mapa limpiamente
              final cleanReport = Map<String, dynamic>.from(report);
              report['agrupados_list'] = [cleanReport]; 
              
              grouped.add(report);
            }
          }

          setState(() {
            _pendingReports = grouped;
          });
        }
      }
    } catch (e) {
      debugPrint('Error listando reportes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String reportId, String newStatus) async {
    try {
      final endpoint = newStatus == 'VALIDADO' 
        ? '/api/reportes/confirmar/$reportId' 
        : '/api/reportes/rechazar/$reportId';
        
      final res = await http.post(
        Uri.parse('https://sgeo-backend-production.up.railway.app$endpoint'),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte $newStatus exitosamente')),
        );
        _fetchPendingReports();
      }
    } catch (_) {}
  }

  void _showGroupDetails(BuildContext context, List<dynamic> group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${group.length} Reportes Agrupados'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: group.length,
            itemBuilder: (context, index) {
              final rep = group[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(rep['direccion'] ?? 'GPS desconocido'),
                subtitle: Text('Fecha: ${rep['fecha_hecho']?.toString().split("T").first ?? "Desconocida"}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría de Incidentes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingReports,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPendingReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingReports.isEmpty
            ? ListView(
                children: const [
                  SizedBox(
                    height: 500,
                    child: Center(
                      child: Text(
                        'No hay incidentes pendientes por validar. ¡Buen trabajo!',
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _pendingReports.length,
                itemBuilder: (ctx, i) {
                  final req = _pendingReports[i];
                  final int count = req['cantidad_agrupada'] ?? 1;
                  final String subTipo = req['sub_tipo'] ?? 'Incidente';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.warning, color: Colors.white),
                      ),
                      title: Text(
                        count > 1 ? '$subTipo ($count agrupaciones)' : subTipo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        req['direccion'] ?? 'Ubicación GPS desconocida',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (count > 1)
                            IconButton(
                              icon: const Icon(Icons.list_alt, color: Colors.white70, size: 28),
                              onPressed: () {
                                _showGroupDetails(context, req['agrupados_list'] ?? []);
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.map,
                              color: Colors.blue,
                              size: 28,
                            ),
                            onPressed: () {
                              final coords = req['ubicacion']['coordinates'];
                              final lng = coords[0] as double;
                              final lat = coords[1] as double;
                              if (widget.onNavigateToMap != null) {
                                widget.onNavigateToMap!(LatLng(lat, lng));
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                            onPressed: () =>
                                _updateStatus(req['_id'].toString(), 'VALIDADO'),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 28,
                            ),
                            onPressed: () => _updateStatus(
                              req['_id'].toString(),
                              'RECHAZADO',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
