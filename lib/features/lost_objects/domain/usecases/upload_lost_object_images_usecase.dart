import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_image_repository.dart';

class UploadLostObjectImagesUseCase {
  final LostObjectImageRepository _repository;

  const UploadLostObjectImagesUseCase(this._repository);

  Future<List<String>> call(List<String> filePaths) {
    return _repository.uploadLostObjectImages(filePaths);
  }
}
