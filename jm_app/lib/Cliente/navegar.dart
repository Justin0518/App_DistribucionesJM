import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jm_app/Cliente/pedidos.dart';
import 'package:jm_app/Cliente/categorias.dart';
import 'package:jm_app/Cliente/carrito.dart';
import 'package:jm_app/Cliente/inicio.dart';
import 'package:jm_app/login.dart'; // Suponiendo que tienes esta pantalla para cerrar sesión

class Navegar extends StatefulWidget {
  final String clienteId;
  final bool esTemporal;
  final String email;

  Navegar({required this.clienteId, required this.esTemporal, required this.email});

  @override
  _NavegarState createState() => _NavegarState();
}

class _NavegarState extends State<Navegar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _carritoCount = 0; // Variable para el número de productos en el carrito
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.esTemporal) {
      Future.delayed(Duration.zero, () => _mostrarCambioContrasenia(context));
    }
    fetchCarritoCount(); // Inicializamos el conteo del carrito desde el backend
  }

  // Función para obtener el número real de productos en el carrito desde el backend
  Future<void> fetchCarritoCount() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/carrito/${widget.clienteId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _carritoCount = data['productos'].length;  // Obtenemos la cantidad de productos
        });
      } else {
        throw Exception('Error al obtener el número de productos del carrito');
      }
    } catch (error) {
      print("Error al obtener el conteo del carrito: $error");
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Carrito(clienteId: widget.clienteId, actualizarCarrito: fetchCarritoCount),
        ),
      ).then((value) {
        if (value == true) {
          // Si se devuelve con "true", regresa a la pantalla de inicio
          setState(() {
            _selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
        }
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _mostrarCambioContrasenia(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: CambioContraseniaDialog(email: widget.email),
        );
      },
    );
  }

  void _cerrarSesion() {
    // Navegar de regreso a la pantalla de login para cerrar sesión
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(), // Suponiendo que esta es la pantalla de login
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 200,
            child: Stack(
              children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff000000), Color(0xff434343)],
                    stops: [0, 1],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                ),
              ),

                Positioned(
                  top: -85,
                  left: -112,
                  child: Container(
                    width: 280,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFF2B109).withOpacity(0.89),
                          Color(0xFFE2590B).withOpacity(0.89),
                          Color(0xFFFF20909).withOpacity(0.89),
                        ],
                        stops: [0.5, 0.61, 0.81],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Aquí se coloca el logo en el centro de la parte superior
                Positioned(
                  top: 70, // Ajusta el valor de top para centrar verticalmente
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80, // Ajusta el tamaño del logo
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              _onItemTapped(0);
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment),
            title: Text('Pedidos'),
            onTap: () {
              Navigator.pop(context);
              _onItemTapped(1);
            },
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Categorías'),
            onTap: () {
              Navigator.pop(context);
              _onItemTapped(2);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Carrito'),
            onTap: () {
              Navigator.pop(context);
              _onItemTapped(3);
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context);
              _cerrarSesion();
            },
          ),
        ],
      ),
    ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          Inicio(openDrawer: _openDrawer, clienteId: widget.clienteId, actualizarCarrito: fetchCarritoCount),
          Pedidos(clienteId: widget.clienteId),
          Categorias(clienteId: widget.clienteId, actualizarCarrito: fetchCarritoCount),
        ],
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: _selectedIndex == 3
          ? null
          : Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.red,
                unselectedItemColor: Color(0xFF828282),
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontSize: 16),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
                  BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Pedidos'),
                  BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categorías'),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        Icon(Icons.shopping_cart_outlined),
                        if (_carritoCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Color(0xFFE33914),
                                borderRadius: BorderRadius.circular(200),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 10,
                              ),
                              child: Text(
                                '$_carritoCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Carrito',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
    );
  }
}



class CambioContraseniaDialog extends StatefulWidget {
  final String email;

  CambioContraseniaDialog({required this.email});

  @override
  _CambioContraseniaDialogState createState() => _CambioContraseniaDialogState();
}

class _CambioContraseniaDialogState extends State<CambioContraseniaDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nuevaContraseniaController = TextEditingController();
  TextEditingController confirmarContraseniaController = TextEditingController();
  bool isLoading = false;

  Future<void> cambiarContrasenia() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final url = Uri.parse('http://192.168.247.186:8081/clientes/cambiarContra');
      final body = json.encode({
        'email': widget.email,
        'nuevaContraseña': nuevaContraseniaController.text,
      });

      try {
        final response = await http.put(
          url,
          headers: {"Content-Type": "application/json"},
          body: body,
        );

        if (response.statusCode == 200) {
          // Contraseña actualizada correctamente
          Navigator.of(context).pop(); // Cerrar el diálogo y continuar en la pantalla principal
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar la contraseña')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $error')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambiar Contraseña',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nuevaContraseniaController,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 122, 121, 121), width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 122, 121, 121), width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 122, 121, 121), width: 2.0),
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingrese la nueva contraseña';
                } else if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: confirmarContraseniaController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 122, 121, 121), width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 122, 121, 121), width: 2.0),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 122, 121, 121), width: 2.0),
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value != nuevaContraseniaController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                :ElevatedButton(
                onPressed: cambiarContrasenia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Fondo rojo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Actualizar Contraseña',
                  style: TextStyle(color: Colors.white), // Texto blanco
                ),
              ),

          ],
        ),
      ),
    );
  }
}
