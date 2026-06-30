import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_repository.dart';

class DeleteUserUseCase {
  final UserRepository _repository;

  const DeleteUserUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required Usuario user,
  }) {
    return _repository.deleteUser(
      requesterId: requesterId,
      userId: user.id,
    );
  }
}
