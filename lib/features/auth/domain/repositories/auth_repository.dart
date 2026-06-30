import 'package:flutter_backtome/features/auth/domain/entities/sign_in_result.dart';
import 'package:flutter_backtome/features/auth/domain/entities/auth_user.dart';

class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(
    this.message, {
    this.code = '',
  });

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<SignInResult> signIn({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  AuthUser? currentUser();

  Future<void> signOut();
}
