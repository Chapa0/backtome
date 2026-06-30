import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository _repository;

  const SendPasswordResetUseCase(this._repository);

  Future<void> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
