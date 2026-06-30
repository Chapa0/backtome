import 'package:flutter/foundation.dart';

import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class AuthState extends ChangeNotifier {
  Usuario? _user;

  Usuario? get user => _user;

  void setUser(Usuario user) {
    _user = user;
    print("usuarioactualizado: ${_user?.nombre}");
    notifyListeners();
  }

  void logout() {
    _user = null;
    print(_user?.nombre);
    notifyListeners();
  }

  void updateUser(Usuario newUser) {
    _user = newUser;
    print("usuarioactualizado: ${_user?.nombre}");
    notifyListeners();
  }
}
