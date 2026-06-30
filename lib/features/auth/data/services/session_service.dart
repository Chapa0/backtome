import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CurrentUserIdProvider = Future<String?> Function();
typedef RemoteUserProvider = Future<Usuario?> Function(String userId);

class RestoredSession {
  final Usuario? user;
  final String? userRole;

  const RestoredSession({
    required this.user,
    required this.userRole,
  });
}

class SessionService {
  final SharedPreferences _preferences;
  final CurrentUserIdProvider _currentUserIdProvider;
  final RemoteUserProvider _remoteUserProvider;

  SessionService(
    this._preferences, {
    CurrentUserIdProvider? currentUserIdProvider,
    RemoteUserProvider? remoteUserProvider,
  })  : _currentUserIdProvider = currentUserIdProvider ?? _defaultCurrentUserId,
        _remoteUserProvider = remoteUserProvider ?? _defaultRemoteUser;

  Future<RestoredSession> restoreSession() async {
    String? authUserId;
    var authLookupSucceeded = false;

    try {
      authUserId = await _currentUserIdProvider();
      authLookupSucceeded = true;
    } catch (error) {
      print('No se pudo consultar FirebaseAuth al restaurar sesion: $error');
    }

    if (authLookupSucceeded && authUserId == null) {
      await _preferences.remove('userRole');
      await _preferences.remove('userData');
      return const RestoredSession(user: null, userRole: null);
    }

    if (authUserId != null) {
      try {
        final usuario = await _remoteUserProvider(authUserId);
        if (usuario == null) {
          return _restoreCachedSession();
        }
        final userRole = usuario.tipoUsuario == 'admin' ? 'admin' : 'user';
        await _preferences.setString('userRole', userRole);
        await _preferences.setString('userData', json.encode(usuario.toMap()));

        return RestoredSession(
          user: usuario,
          userRole: userRole,
        );
      } catch (error) {
        print('Error al restaurar usuario desde Firestore: $error');
      }
    }

    return _restoreCachedSession();
  }

  RestoredSession _restoreCachedSession() {
    final userRole = _preferences.getString('userRole');
    final usuarioJson = _preferences.getString('userData');
    Usuario? usuario;

    if (usuarioJson != null) {
      final usuarioMap = json.decode(usuarioJson) as Map<String, dynamic>;
      final id = usuarioMap['id'] as String?;
      if (id != null && id.isNotEmpty) {
        usuario = Usuario.fromMap(usuarioMap, id);
      }
    }

    return RestoredSession(
      user: usuario,
      userRole: userRole,
    );
  }

  static Future<String?> _defaultCurrentUserId() async {
    return firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  static Future<Usuario?> _defaultRemoteUser(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();

    if (!userDoc.exists || userDoc.data() == null) {
      return null;
    }

    return Usuario.fromMap(userDoc.data()!, userDoc.id);
  }
}
