import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class FetchVisibleLostObjectsUseCase {
  final LostObjectRepository _repository;

  const FetchVisibleLostObjectsUseCase(this._repository);

  Future<List<LostObject>> call({
    required Usuario? user,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.fetchVisibleLostObjects(
      isAdmin: user?.tipoUsuario == 'admin',
      userId: user?.id,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
