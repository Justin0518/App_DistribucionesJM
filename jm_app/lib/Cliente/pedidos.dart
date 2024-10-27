import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'package:intl/intl.dart';

class Pedidos extends StatefulWidget {
  final String clienteId; 

  Pedidos({required this.clienteId});

  @override
  _PedidosState createState() => _PedidosState();
}

class _PedidosState extends State<Pedidos> {
  List<dynamic> pedidos = [];
  List<dynamic> pedidosFiltrados = [];
  bool isLoading = true;
  String searchQuery = "";
  String? filtroEstado;
  DateTime? filtroFecha;

  @override
  void initState() {
    super.initState();
    fetchPedidos(); 
  }

  // Función para obtener los pedidos del cliente desde el backend
  Future<void> fetchPedidos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/pedidos/cliente/${widget.clienteId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pedidos = data;
          pedidosFiltrados = pedidos; // Inicialmente todos los pedidos son mostrados
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los pedidos');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filtrar los pedidos según búsqueda y filtros
  void _filterPedidos() {
    List<dynamic> filtrados = pedidos;

    if (searchQuery.isNotEmpty) {
      filtrados = filtrados.where((pedido) =>
          pedido['_id'].toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    if (filtroEstado != null) {
      filtrados = filtrados.where((pedido) => pedido['estado'] == filtroEstado).toList();
    }

    if (filtroFecha != null) {
      filtrados = filtrados.where((pedido) {
        DateTime fechaPedido = DateTime.parse(pedido['fechaCompra']);
        return fechaPedido.isAtSameMomentAs(filtroFecha!) || fechaPedido.isAfter(filtroFecha!);
      }).toList();
    }

    setState(() {
      pedidosFiltrados = filtrados;
    });
  }

  // Mostrar opciones de filtrado
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(30),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Filtro de estado
                  Flexible(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: filtroEstado,
                      hint: Text('Estado:'),
                      items: ['en preparación', 'enviado', 'entregado']
                          .map((estado) => DropdownMenuItem<String>(
                                value: estado,
                                child: Text(estado),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          filtroEstado = value;
                          _filterPedidos(); // Aplicar filtros
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 50),
                  // Filtro de fecha
                  Flexible(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            filtroFecha = selectedDate;
                            _filterPedidos(); // Aplicar filtros
                          });
                        }
                      },
                      child: Text('Fecha', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Botón para limpiar filtros
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      filtroEstado = null;
                      filtroFecha = null;
                      _filterPedidos(); // Limpiar filtros
                    });
                    Navigator.pop(context); // Cerrar el modal
                  },
                  child: Text('Limpiar filtro', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Mis Pedidos',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFFFFFFF),
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
      body: Container( 
        padding: const EdgeInsets.all(30.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Barra de búsqueda y botón de filtro
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Color(0xFFE4E4E4)),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _filterPedidos(); // Filtrar al escribir en la barra de búsqueda
                              });
                            },
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              hintText: 'Buscar pedido',
                              hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                              suffixIcon: Icon(Icons.search, color: Color(0xFF828282)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.filter_list, color: Color(0xFF828282)),
                        onPressed: _showFilterOptions,
                      ),
                      const Text(
                        'Filtrar',
                        style: TextStyle(color: Color(0xFF828282)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pedidosFiltrados.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidosFiltrados[index];
                        return _buildPedidoSection(
                          pedido['fechaCompra'].toString().substring(0, 10),
                          pedido['_id'],
                          pedido['estado'],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Construye la carta de cada pedido con el nuevo diseño
  Widget _buildPedidoSection(String fecha, String numeroPedido, String estado) {
    Color estadoColor;
    Icon estadoIcon;

    if (estado == 'en preparación') {
      estadoColor = Colors.red;
      estadoIcon = Icon(Icons.pending, color: Colors.white);
    } else if (estado == 'enviado') {
      estadoColor = Colors.orange;
      estadoIcon = Icon(Icons.local_shipping, color: Colors.white);
    } else {
      estadoColor = Colors.green;
      estadoIcon = Icon(Icons.check, color: Colors.white);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Color.fromARGB(255, 252, 251, 251),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: estadoColor,
                    child: estadoIcon,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pedido #$numeroPedido",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    estado,
                    style: TextStyle(
                      fontSize: 14,
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Fecha: $fecha', style: TextStyle(fontSize: 14, color: Colors.black)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.search, size: 14),
                  const SizedBox(width: 5),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePedidoCliente(pedidoId: numeroPedido),
                        ),
                      );
                    },
                    child: Text('Ver detalles', style: TextStyle(fontSize: 14, color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class DetallePedidoCliente extends StatefulWidget {
  final String pedidoId;

  DetallePedidoCliente({required this.pedidoId});

  @override
  _DetallePedidoClienteState createState() => _DetallePedidoClienteState();
}

class _DetallePedidoClienteState extends State<DetallePedidoCliente> {
  Map<String, dynamic> pedido = {};
  bool isLoading = true;
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    fetchDetallePedido(); // Llamar para obtener los detalles del pedido
  }

  // Función para obtener los detalles del pedido desde el backend
  Future<void> fetchDetallePedido() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/pedidos/${widget.pedidoId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pedido = data; // Asignar los detalles del pedido al estado
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los detalles del pedido');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> productos = pedido['productos'] ?? [];

    double totalPagado = productos.fold(0, (sum, producto) {
      return sum + producto['subtotal'];
    });
    double total = totalPagado;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF828282)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Detalle del Pedido',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${pedido['_id']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text('Fecha: ${pedido['fechaCompra'].toString().substring(0, 10)}', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  Text(
                    'Productos Comprados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        final producto = productos[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Image.network(
                                  producto['imgUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                    return Icon(Icons.broken_image, size: 50);
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        producto['nombre'],
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text('Cantidad: ${producto['cantidad']}', style: TextStyle(fontSize: 14)),
                                      const SizedBox(height: 5),
                                      Text('Precio: \$${formatPrice(producto['precio'])}', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Subtotal:',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    Text(
                                      '\$${formatPrice(producto['subtotal'])}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                  const SizedBox(height: 20),
                  Divider(),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '\$${formatPrice(total)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
