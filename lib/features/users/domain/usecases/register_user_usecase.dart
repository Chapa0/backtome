import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_repository.dart';

class RegisterUserUseCase {
  final UserRepository _repository;

  const RegisterUserUseCase(this._repository);

  Future<void> call(Usuario user) {
    return _repository.registerUser(user);
  }
}
