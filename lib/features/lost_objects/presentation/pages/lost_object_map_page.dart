import 'package:flutter/material.dart';

class LostObjectMapPage extends StatelessWidget {
  final double latitud;
  final double longitud;

  const LostObjectMapPage({
    super.key,
    required this.latitud,
    required this.longitud,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicacion del Objeto Perdido',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B396A),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ubicacion: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aproximadamente donde se encontro el objeto perdido.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
