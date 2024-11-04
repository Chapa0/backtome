import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_backtome/views/pageCrearCuenta.dart';
import 'package:flutter_backtome/views/usuarios/pageAppGeneral.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'administradores/AdminHomePage.dart'; // Importa la página principal del administrador

class PageLogin extends StatefulWidget {
  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final Color _backgroundColor = Color(0xFFE1EDFF);
  // Variables útiles para la autenticación
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variables para mensajes de error en caso de que alguno esté mal
  String? _correoError;
  String? _passwordError;

  // Variable para controlar el estado del checkbox

  // Métodos útiles para la autenticación:
  Future<void> _signIn(BuildContext contextLocal, {required bool isAdmin}) async {
    // Método para seguir errores
    setState(() {
      _correoError = null;
      _passwordError = null;
    });
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print("Signed in as: ${userCredential.user?.email}");

      // Guarda los datos en SharedPreferences si el usuario marcó "Mantener sesión iniciada"
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', isAdmin ? 'admin' : 'user');


      // Navega a la pantalla correspondiente
      if (isAdmin) {
        Navigator.pushAndRemoveUntil(
          contextLocal,
          MaterialPageRoute(
            builder: (context) => AdminHomePage(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          contextLocal,
          MaterialPageRoute(
            builder: (context) => PageAppGeneral(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Manejo de errores
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-email') {
          setState(() {
            _correoError = "Correo inválido o inexistente";
          });
        } else if (e.code == 'wrong-password') {
          setState(() {
            _passwordError = "Contraseña incorrecta";
          });
        } else {
          setState(() {
            _correoError = "Error en el inicio de sesión";
          });
        }
      }
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        actions: [
          // Botón discreto de acceso de administrador
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: Colors.blue),
            onPressed: () => _showAdminLoginDialog(context),
            tooltip: 'Acceso administrador',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Para evitar overflow en pantallas pequeñas
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo y texto de la pantalla
              SizedBox(height: 60), // Espacio superior
              Image.asset(
                'lib/resources/itver_logo_sf.png',
                height: 100,
              ),
              SizedBox(height: 20),
              Text(
                "INICIAR SESIÓN",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // Campo de correo electrónico
              TextField(
                controller: _correoController,
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  errorText: _correoError,
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              // Campo de contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  errorText: _passwordError,
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              // Recordar contraseña checkbox

              SizedBox(height: 20),
              // Botón de Iniciar Sesión
              ElevatedButton(
                onPressed: () => _signIn(context, isAdmin: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                ),
                child: Text(
                  "Iniciar Sesión",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              // Botón de Crear Cuenta
              TextButton(
                onPressed: () {
                  // Navegar a la pantalla de Crear Cuenta
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PageCrearCuenta(background: _backgroundColor),
                    ),
                  );
                },
                child: Text(
                  "Crear Cuenta",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para mostrar un diálogo de inicio de sesión para administradores
  void _showAdminLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _adminPasswordController = TextEditingController();

        return AlertDialog(
          title: Text('Acceso de administrador'),
          content: TextField(
            controller: _adminPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Contraseña de administrador',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cerrar el diálogo
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Verificar la contraseña de administrador
                if (_adminPasswordController.text == 'admin') {
                  // Iniciar sesión como administrador
                  _signIn(context, isAdmin: true);
                  Navigator.of(context).pop();
                } else {
                  // Mostrar mensaje de error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contraseña de administrador incorrecta')),
                  );
                }
              },
              child: Text('Ingresar'),
            ),
          ],
        );
      },
    );
  }
}
