// user_account_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/usuarioRegistrado.dart';
import '../administradorBD/usuariosBD.dart';
import '../pageLogin.dart'; // Import the login page

class UserAccountPage extends StatefulWidget {
  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final _formKey = GlobalKey<FormState>();
  String? _nombre;
  String? _password;
  bool _isEditingName = false;
  bool _isEditingPassword = false;

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final Usuario? currentUser = authState.user;

    final String userName = currentUser?.nombre ?? 'Usuario';
    final String userEmail = currentUser?.correo ?? 'correo@ejemplo.com';
    final String userPhotoUrl = currentUser?.urlimagen ?? 'https://via.placeholder.com/150';

    final Color primaryColor = Color(0xFF1B396A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cuenta'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(userPhotoUrl),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: userName,
                    enabled: _isEditingName,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      suffixIcon: IconButton(
                        icon: Icon(_isEditingName ? Icons.check : Icons.edit),
                        onPressed: () {
                          setState(() {
                            if (_isEditingName) {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                currentUser?.nombre = _nombre ?? currentUser.nombre;
                                authState.updateUser(currentUser!);
                              }
                              _isEditingName = false;
                            } else {
                              _isEditingName = true;
                            }
                          });
                        },
                      ),
                    ),
                    onSaved: (value) {
                      _nombre = value;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    obscureText: true,
                    enabled: _isEditingPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: '********',
                      suffixIcon: IconButton(
                        icon: Icon(_isEditingPassword ? Icons.check : Icons.edit),
                        onPressed: () {
                          setState(() {
                            if (_isEditingPassword) {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                              }
                              _isEditingPassword = false;
                            } else {
                              _isEditingPassword = true;
                            }
                          });
                        },
                      ),
                    ),
                    onSaved: (value) {
                      _password = value;
                    },
                  ),
                ],
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () async {
                authState.logout();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('userRole');

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => PageLogin()),
                      (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
