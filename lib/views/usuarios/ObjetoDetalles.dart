import 'package:flutter/material.dart';

class WindowsObjetoDetalles extends StatelessWidget {
  final String imageUrl;
  final String objectName;
  final String objectDescription;
  final String foundDateTime;

  WindowsObjetoDetalles({
    required this.imageUrl,
    required this.objectName,
    required this.objectDescription,
    required this.foundDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.network(
              imageUrl,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 20),
          Text(
            objectName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Descripción:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            objectDescription,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Fecha y hora encontrada:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            foundDateTime,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

