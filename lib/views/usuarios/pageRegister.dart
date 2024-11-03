import 'package:flutter/material.dart';
import 'pageShare.dart';

class PageRegister extends StatelessWidget {


  PageRegister({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B396A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Crea un anuncio",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Al hacer clic, navega a la siguiente pantalla para compartir detalles
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PageShare()),
                );
              },
              child: Column(
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.image,
                      size: 80,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Lógica adicional para seleccionar imagen (opcional)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PageShare()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B396A), // Color del botón
                    ),
                    child: Text(
                      "Selecciona la imagen del anuncio",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
