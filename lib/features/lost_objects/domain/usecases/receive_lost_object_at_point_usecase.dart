import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object_point.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class ReceiveLostObjectAtPointUseCase {
  final LostObjectRepository _repository;

  const ReceiveLostObjectAtPointUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required LostObject object,
    required LostObjectPoint custodyPoint,
  }) {
    return _repository.receiveLostObjectAtPoint(
      requesterId: requesterId,
      objectId: object.id,
      custodyPoint: custodyPoint,
    );
  }
}
