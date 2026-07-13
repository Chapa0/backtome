import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/core/firebase/solicitud_backend_service.dart';
import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object_point.dart';

class LostObjectsFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final SolicitudBackendService _backendService;

  LostObjectsFirestoreDataSource({
    required FirebaseFirestore firestore,
    required SolicitudBackendService backendService,
  })  : _firestore = firestore,
        _backendService = backendService;

  Stream<List<LostObject>> watchLostObjects() {
    return _firestore
        .collection('objetos_perdidos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_mapQuery);
  }

  Stream<List<LostObject>> watchApprovedLostObjects() {
    return _firestore
        .collection('objetos_perdidos')
        .where('aprobado', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_mapQuery);
  }

  Stream<List<LostObject>> watchVisibleLostObjects({
    required bool isAdmin,
    String? userId,
  }) {
    if (isAdmin) return watchLostObjects();

    final approvedStream = _firestore
        .collection('objetos_perdidos')
        .where('aprobado', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_mapQuery);

    if (userId == null || userId.isEmpty) return approvedStream;

    final ownPendingStream = _firestore
        .collection('objetos_perdidos')
        .where('uidEncontrado', isEqualTo: userId)
        .where('aprobado', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_mapQuery);

    late final StreamController<List<LostObject>> controller;
    StreamSubscription<List<LostObject>>? approvedSubscription;
    StreamSubscription<List<LostObject>>? ownPendingSubscription;
    List<LostObject>? approvedObjects;
    List<LostObject>? ownPendingObjects;

    void emitMergedObjects() {
      if (approvedObjects == null || ownPendingObjects == null) return;

      final objectsById = <String, LostObject>{
        for (final object in approvedObjects!) object.id: object,
        for (final object in ownPendingObjects!) object.id: object,
      };
      final mergedObjects = objectsById.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      controller.add(mergedObjects);
    }

    controller = StreamController<List<LostObject>>(
      onListen: () {
        approvedSubscription = approvedStream.listen(
          (objects) {
            approvedObjects = objects;
            emitMergedObjects();
          },
          onError: controller.addError,
        );
        ownPendingSubscription = ownPendingStream.listen(
          (objects) {
            ownPendingObjects = objects;
            emitMergedObjects();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await approvedSubscription?.cancel();
        await ownPendingSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<List<LostObject>> fetchLostObjects() async {
    final query = await _firestore
        .collection('objetos_perdidos')
        .orderBy('timestamp', descending: true)
        .get();

    return _mapQuery(query);
  }

  Future<List<LostObject>> fetchLostObjectsByOwner(String userId) async {
    final query = await _firestore
        .collection('objetos_perdidos')
        .where('uidEncontrado', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return _mapQuery(query);
  }

  Future<List<LostObject>> fetchClaimedLostObjects(String userId) async {
    final query = await _firestore
        .collection('objetos_perdidos')
        .where('reclamacionesUids', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return _mapQuery(query);
  }

  Future<List<LostObject>> fetchVisibleLostObjects({
    required bool isAdmin,
    String? userId,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    late List<LostObject> objects;
    if (isAdmin) {
      try {
        objects = await fetchLostObjects();
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') {
          rethrow;
        }
        objects = await _fetchObjectsVisibleToUser(userId);
      }
    } else {
      objects = await _fetchObjectsVisibleToUser(userId);
    }

    final normalizedSearch = searchQuery.trim().toLowerCase();
    final filtered = objects.where((object) {
      final matchesSearch = normalizedSearch.isEmpty ||
          object.tipoObjeto.toLowerCase().contains(normalizedSearch) ||
          object.descripcion.toLowerCase().contains(normalizedSearch);
      final matchesDate = _isInDateRange(object.timestamp, startDate, endDate);
      return matchesSearch && matchesDate;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  Future<void> deleteLostObject({
    required String requesterId,
    required String objectId,
    required List<String> imageUrls,
  }) {
    return _backendService.eliminarObjeto(
      solicitanteUid: requesterId,
      objetoId: objectId,
      imageUrls: imageUrls,
    );
  }

  Future<void> createLostObject({
    required String requesterId,
    required String description,
    required String objectType,
    required String foundPlace,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
  }) {
    return _backendService.crearObjetoPerdido(
      solicitanteUid: requesterId,
      payload: {
        'descripcion': description,
        'tipoObjeto': objectType,
        'tipoObjetoBusqueda': objectType.toLowerCase(),
        'lugarEncontrado': foundPlace,
        'imageUrls': imageUrls,
        if (latitude != null) 'latitud': latitude,
        if (longitude != null) 'longitud': longitude,
      },
    );
  }

  Future<void> claimLostObject({
    required String requesterId,
    required String objectId,
    required Reclamacion claim,
  }) {
    return _backendService.reclamarObjeto(
      solicitanteUid: requesterId,
      objetoId: objectId,
      reclamacion: claim.toMap(),
    );
  }

  Future<void> approveLostObject({
    required String requesterId,
    required String objectId,
    LostObjectPoint? custodyPoint,
  }) {
    return _backendService.aprobarObjeto(
      solicitanteUid: requesterId,
      objetoId: objectId,
      puntoCustodiaId: custodyPoint?.id,
    );
  }

  Future<void> rejectLostObject({
    required String requesterId,
    required String objectId,
  }) {
    return _backendService.rechazarObjeto(
      solicitanteUid: requesterId,
      objetoId: objectId,
    );
  }

  Future<void> deliverLostObject({
    required String requesterId,
    required String objectId,
    required String claimantId,
  }) {
    return _backendService.entregarObjeto(
      solicitanteUid: requesterId,
      objetoId: objectId,
      uidReclamante: claimantId,
    );
  }

  Future<void> receiveLostObjectAtPoint({
    required String requesterId,
    required String objectId,
    required LostObjectPoint custodyPoint,
  }) {
    return _backendService.recibirObjetoEnPunto(
      solicitanteUid: requesterId,
      objetoId: objectId,
      puntoCustodiaId: custodyPoint.id,
    );
  }

  Future<List<LostObject>> _fetchObjectsVisibleToUser(String? userId) async {
    final approvedQuery = _firestore
        .collection('objetos_perdidos')
        .where('aprobado', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();

    if (userId == null || userId.isEmpty) {
      return _mapQuery(await approvedQuery);
    }

    final ownQuery = _firestore
        .collection('objetos_perdidos')
        .where('uidEncontrado', isEqualTo: userId)
        .where('aprobado', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .get();

    final results = await Future.wait([approvedQuery, ownQuery]);
    final byId = <String, LostObject>{};
    for (final object in _mapQuery(results[0])) {
      byId[object.id] = object;
    }
    for (final object in _mapQuery(results[1])) {
      byId[object.id] = object;
    }
    return byId.values.toList();
  }

  bool _isInDateRange(
    DateTime timestamp,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null || endDate == null) {
      return true;
    }
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );
    return !timestamp.isBefore(start) && !timestamp.isAfter(end);
  }

  List<LostObject> _mapQuery(QuerySnapshot<Map<String, dynamic>> query) {
    return query.docs
        .map((doc) => LostObject.fromMap(doc.data(), doc.id))
        .toList();
  }
}
