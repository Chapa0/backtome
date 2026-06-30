import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class ApproveLostObjectUseCase {
  final LostObjectRepository _repository;

  const ApproveLostObjectUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required LostObject object,
  }) {
    return _repository.approveLostObject(
      requesterId: requesterId,
      objectId: object.id,
    );
  }
}
