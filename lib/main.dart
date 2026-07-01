import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/core/firebase/firebase_options.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/user_home_page.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  setupLocator();

  final authState = AuthState();
  final prefs = await SharedPreferences.getInstance();
  final usuarioJson = prefs.getString('userData');
  if (usuarioJson != null) {
    final Map<String, dynamic> usuarioMap = json.decode(usuarioJson);
    if (usuarioMap.containsKey('id')) {
      final usuario = Usuario.fromMap(usuarioMap, usuarioMap['id'] as String);
      authState.setUser(usuario);
    }
  }

  runApp(BackToMeApp(authState: authState));
}

class BackToMeApp extends StatelessWidget {
  final AuthState authState;

  const BackToMeApp({super.key, required this.authState});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: authState),
      ],
      child: MaterialApp(
        title: 'Back To Me',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF1B396A),
          scaffoldBackgroundColor: const Color(0xFFE1EDFF),
        ),
        home: PageAppGeneral(),
      ),
    );
  }
}
