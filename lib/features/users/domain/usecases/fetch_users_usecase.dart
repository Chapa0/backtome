import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_repository.dart';

class FetchUsersUseCase {
  final UserRepository _repository;

  const FetchUsersUseCase(this._repository);

  Future<List<Usuario>> call({bool onlyRegularUsers = false}) async {
    final users = await _repository.fetchUsers();

    if (!onlyRegularUsers) {
      return users;
    }

    return users.where((user) => user.tipoUsuario == 'user').toList();
  }
}
