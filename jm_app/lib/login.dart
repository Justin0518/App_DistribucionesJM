import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jm_app/Admin/adminNavegar.dart';
import 'dart:convert';
import 'package:jm_app/Cliente/navegar.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isClienteSelected = false;
  bool isAdministradorSelected = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // Indicador de carga

  // Función para autenticar cliente
  Future<void> autenticarCliente() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse('http://192.168.39.186:8081/clientes/login'); // URL del backend para autenticar cliente

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailController.text,
          "contraseña": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');

        // Si las credenciales son correctas
        final data = json.decode(response.body);
        final clienteId = data['_id'];


        // Navega a la pantalla "Navegar"
        bool esTemporal = data['isPasswordTemporary'] ?? false;
        print(data['isPasswordTemporary']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Navegar(clienteId: clienteId, esTemporal: esTemporal, email: emailController.text),
          ),
        );

      } else if (response.statusCode == 404) {
        _mostrarMensajeError('Cliente no registrado');
      } else if (response.statusCode == 401) {
        _mostrarMensajeError('Contraseña incorrecta');
      }
    } catch (error) {
      _mostrarMensajeError('Error al conectar con el servidor');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> autenticarAdmin() async {
  setState(() {
    isLoading = true;
  });
  
  final url = Uri.parse('http://192.168.39.186:8081/admin/login'); // Endpoint para administradores

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "email": emailController.text,
        "contraseña": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Si las credenciales son correctas
      final data = json.decode(response.body);


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminNavegar(), // Cambiar a la pantalla de admin
        ),
      );
    } else if (response.statusCode == 404) {
      _mostrarMensajeError('Administrador no encontrado');
    } else if (response.statusCode == 401) {
      _mostrarMensajeError('Contraseña incorrecta');
    }
  } catch (error) {
    _mostrarMensajeError('Error al conectar con el servidor');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  // Función para mostrar mensaje de error
  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Fondo
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fondo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: const Color.fromARGB(36, 36, 36, 36).withOpacity(0.67),
            ),
            // Contenido
            Column(
              children: [
                const Spacer(flex: 3),
                Image.asset('assets/images/loguito.png', width: 349, fit: BoxFit.fill),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isClienteSelected = true;
                          isAdministradorSelected = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isClienteSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFE33914), Color(0xFFF20909)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          border: isClienteSelected ? null : Border.all(color: Colors.white),
                        ),
                        child: const Text(
                          'Cliente',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isClienteSelected = false;
                          isAdministradorSelected = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isAdministradorSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFE33914), Color(0xFFF20909)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          border: isAdministradorSelected ? null : Border.all(color: Colors.white),
                        ),
                        child: const Text(
                          'Administrador',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white, size: 40),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                hintText: 'Usuario',
                                hintStyle: TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.transparent,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.white, size: 40),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                hintText: 'Contraseña',
                                hintStyle: TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.transparent,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      GestureDetector(
                        onTap: () {
                          if (!isClienteSelected && !isAdministradorSelected) {
                            // Mostrar mensaje de error si no ha seleccionado ninguna opción
                            _mostrarMensajeError('Debes elegir una opción: Cliente o Administrador');
                          } else if (isClienteSelected) {
                            autenticarCliente(); // Autenticar como cliente
                          } else if (isAdministradorSelected) {
                            autenticarAdmin(); // Autenticar como administrador
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE33914), Color(0xFFF20909)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Text(
                            'Ingresar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isLoading)
                        const CircularProgressIndicator(), // Indicador de carga
                    ],
                  ),
                ),
                const Spacer(flex: 5),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 150),
                painter: CurvePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF2B109),
          Color(0xFFE2590B),
          Color(0xFFE33914),
        ],
        stops: [0.05, 0.5, 1.0], // Ajusta los porcentajes aquí para suavizar la transición
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 4, 90, size.width / 2, 105)
      ..quadraticBezierTo(size.width * 0.75, 117, size.width, 80)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
