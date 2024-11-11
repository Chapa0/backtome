// lost_object.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/views/administradorBD/reclamacionesBD.dart';

class LostObject {
  // Campos existentes
  final String id;
  final String descripcion;
  final String tipoObjeto;
  final String tipoOBjetoBusqueda;
  final String lugarEncontrado;
  final String imagenUrl;
  final String nombreEncontrado;
  final String uidEncontrado;
  final DateTime timestamp;
  List<String>? imageUrls;

  // Otros campos
  String? estadoReclamacion;

  // Lista de reclamaciones
  List<Reclamacion> reclamaciones;

  // Nuevo campo para la ubicación del mapa
  final Map<String, double>? mapLocation; // {'x': valor, 'y': valor}

  LostObject({
    required this.id,
    required this.descripcion,
    required this.tipoObjeto,
    required this.tipoOBjetoBusqueda,
    required this.lugarEncontrado,
    required this.imagenUrl,
    required this.nombreEncontrado,
    required this.uidEncontrado,
    required this.timestamp,
    required this.imageUrls,
    required this.reclamaciones,
    required this.estadoReclamacion,
    this.mapLocation, // Nuevo campo añadido
  });

  factory LostObject.fromMap(Map<String, dynamic> data, String documentId) {
    // Parsear la lista de reclamaciones
    List<Reclamacion> reclamaciones = [];
    if (data['reclamaciones'] != null) {
      var list = data['reclamaciones'] as List;
      reclamaciones = list.map((item) => Reclamacion.fromMap(item)).toList();
    }

    // Parsear la ubicación del mapa
    Map<String, double>? mapLocation;
    if (data['mapLocation'] != null) {
      mapLocation = {
        'x': (data['mapLocation']['x'] as num).toDouble(),
        'y': (data['mapLocation']['y'] as num).toDouble(),
      };
    }

    return LostObject(
      id: documentId,
      descripcion: data['descripcion'] ?? '',
      tipoObjeto: data['tipoObjeto'] ?? '',
      tipoOBjetoBusqueda: data['tipoObjetoBusqueda'] ?? '',
      lugarEncontrado: data['lugarEncontrado'] ?? '',
      imagenUrl: data['imagenUrl'] ?? '',
      nombreEncontrado: data['nombreEncontrado'] ?? '',
      uidEncontrado: data['uidEncontrado'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [],
      reclamaciones: reclamaciones,
      estadoReclamacion: data['estadoReclamacion'] ?? '',
      mapLocation: mapLocation, // Asignar la ubicación del mapa
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'tipoObjeto': tipoObjeto,
      'tipoObjetoBusqueda': tipoOBjetoBusqueda,
      'lugarEncontrado': lugarEncontrado,
      'imagenUrl': imagenUrl,
      'nombreEncontrado': nombreEncontrado,
      'uidEncontrado': uidEncontrado,
      'timestamp': timestamp,
      'imageUrls': imageUrls,
      'reclamaciones': reclamaciones.map((reclamacion) => reclamacion.toMap()).toList(),
      'estadoReclamacion': estadoReclamacion,
      'mapLocation': mapLocation, // Incluir la ubicación del mapa
    };
  }
}
