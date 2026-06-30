import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudBackendException implements Exception {
  final String message;

  const SolicitudBackendException(this.message);

  @override
  String toString() => message;
}

class SolicitudBackendService {
  final FirebaseFirestore _firestore;
  final Duration timeout;

  SolicitudBackendService({
    FirebaseFirestore? firestore,
    this.timeout = const Duration(seconds: 45),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> crearSolicitud({
    required String collection,
    required String solicitanteUid,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add({
        'estado': 'pendiente',
        'solicitanteUid': solicitanteUid,
        'payload': payload,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await for (final snapshot in docRef.snapshots().timeout(timeout)) {
        final data = snapshot.data();
        final estado = data?['estado'] as String?;

        if (estado == 'ok') {
          return snapshot;
        }

        if (estado == 'error') {
          throw SolicitudBackendException(
            data?['errorMensaje'] as String? ?? 'La solicitud fallo.',
          );
        }
      }
    } on TimeoutException {
      throw SolicitudBackendException(
        'La solicitud tardo demasiado en responder. Verifica conexion e intenta de nuevo.',
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const SolicitudBackendException(
          'No tienes permiso para enviar o consultar esta solicitud.',
        );
      }

      throw SolicitudBackendException(
        error.message ?? 'No se pudo completar la solicitud (${error.code}).',
      );
    }

    throw const SolicitudBackendException('La solicitud no recibio respuesta.');
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> registrarUsuario({
    required Map<String, dynamic> usuario,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_registro_usuario',
      solicitanteUid: usuario['id'] as String,
      payload: usuario,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> actualizarUsuario({
    required String solicitanteUid,
    required Map<String, dynamic> usuario,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_actualizar_usuario',
      solicitanteUid: solicitanteUid,
      payload: usuario,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> eliminarUsuario({
    required String solicitanteUid,
    required String uid,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_eliminar_usuario',
      solicitanteUid: solicitanteUid,
      payload: {'uid': uid},
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> crearObjetoPerdido({
    required String solicitanteUid,
    required Map<String, dynamic> payload,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_crear_objeto_perdido',
      solicitanteUid: solicitanteUid,
      payload: payload,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> reclamarObjeto({
    required String solicitanteUid,
    required String objetoId,
    required Map<String, dynamic> reclamacion,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_reclamar_objeto',
      solicitanteUid: solicitanteUid,
      payload: {
        'objetoId': objetoId,
        ...reclamacion,
      },
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> aprobarObjeto({
    required String solicitanteUid,
    required String objetoId,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_aprobar_objeto',
      solicitanteUid: solicitanteUid,
      payload: {'objetoId': objetoId},
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> entregarObjeto({
    required String solicitanteUid,
    required String objetoId,
    required String uidReclamante,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_entregar_objeto',
      solicitanteUid: solicitanteUid,
      payload: {
        'objetoId': objetoId,
        'uidReclamante': uidReclamante,
      },
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> rechazarObjeto({
    required String solicitanteUid,
    required String objetoId,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_rechazar_objeto',
      solicitanteUid: solicitanteUid,
      payload: {'objetoId': objetoId},
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> eliminarObjeto({
    required String solicitanteUid,
    required String objetoId,
    required List<String> imageUrls,
  }) {
    return crearSolicitud(
      collection: 'solicitudes_eliminar_objeto',
      solicitanteUid: solicitanteUid,
      payload: {
        'objetoId': objetoId,
        'imageUrls': imageUrls,
      },
    );
  }
}
