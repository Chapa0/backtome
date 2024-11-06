import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/views/administradorBD/reclamaciones.dart';

class LostObject {
  // Campos existentes
  final String id;
  final String descripcion;
  final String tipoObjeto;
  final String lugarEncontrado;
  final String imagenUrl;
  final String nombreEncontrado;
  final String uidEncontrado;
  final DateTime timestamp;

  // Eliminamos los campos individuales de reclamación
  // String? uidReclamante;
  // String? nombreReclamante;
  String? estadoReclamacion;
  // String? textoReclamacion;
  // String? imagenReclamacionUrl;

  // Añadimos una lista de reclamaciones
  List<Reclamacion> reclamaciones;

  LostObject({
    required this.id,
    required this.descripcion,
    required this.tipoObjeto,
    required this.lugarEncontrado,
    required this.imagenUrl,
    required this.nombreEncontrado,
    required this.uidEncontrado,
    required this.timestamp,
    required this.reclamaciones,
    required this.estadoReclamacion,
  });

  factory LostObject.fromMap(Map<String, dynamic> data, String documentId) {
    // Parseamos la lista de reclamaciones
    List<Reclamacion> reclamaciones = [];
    if (data['reclamaciones'] != null) {
      var list = data['reclamaciones'] as List;
      reclamaciones = list.map((item) => Reclamacion.fromMap(item)).toList();
    }

    return LostObject(
      id: documentId,
      descripcion: data['descripcion'] ?? '',
      tipoObjeto: data['tipoObjeto'] ?? '',
      lugarEncontrado: data['lugarEncontrado'] ?? '',
      imagenUrl: data['imagenUrl'] ?? '',
      nombreEncontrado: data['nombreEncontrado'] ?? '',
      uidEncontrado: data['uidEncontrado'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      reclamaciones: reclamaciones,
      estadoReclamacion: data['estadoReclamacion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'tipoObjeto': tipoObjeto.toLowerCase(),
      'lugarEncontrado': lugarEncontrado,
      'imagenUrl': imagenUrl,
      'nombreEncontrado': nombreEncontrado,
      'uidEncontrado': uidEncontrado,
      'timestamp': timestamp,
      'reclamaciones': reclamaciones.map((reclamacion) => reclamacion.toMap()).toList(),
      'estadoReclamacion': estadoReclamacion,
    };
  }
}
