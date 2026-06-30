import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<void> call() {
    return _repository.signOut();
  }
}
