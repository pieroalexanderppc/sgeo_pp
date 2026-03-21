import 'package:flutter/material.dart';

class MyReportsView extends StatelessWidget {
  const MyReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Número de reportes de ejemplo
        itemBuilder: (context, index) {
          final isConfirmed = index % 2 == 0;
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                isConfirmed ? Icons.check_circle : Icons.pending_actions,
                color: isConfirmed ? Colors.green : Colors.orange,
                size: 32,
              ),
              title: Text('Reporte #${index + 1} - ${isConfirmed ? 'Confirmado' : 'Pendiente'}'),
              subtitle: Text('Fecha: 12/10/2023\nDirección: Calle Falsa 123, Ciudad'),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Detalles del reporte
              },
            ),
          );
        },
      ),
    );
  }
}

