// lost_object_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import 'fullscreen_image_detail.dart';

class LostObjectDetailPage extends StatelessWidget {
  final LostObject lostObject;

  LostObjectDetailPage({required this.lostObject});

  final Color _primaryColor = Color(0xFF1B396A); // Asegúrate de que coincida con tu color primario

  // Formatear la fecha
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lostObject.tipoObjeto,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Imagen del objeto perdido con GestureDetector
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullscreenImageDialog(
                      imageUrl: lostObject.imagenUrl,
                  ),
                ),
              );
              },
              child: lostObject.imagenUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: lostObject.imagenUrl,
                width: double.infinity,
                height: 250, // Puedes ajustar la altura según prefieras
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red, size: 40),
                ),
              )
                  : Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[700]),
              ),
            ),
            // Datos del objeto perdido
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Ocupa todo el ancho
                children: [
                  Text(
                    lostObject.tipoObjeto,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Descripción:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _primaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    lostObject.descripcion,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Encontrado en:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _primaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    lostObject.lugarEncontrado,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Fecha:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _primaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatDate(lostObject.timestamp),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  // Botón para reclamar objeto
                  ElevatedButton(
                    onPressed: () {
                      // Por ahora, no tiene funcionalidad
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Funcionalidad en desarrollo.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Reclamar objeto',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
