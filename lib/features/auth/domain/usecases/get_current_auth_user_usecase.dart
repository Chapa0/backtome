import 'package:flutter_backtome/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentAuthUserUseCase {
  final AuthRepository _repository;

  const GetCurrentAuthUserUseCase(this._repository);

  AuthUser? call() {
    return _repository.currentUser();
  }
}
