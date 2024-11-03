import 'package:flutter/material.dart';
import 'package:flutter_backtome/views/usuarios/pageAppGeneral.dart';
// Importar librerías para autenticación y Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'administradorBD/usuariosBD.dart'; // Importa la clase Usuario

class PageCrearCuenta extends StatefulWidget {
  final Color background;

  // Constructor
  PageCrearCuenta({required this.background});

  @override
  _PageCrearCuentaState createState() => _PageCrearCuentaState();
}

class _PageCrearCuentaState extends State<PageCrearCuenta> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _signUp(BuildContext context, {required bool isAdmin}) async {
    if (_passwordController.text == _confirmPasswordController.text) {
      try {
        // Crea la cuenta en Firebase Authentication
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _correoController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Obtiene el UID del usuario recién registrado
        String uid = userCredential.user!.uid;

        // Crea una instancia de Usuario con los datos ingresados
        Usuario newUser = Usuario(
          id: uid,
          nombre: _nombreController.text.trim(),
          apellido: _apellidosController.text.trim(),
          correo: _correoController.text.trim(),
          urlimagen: '', // Puedes incluir la URL de una imagen si existe
        );

        // Guarda los datos del usuario en Firestore
        await _firestore.collection('usuarios').doc(uid).set(newUser.toMap());

        print("Usuario registrado y datos guardados en Firestore: ${userCredential.user?.email}");

        // Guarda los datos en SharedPreferences si el usuario marcó "Mantener sesión iniciada"
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', isAdmin ? 'admin' : 'user');
        // Navega a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PageAppGeneral(),
          ),
        );
      } catch (e) {
        print("Error al crear la cuenta: $e");
      }
    } else {
      print("Las contraseñas no coinciden");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: widget.background,
      appBar: AppBar(
        backgroundColor: widget.background,
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
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'CREA TU CUENTA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Y comencemos a ayudar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            // Campo Nombre
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 15),
            // Campo Apellidos
            TextFormField(
              controller: _apellidosController,
              decoration: InputDecoration(
                labelText: 'Apellidos',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 15),
            // Campo Correo Electrónico
            TextFormField(
              controller: _correoController,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                helperText: 'Ingresa un correo electrónico válido',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 15),
            // Campo Contraseña
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            SizedBox(height: 15),
            // Campo Confirmación de contraseña
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmación de contraseña',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            SizedBox(height: 15),
            // Checkbox para mantener la sesión iniciada

            SizedBox(height: 30),
            // Botón Crear cuenta
            ElevatedButton(
              onPressed: () => _signUp(context, isAdmin: false),
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )),
              child: Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

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
                  _signUp(context, isAdmin: true);
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
