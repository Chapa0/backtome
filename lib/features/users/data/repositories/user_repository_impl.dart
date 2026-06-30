import 'package:flutter_backtome/features/users/data/datasources/users_firestore_datasource.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UsersFirestoreDataSource _dataSource;

  UserRepositoryImpl({
    required UsersFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Stream<Usuario?> watchUser(String userId) => _dataSource.watchUser(userId);

  @override
  Future<List<Usuario>> fetchUsers() => _dataSource.fetchUsers();

  @override
  Future<void> registerUser(Usuario user) => _dataSource.registerUser(user);

  @override
  Future<void> updateUser(Usuario user) => _dataSource.updateUser(user);

  @override
  Future<void> deleteUser({
    required String requesterId,
    required String userId,
  }) {
    return _dataSource.deleteUser(
      requesterId: requesterId,
      userId: userId,
    );
  }
}
