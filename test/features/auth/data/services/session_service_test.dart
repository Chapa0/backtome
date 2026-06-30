import 'dart:convert';

import 'package:flutter_backtome/features/auth/data/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SessionService', () {
    test('restores user role and user data from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'user',
        'userData': json.encode({
          'id': 'user-1',
          'nombre': 'Ana',
          'apellido': 'Lopez',
          'correo': 'ana@example.com',
          'urlimagen': '',
          'tipoUsuario': 'user',
        }),
      });

      final preferences = await SharedPreferences.getInstance();
      final session = await SessionService(preferences).restoreSession();

      expect(session.userRole, 'user');
      expect(session.user?.id, 'user-1');
      expect(session.user?.nombre, 'Ana');
    });

    test('returns an empty auth state when userData is missing', () async {
      SharedPreferences.setMockInitialValues({});

      final preferences = await SharedPreferences.getInstance();
      final session = await SessionService(preferences).restoreSession();

      expect(session.userRole, isNull);
      expect(session.user, isNull);
    });
  });
}
