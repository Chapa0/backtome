import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class CreateLostObjectUseCase {
  final LostObjectRepository _repository;

  const CreateLostObjectUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required String description,
    required String objectType,
    required String foundPlace,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
  }) {
    return _repository.createLostObject(
      requesterId: requesterId,
      description: description,
      objectType: objectType,
      foundPlace: foundPlace,
      imageUrls: imageUrls,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
