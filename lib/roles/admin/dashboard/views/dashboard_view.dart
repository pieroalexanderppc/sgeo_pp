import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard de SGEO'), centerTitle: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 100, color: Colors.blueGrey),
            SizedBox(height: 20),
            Text(
              'Estadísticas y Análisis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Aquí incorporaremos el paquete fl_chart para mostrar gráficas del BigData:\nTortas de delitos recurrentes y picos de mapas de calor.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
