import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class WatchLostObjectsUseCase {
  final LostObjectRepository _repository;

  const WatchLostObjectsUseCase(this._repository);

  Stream<List<LostObject>> call({bool onlyApproved = true}) {
    if (onlyApproved) {
      return _repository.watchApprovedLostObjects();
    }

    return _repository.watchLostObjects();
  }
}
