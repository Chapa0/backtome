// models/lost_object.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LostObject {
  final String id;
  final String descripcion;
  final String tipoObjeto;
  final String lugarEncontrado;
  final String imagenUrl;
  final String nombreEncontrado;
  final String uidEncontrado;
  final DateTime timestamp;

  LostObject({
    required this.id,
    required this.descripcion,
    required this.tipoObjeto,
    required this.lugarEncontrado,
    required this.imagenUrl,
    required this.nombreEncontrado,
    required this.uidEncontrado,
    required this.timestamp,
  });

  factory LostObject.fromMap(Map<String, dynamic> data, String documentId) {
    return LostObject(
      id: documentId,
      descripcion: data['descripcion'] ?? '',
      tipoObjeto: data['tipoObjeto'] ?? '',
      lugarEncontrado: data['lugarEncontrado'] ?? '',
      imagenUrl: data['imagenUrl'] ?? '',
      nombreEncontrado: data['nombreEncontrado'] ?? '',
      uidEncontrado: data['uidEncontrado'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
