import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Carrito extends StatefulWidget {
  final String clienteId;
  final Function actualizarCarrito;
  

  Carrito({required this.clienteId, required this.actualizarCarrito});

  @override
  _CarritoState createState() => _CarritoState();
}

class _CarritoState extends State<Carrito> {
  List<dynamic> productosCarrito = [];
  bool isLoading = true;
  int total = 0;
  int _selectedIndex = 0;
  String direccionDomicilio = "";
  final PageController _pageController = PageController();
    String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }


  @override
  void initState() {
    super.initState();
    fetchProductosCarrito(); // Llamar para obtener los productos del carrito
  }
  

// Función para vaciar el carrito
Future<void> vaciarCarrito() async {
  try {
    final response = await http.put(
      Uri.parse('http://192.168.39.186:8081/carrito/vaciar/${widget.clienteId}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        productosCarrito = []; // Vaciar los productos localmente
        total = 0; // Reiniciar el total a 0
      });
      widget.actualizarCarrito();
    } else {
      throw Exception('Error al vaciar el carrito');
    }
  } catch (error) {
    print('Error al vaciar el carrito: $error');
  }
}
  Future<void> confirmarPedido() async {
    // Abre el cuadro de diálogo para la dirección antes de confirmar el pedido
    String? direccion = await mostrarDialogoDireccion();
    if (direccion == null || direccion.isEmpty) {
      // Si el usuario cancela o no ingresa una dirección, no continúa
      return;
    }

    setState(() {
      direccionDomicilio = direccion;
    });

    // Continúa con el proceso de confirmar pedido
    try {
      final response = await http.post(
        Uri.parse('http://192.168.39.186:8081/compras/agregar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': widget.clienteId,
          'direccion': direccionDomicilio, // Enviar la dirección de domicilio
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          productosCarrito = [];
          total = 0;
        });
        widget.actualizarCarrito();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compra confirmada exitosamente')),
        );
      } else {
        throw Exception('Error al confirmar la compra');
      }
    } catch (error) {
      print('Error al confirmar el pedido: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar el pedido')),
      );
    }
  }
  // Función para mostrar el cuadro de diálogo y pedir la dirección
  Future<String?> mostrarDialogoDireccion() async {
    TextEditingController direccionController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ingrese la dirección de domicilio'),
          content: TextField(
            controller: direccionController,
            decoration: InputDecoration(hintText: 'Dirección'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () => Navigator.of(context).pop(direccionController.text),
            ),
          ],
        );
      },
    );
  }

  // Función para obtener los productos del carrito desde el backend
  Future<void> fetchProductosCarrito() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/carrito/${widget.clienteId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productosCarrito = data['productos']; // Asignar los productos del carrito directamente
          total = _calcularTotal(); // Calcular el total al cargar los productos
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los productos del carrito');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para calcular el total del carrito
  int _calcularTotal() {
    return productosCarrito.fold(0, (sum, producto) {
      return sum + (producto['subtotal'] as int);
    });
  }

// Función para actualizar la cantidad en el backend
Future<void> actualizarCantidadProducto(String productoId, int nuevaCantidad) async {
  try {
    final response = await http.put(
      Uri.parse('http://192.168.39.186:8081/carrito/actualizar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clienteId': widget.clienteId,  // Asegúrate de enviar clienteId
        'productoId': productoId,       // Producto que queremos actualizar
        'nuevaCantidad': nuevaCantidad  // Nueva cantidad de producto
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        fetchProductosCarrito(); // Refrescar el carrito después de actualizar
      });
      widget.actualizarCarrito();
    } else {
      throw Exception('Error al actualizar la cantidad del producto');
    }
  } catch (error) {
    print('Error al actualizar la cantidad: $error');
  }
}


  // Función para eliminar un producto del carrito
  Future<void> eliminarProducto(String productoId) async {
    try {
      final response = await http.delete(Uri.parse('http://192.168.39.186:8081/carrito/${widget.clienteId}/producto/$productoId'));
      if (response.statusCode == 200) {
        setState(() {
          productosCarrito.removeWhere((producto) => producto['_id'] == productoId);
          total = _calcularTotal(); // Recalcular el total después de eliminar
        });
        widget.actualizarCarrito();
      } else {
        throw Exception('Error al eliminar el producto del carrito');
      }
    } catch (error) {
      print('Error al eliminar el producto: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF828282)),
          onPressed: () {
            Navigator.pop(context, true); 
          },
        ),

        title: const Text(
          'Carrito',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              vaciarCarrito();
            },
            child: const Text(
              'Vaciar',
              style: TextStyle(color: Color(0xFF828282)),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFDFDDDD),
            height: 1.0,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              child: ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: productosCarrito.length, // Número de productos en el carrito
                itemBuilder: (context, index) {
                  final producto = productosCarrito[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // Color de las tarjetas
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.network(
                                producto['imgUrl'], // Ruta de la imagen
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 10.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto['nombre'],
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('${producto['cantidad']} unidades'),
                                    SizedBox(height: 4.0),
                                    Text(
                                      '\$${formatPrice(producto['precio'])}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: const Color.fromARGB(255, 148, 147, 147)),
                                onPressed: () {
                                  eliminarProducto(producto['_id']); // Eliminar producto
                                },
                              ),

                              Spacer(),
                              // Botones de decremento y incremento
                              IconButton(
                                icon: Icon(Icons.remove, color: Colors.red),
                                onPressed: () {
                                  if (producto['cantidad'] > 1) {
                                    setState(() {
                                      producto['cantidad']--;
                                      producto['subtotal'] = producto['cantidad'] * producto['precio'];
                                      total = _calcularTotal();
                                    });
                                    actualizarCantidadProducto(producto['_id'], producto['cantidad']); // Actualizar en el backend
                                  }
                                },
                              ),
                              Text('${producto['cantidad']}'),
                              IconButton(
                                icon: Icon(Icons.add, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    producto['cantidad']++;
                                    producto['subtotal'] = producto['cantidad'] * producto['precio'];
                                    total = _calcularTotal();
                                  });
                                  actualizarCantidadProducto(producto['_id'], producto['cantidad']); // Actualizar en el backend
                                },
                              ),
                              Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Subtotal:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${formatPrice(producto['subtotal'])}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.grey),
                  ),
                  Text(
                    '\$${formatPrice(total)}', // Total calculado del carrito
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                confirmarPedido(); 
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE33914),
                      Color(0xFFF20909),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  'Confirmar pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
