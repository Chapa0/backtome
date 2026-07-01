import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthState stores, updates and clears the current user', () {
    final authState = AuthState();
    final user = Usuario(
      id: 'u-1',
      nombre: 'Mario',
      apellido: 'Chapa',
      correo: 'mario@example.com',
      urlimagen: '',
      tipoUsuario: 'usuario',
    );
    final updatedUser = Usuario(
      id: 'u-1',
      nombre: 'Mario',
      apellido: 'Actualizado',
      correo: 'mario@example.com',
      urlimagen: 'https://example.com/avatar.png',
      tipoUsuario: 'admin',
    );

    expect(authState.user, isNull);

    authState.setUser(user);
    expect(authState.user, same(user));

    authState.updateUser(updatedUser);
    expect(authState.user, same(updatedUser));
    expect(authState.user?.tipoUsuario, 'admin');

    authState.logout();
    expect(authState.user, isNull);
  });
}
