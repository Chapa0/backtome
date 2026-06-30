import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class RejectLostObjectUseCase {
  final LostObjectRepository _repository;

  const RejectLostObjectUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required LostObject object,
  }) {
    return _repository.rejectLostObject(
      requesterId: requesterId,
      objectId: object.id,
    );
  }
}
