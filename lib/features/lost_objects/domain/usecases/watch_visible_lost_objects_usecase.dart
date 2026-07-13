import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class WatchVisibleLostObjectsUseCase {
  final LostObjectRepository _repository;

  const WatchVisibleLostObjectsUseCase(this._repository);

  Stream<List<LostObject>> call({required Usuario? user}) {
    return _repository.watchVisibleLostObjects(
      isAdmin: user?.tipoUsuario == 'admin',
      userId: user?.id,
    );
  }
}
