import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/core/firebase/solicitud_backend_service.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object_point.dart';

class LostObjectPointsFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final SolicitudBackendService _backendService;

  LostObjectPointsFirestoreDataSource({
    required FirebaseFirestore firestore,
    required SolicitudBackendService backendService,
  })  : _firestore = firestore,
        _backendService = backendService;

  Stream<List<LostObjectPoint>> watchPoints() {
    return _firestore
        .collection('puntos_objetos_perdidos')
        .orderBy('nombre')
        .snapshots()
        .map(_mapQuery);
  }

  Stream<List<LostObjectPoint>> watchActivePoints() {
    return _firestore
        .collection('puntos_objetos_perdidos')
        .where('activo', isEqualTo: true)
        .orderBy('nombre')
        .snapshots()
        .map(_mapQuery);
  }

  Future<List<LostObjectPoint>> fetchActiveDropOffPoints() async {
    final query = await _firestore
        .collection('puntos_objetos_perdidos')
        .where('activo', isEqualTo: true)
        .get();

    final points = _mapQuery(query)
        .where((point) => point.permiteEntrega)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return points;
  }

  Future<void> savePoint({
    required String requesterId,
    required LostObjectPoint point,
  }) {
    return _backendService.guardarPuntoObjetoPerdido(
      solicitanteUid: requesterId,
      punto: point.toRequestPayload(),
    );
  }

  Future<void> deactivatePoint({
    required String requesterId,
    required String pointId,
  }) {
    return _backendService.eliminarPuntoObjetoPerdido(
      solicitanteUid: requesterId,
      puntoId: pointId,
    );
  }

  List<LostObjectPoint> _mapQuery(QuerySnapshot<Map<String, dynamic>> query) {
    return query.docs
        .map((doc) => LostObjectPoint.fromMap(doc.data(), doc.id))
        .toList();
  }
}
