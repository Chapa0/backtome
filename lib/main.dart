import 'package:flutter/material.dart';
import 'package:flutter_backtome/views/administradores/AdminHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/pageLogin.dart';
import 'views/usuarios/pageAppGeneral.dart'; // Pantalla principal para usuarios normales

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verifica si el usuario está autenticado
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userRole = prefs.getString('userRole'); // 'user' o 'admin'



  runApp(MyApp(userRole: userRole));
}

class MyApp extends StatelessWidget {
  final String? userRole;

  const MyApp({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Widget homeScreen = _selectHomeScreen();

    final Color _backgroundAppColor = Color(0xFFE1EDFF);
    final Color _institutionalColor = Color(0xFF1B396A);

    return MaterialApp(
      title: 'Back To Me',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: _institutionalColor,
        scaffoldBackgroundColor: _backgroundAppColor,
      ),
      debugShowCheckedModeBanner: false,
      home: homeScreen,
    );
  }

  Widget _selectHomeScreen() {

      // Si no es web, sigue la lógica existente basada en el rol del usuario
      switch (userRole) {
        case 'admin':
          return  AdminHomePage();
        case 'user':
          return PageAppGeneral();
        default:
          return PageLogin();
      }

  }


}
