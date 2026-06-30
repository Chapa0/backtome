import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class DeleteLostObjectUseCase {
  final LostObjectRepository _repository;

  const DeleteLostObjectUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required LostObject object,
  }) {
    return _repository.deleteLostObject(
      requesterId: requesterId,
      objectId: object.id,
      imageUrls: object.imageUrls ?? [object.imagenUrl],
    );
  }
}
