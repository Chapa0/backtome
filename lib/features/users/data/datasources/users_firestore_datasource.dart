import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/core/firebase/solicitud_backend_service.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class UsersFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final SolicitudBackendService _backendService;

  UsersFirestoreDataSource({
    required FirebaseFirestore firestore,
    required SolicitudBackendService backendService,
  })  : _firestore = firestore,
        _backendService = backendService;

  Stream<Usuario?> watchUser(String userId) {
    return _firestore.collection('usuarios').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }

      return Usuario.fromMap(data, doc.id);
    });
  }

  Future<List<Usuario>> fetchUsers() async {
    final query = await _firestore.collection('usuarios').get();
    return query.docs
        .map((doc) => Usuario.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> registerUser(Usuario user) async {
    await _backendService.registrarUsuario(usuario: user.toMap());
  }

  Future<void> updateUser(Usuario user) async {
    await _backendService.actualizarUsuario(
      solicitanteUid: user.id,
      usuario: user.toMap(),
    );
  }

  Future<void> deleteUser({
    required String requesterId,
    required String userId,
  }) {
    return _backendService.eliminarUsuario(
      solicitanteUid: requesterId,
      uid: userId,
    );
  }
}
