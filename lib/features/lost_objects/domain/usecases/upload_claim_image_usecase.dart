import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_image_repository.dart';

class UploadClaimImageUseCase {
  final LostObjectImageRepository _repository;

  const UploadClaimImageUseCase(this._repository);

  Future<String?> call({
    required String objectId,
    required String filePath,
  }) {
    return _repository.uploadClaimImage(
      objectId: objectId,
      filePath: filePath,
    );
  }
}
