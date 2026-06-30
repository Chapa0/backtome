import 'package:flutter_backtome/features/users/data/datasources/user_image_storage_datasource.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_image_repository.dart';

class UserImageRepositoryImpl implements UserImageRepository {
  final UserImageStorageDataSource _dataSource;

  const UserImageRepositoryImpl(
      {required UserImageStorageDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<String?> uploadProfileImage({
    required String userId,
    required String filePath,
  }) {
    return _dataSource.uploadProfileImage(userId: userId, filePath: filePath);
  }
}
