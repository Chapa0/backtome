import 'package:flutter_backtome/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';

class CreateAuthUserUseCase {
  final AuthRepository _repository;

  const CreateAuthUserUseCase(this._repository);

  Future<AuthUser> call({
    required String email,
    required String password,
  }) {
    return _repository.createUser(email: email, password: password);
  }
}
