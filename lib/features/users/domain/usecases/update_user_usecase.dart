import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_repository.dart';

class UpdateUserUseCase {
  final UserRepository _repository;

  const UpdateUserUseCase(this._repository);

  Future<void> call(Usuario user) {
    return _repository.updateUser(user);
  }
}
