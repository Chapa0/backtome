import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class SignInResult {
  final Usuario? user;
  final bool requiresRegistration;

  const SignInResult({
    required this.user,
    required this.requiresRegistration,
  });
}
