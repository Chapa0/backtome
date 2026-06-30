import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class DeliverLostObjectUseCase {
  final LostObjectRepository _repository;

  const DeliverLostObjectUseCase(this._repository);

  Future<void> call({
    required String requesterId,
    required LostObject object,
    required Reclamacion claim,
  }) {
    return _repository.deliverLostObject(
      requesterId: requesterId,
      objectId: object.id,
      claimantId: claim.uidReclamante,
    );
  }
}
