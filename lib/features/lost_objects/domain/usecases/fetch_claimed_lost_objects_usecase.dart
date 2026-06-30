import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class FetchClaimedLostObjectsUseCase {
  final LostObjectRepository _repository;

  const FetchClaimedLostObjectsUseCase(this._repository);

  Future<List<LostObject>> call(String userId) {
    return _repository.fetchClaimedLostObjects(userId);
  }
}
