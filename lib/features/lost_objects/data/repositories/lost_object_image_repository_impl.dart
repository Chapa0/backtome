import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_object_image_storage_datasource.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_image_repository.dart';

class LostObjectImageRepositoryImpl implements LostObjectImageRepository {
  final LostObjectImageStorageDataSource _dataSource;

  const LostObjectImageRepositoryImpl({
    required LostObjectImageStorageDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<List<String>> uploadLostObjectImages(List<String> filePaths) {
    return _dataSource.uploadLostObjectImages(filePaths);
  }

  @override
  Future<String?> uploadClaimImage({
    required String objectId,
    required String filePath,
  }) {
    return _dataSource.uploadClaimImage(
      objectId: objectId,
      filePath: filePath,
    );
  }
}
