import 'package:flutter/material.dart';

class PoliceMapView extends StatelessWidget {
  final String userId;
  const PoliceMapView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Operativo (Policía)'),
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Vista de mapa operativo policial en construcción.\n\nAquí se implementará el mismo mapa que el usuario pero con marcadores que titilan para atención inmediata.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
