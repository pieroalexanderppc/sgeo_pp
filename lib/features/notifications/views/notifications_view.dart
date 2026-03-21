import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationCard(
            context,
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            title: 'HURTO detectado cerca',
            message: 'A 500m de tu ubicación actual se ha reportado un hurto. Mantente alerta.',
            time: 'Hace 5 min',
          ),
          _buildNotificationCard(
            context,
            icon: Icons.local_police,
            color: Colors.blue,
            title: 'Reporte Confirmado',
            message: 'La policía ha confirmado y está atendiendo el aviso de ROBO en el centro.',
            time: 'Hace 1 hora',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, {required IconData icon, required Color color, required String title, required String message, required String time}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(message),
            const SizedBox(height: 5),
            Text(time, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
