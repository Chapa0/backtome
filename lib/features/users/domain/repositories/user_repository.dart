import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

abstract class UserRepository {
  Stream<Usuario?> watchUser(String userId);

  Future<List<Usuario>> fetchUsers();

  Future<void> registerUser(Usuario user);

  Future<void> updateUser(Usuario user);

  Future<void> deleteUser({
    required String requesterId,
    required String userId,
  });
}
