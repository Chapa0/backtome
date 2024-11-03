import 'package:flutter/material.dart';
import 'package:flutter_backtome/views/usuarios/pageUser.dart';

class PageSearch extends StatefulWidget {

  // Constructor que recibe el color de fondo
  PageSearch({Key? key}) : super(key: key);

  @override
  _PageSearchState createState() => _PageSearchState();
}

class _PageSearchState extends State<PageSearch> {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            // Barra de búsqueda
            GestureDetector(
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
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: Icon(Icons.close),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Título y botón de filtro
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Objetos Encontrados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Funcionalidad del filtro
                  },
                  icon: Icon(
                    Icons.filter_list,
                  ),
                  label: Text(
                    'Recientes',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B396A), // Color institucional
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Lista de objetos con scroll infinito
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Dos columnas
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _items.length + 1, // +1 para el indicador de carga
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    // Muestra un indicador de carga cuando se llega al final de la lista
                    return _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SizedBox.shrink();
                  }
                  return _buildObjectCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir las tarjetas de los objetos encontrados
  Widget _buildObjectCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/ipone.jpg', // Ruta de la imagen en tu carpeta assets
              height: 100,
              width: double.infinity,
              fit: BoxFit
                  .cover, // Ajusta la imagen para que ocupe todo el espacio
            ),
            SizedBox(height: 10),
            Text(
              'Objeto 1',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: 50),
              child: Text(
                'Esta es una descripción del objeto encontrado',
                overflow: TextOverflow
                    .ellipsis, //Agregar puntos suspensivos si es que hay más información
                maxLines: 2, //Solo mostrará 2 lineas del contenido
                style: TextStyle(color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}
