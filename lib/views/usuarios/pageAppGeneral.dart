import 'package:flutter/material.dart';
import 'package:flutter_backtome/views/usuarios/pageHome.dart';
import 'package:flutter_backtome/views/usuarios/pageRegister.dart';
import 'package:flutter_backtome/views/usuarios/pageSearch.dart';
import 'package:flutter_backtome/views/usuarios/pageUser.dart';

class PageAppGeneral extends StatefulWidget {
  PageAppGeneral({Key? key}) : super(key: key);
  @override
  _PageAppGeneralState createState() => _PageAppGeneralState();
}

class _PageAppGeneralState extends State<PageAppGeneral> {
  // Colores del proyecto
  //final Color _backgroundAppColor = Color(0xFFF0ECF5);
  //final Color _backgroundAppColor = widget.background; //Color(0xFFE1EDFF);
  final Color _institutionalColor = Color(0xFF1B396A);
  int _selectedItems = 0;

  late List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    // Inicializar la lista de páginas en el initState
    _paginas = [
      PageHome(),
      PageSearch(),
      PageRegister(),
      PageUser(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _paginas[_selectedItems],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:
            _selectedItems, // Indice para saber en qué pestaña estamos
        onTap: (int index) {
          setState(() {
            _selectedItems = index;
          });
        },
        // Colores de la barra de navegación
        backgroundColor: Colors.white,
        selectedItemColor: _institutionalColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Búsqueda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Registrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Usuario',
          ),
        ],
      ),
    );
  }
}
