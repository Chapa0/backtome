
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/views/administradores/userDetailPage.dart';
import '../administradorBD/usuariosBD.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final Color _primaryColor = Color(0xFF1B396A);
  List<Usuario> _usuarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('usuarios').
      where('tipoUsuario', isEqualTo: 'user')
          .get();
      setState(() {
        _usuarios = querySnapshot.docs
            .map((doc) => Usuario.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los usuarios.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios registrados (${_usuarios.length})', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(usuario.urlimagen),
            ),
            title: Text(usuario.nombre),
            subtitle: Text(usuario.correo),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailPage(usuario: usuario),
                ),
              );

              if (result == true) {
                // El usuario fue eliminado, actualizar la lista
                setState(() {
                  _usuarios.removeAt(index);
                });
              }
            },
          );
        },
      ),
    );
  }
}

