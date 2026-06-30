import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard

class Soporte extends StatefulWidget {
  @override
  _SoporteState createState() => _SoporteState();
}

class _SoporteState extends State<Soporte> {
  // Variables para el tamaño de la imagen del logo
  double _logoHeight = 250.0; // Altura inicial del logo
  double _logoWidth = 250.0;  // Ancho inicial del logo

  // Método para copiar al portapapeles y mostrar SnackBar
  void _copiarCorreo(BuildContext context) {
    final correo = 'mariopinedad03@gmail.com';
    Clipboard.setData(ClipboardData(text: correo)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'El correo ha sido copiado al portapapeles.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green, // Color verde
          behavior: SnackBarBehavior.floating, // SnackBar flotante
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Esquinas redondeadas
          ),
          duration: Duration(seconds: 2), // Duración del SnackBar
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Soporte',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1B396A), // Mismo color que el botón
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Espacio alrededor del contenido
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alineación al inicio
            children: [
              // Logo de la empresa centrado
              Center(
                child: Image.asset(
                  'lib/resources/Logo_BackToMe.jpeg',
                  height: _logoHeight, // Altura del logo ajustable
                  width: _logoWidth,   // Ancho del logo ajustable
                  fit: BoxFit.contain, // Ajuste para mantener la proporción
                ),
              ),
              SizedBox(height: 20.0), // Espacio vertical
              // Descripción del proyecto
              Text(
                'BackToMe es un proyecto de gestión de objetos perdidos para la materia de Gestión de Proyectos de Software. Esta idea nace con la problemática de objetos perdidos en la instalación del Instituto Tecnológico de Veracruz, haciendo que todos los problemas relacionados a este tema puedan ser administrados, cargados y solucionados en esta app.',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20.0), // Espacio vertical
              // Título del correo de asistencia
              Text(
                'Correo de asistencia:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              // Correo interactivo
              GestureDetector(
                onTap: () => _copiarCorreo(context), // Acción al tocar
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text(
                    'mariopinedad03@gmail.com',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.blue,
                      decoration: TextDecoration.underline, // Subrayado para indicar interactividad
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.0), // Espacio adicional si es necesario
              // Opcional: Slider para ajustar el tamaño del logo en tiempo real
              /*
              Text(
                'Ajustar tamaño del logo:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _logoHeight,
                min: 50.0,
                max: 200.0,
                divisions: 150,
                label: _logoHeight.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _logoHeight = value;
                    _logoWidth = value; // Mantiene la proporción cuadrada
                  });
                },
              ),
              */
            ],
          ),
        ),
      ),
    );
  }
}
