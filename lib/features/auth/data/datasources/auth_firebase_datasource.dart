import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_backtome/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class AuthDataException implements Exception {
  final String message;
  final String code;

  const AuthDataException(
    this.message, {
    this.code = '',
  });

  @override
  String toString() => message;
}

class AuthFirebaseDataSource {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthFirebaseDataSource({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw const AuthDataException('No se pudo identificar al usuario.');
      }
      return uid;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthDataException(_mapAuthMessage(e.code), code: e.code);
    }
  }

  Future<Usuario?> fetchUser(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Usuario.fromMap(doc.data()!, doc.id);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthDataException(_mapAuthMessage(e.code), code: e.code);
    }
  }

  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null || user.uid.isEmpty) {
        throw const AuthDataException('No se pudo crear el usuario.');
      }
      return AuthUser(id: user.uid, email: user.email ?? email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthDataException(_mapAuthMessage(e.code), code: e.code);
    }
  }

  AuthUser? currentUser() {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      return null;
    }
    return AuthUser(id: user.uid, email: user.email ?? '');
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  String _mapAuthMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El correo electronico ya esta en uso.';
      case 'invalid-email':
        return 'Correo invalido. Por favor, verifica el formato.';
      case 'weak-password':
        return 'La contrasena es demasiado debil.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contrasena incorrecta. Intentalo de nuevo.';
      case 'invalid-credential':
        return 'Correo o contrasena incorrectos. Verifica los datos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, intenta mas tarde.';
      case 'operation-not-allowed':
        return 'El registro con correo/contrasena no esta habilitado en Firebase.';
      case 'network-request-failed':
        return 'Error de conexion. Verifica tu internet e intenta de nuevo.';
      default:
        return 'Error de autenticacion. Por favor, intenta de nuevo. ($code)';
    }
  }
}
