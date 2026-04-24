import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ValidationsView extends StatefulWidget {
  final String userId;
  const ValidationsView({super.key, required this.userId});

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
          'https://sgeo-backend-production.up.railway.app/api/reportes',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _pendingReports = (data['reportes'] as List)
                .where((r) => r['estado'] == 'PENDIENTE')
                .toList();
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
      final res = await http.put(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/reportes/$reportId/estado',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'estado': newStatus}),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte $newStatus exitosamente')),
        );
        _fetchPendingReports();
      }
    } catch (_) {}
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
                        req['sub_tipo'] ?? 'Incidente reportado',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        req['direccion'] ?? 'Ubicación GPS desconocida',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 30,
                            ),
                            onPressed: () =>
                                _updateStatus(req['id'].toString(), 'VALIDADO'),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 30,
                            ),
                            onPressed: () => _updateStatus(
                              req['id'].toString(),
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
