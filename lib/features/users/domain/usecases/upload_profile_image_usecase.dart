import 'package:flutter_backtome/features/users/domain/repositories/user_image_repository.dart';

class UploadProfileImageUseCase {
  final UserImageRepository _repository;

  const UploadProfileImageUseCase(this._repository);

  Future<String?> call({
    required String userId,
    required String filePath,
  }) {
    return _repository.uploadProfileImage(userId: userId, filePath: filePath);
  }
}
