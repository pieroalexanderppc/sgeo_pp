import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MyReportsView extends StatefulWidget {
  final String userId;
  const MyReportsView({super.key, required this.userId});

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://sgeo-backend-production.up.railway.app/api/reportes/mis_reportes/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _reports = data['reportes'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    }
    setState(() {
      _reports = [];
      _isLoading = false;
    });
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
                    final isPending = report['estado'] == 'pendiente';
                    final dateStr = report['creado_en'];
                    DateTime? date;
                    if (dateStr != null) {
                      try {
                        date = DateTime.parse(dateStr).toLocal();
                      } catch (e) {
                        debugPrint('Error parseando fecha: $e');
                      }
                    }
                    final formattedDate = date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : 'Fecha desconocida';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isPending ? Icons.pending_actions : Icons.check_circle,
                          color: isPending ? Colors.orange : Colors.green,
                          size: 32,
                        ),
                        title: Text('${report['sub_tipo']} - ${report['estado'].toString().toUpperCase()}'),
                        subtitle: Text('Fecha: $formattedDate\nDirección: ${report['direccion'] ?? 'No especificada'}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Aquí podrías abrir detalles del reporte si quieres
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
