import 'package:flutter_backtome/services/usuarioRegistrado.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthState starts without an authenticated user', () {
    final authState = AuthState();

    expect(authState.user, isNull);
  });
}
