import 'package:flutter/material.dart';
import 'package:flutter_backtome/views/usuarios/pageUser.dart';

class PageHome extends StatefulWidget {

  // Constructor que recibe el color de fondo
  PageHome({Key? key}) : super(key: key);

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  final ScrollController _scrollController = ScrollController();
  List<int> _items = List.generate(10, (index) => index); // Items iniciales
  bool _isLoading = false;
  final Color _institutionalColor = Color(0xFF1B396A);

  @override
  void initState() {
    super.initState();

    // Listener para detectar cuando el usuario llega al final del scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        _loadMoreItems();
      }
    });
  }

  // Simula la carga de más elementos
  void _loadMoreItems() async {
    setState(() {
      _isLoading = true;
    });

    // Simula un tiempo de carga
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _items.addAll(List.generate(
          10, (index) => _items.length + index)); // Agrega más elementos
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B396A),
      body: Column(
        children: [
          SizedBox(height: 30),
          // Parte superior con nombre de usuario y notificaciones
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PageUser()),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/mario.jpg',
                    ), // Imagen del usuario
                    radius: 24.0,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mario Pineda',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.notifications),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount:
                  _items.length + 1, // +1 para mostrar el indicador de carga
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  // Muestra un indicador de carga cuando se llegue al final de la lista
                  return _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SizedBox.shrink();
                }
                return _buildObjectCard();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir las tarjetas de los objetos encontrados
  Widget _buildObjectCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/mario.jpg'), // Imagen del usuario
                    radius: 20.0,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Mario Pineda',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Image.asset(
                'assets/ipone.jpg', // Ruta de la imagen en tu carpeta assets
                height: 150,
                width: double.infinity,
                fit: BoxFit
                    .cover, // Ajusta la imagen para que ocupe todo el espacio
              ),
              SizedBox(height: 10),
              Text(
                'Nombre del objeto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Esta es una descripción del objeto que se haya encontrado para que se pueda mostrar en la página de inicio',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
