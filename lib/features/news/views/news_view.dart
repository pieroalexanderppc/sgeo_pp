import 'package:flutter/material.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNewsCard(
            context,
            title: 'Desarticulan banda en el distrito Alto de la Alianza',
            description: 'La policía nacional ha logrado detener a 3 individuos con objetos reportados en la app.',
            date: '20 Mar 2026',
          ),
          _buildNewsCard(
            context,
            title: 'Nuevas cámaras de seguridad instaladas en el Centro',
            description: 'La municipalidad ha instalado nuevas cámaras en zonas reportadas como de alto riesgo.',
            date: '18 Mar 2026',
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, {required String title, required String description, required String date}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.newspaper, color: Colors.blue),
                Text(date, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Leer más'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
