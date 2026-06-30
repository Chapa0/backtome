import 'dart:convert';

import 'package:flutter_backtome/features/auth/data/datasources/auth_firebase_datasource.dart';
import 'package:flutter_backtome/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_backtome/features/auth/domain/entities/sign_in_result.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDataSource _dataSource;
  final SharedPreferences _preferences;

  AuthRepositoryImpl({
    required AuthFirebaseDataSource dataSource,
    required SharedPreferences preferences,
  })  : _dataSource = dataSource,
        _preferences = preferences;

  @override
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final uid = await _dataSource.signIn(email: email, password: password);
      final user = await _dataSource.fetchUser(uid);

      if (user == null) {
        return const SignInResult(user: null, requiresRegistration: true);
      }

      final userRole = user.tipoUsuario == 'admin' ? 'admin' : 'user';
      await _preferences.setString('userRole', userRole);
      await _preferences.setString('userData', json.encode(user.toMap()));

      return SignInResult(user: user, requiresRegistration: false);
    } on AuthDataException catch (e) {
      throw AuthException(e.message, code: e.code);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } on AuthDataException catch (e) {
      throw AuthException(e.message, code: e.code);
    }
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _dataSource.createUser(email: email, password: password);
    } on AuthDataException catch (e) {
      throw AuthException(e.message, code: e.code);
    }
  }

  @override
  AuthUser? currentUser() {
    return _dataSource.currentUser();
  }

  @override
  Future<void> signOut() {
    return _dataSource.signOut();
  }
}
