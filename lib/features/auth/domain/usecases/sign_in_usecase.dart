import 'package:flutter_backtome/features/auth/domain/entities/sign_in_result.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<SignInResult> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
