import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PedidosAdmin extends StatefulWidget {
  @override
  _PedidosAdminState createState() => _PedidosAdminState();
}

class _PedidosAdminState extends State<PedidosAdmin> {
  List<Map<String, dynamic>> pedidos = [];
  String searchQuery = "";
  String? filtroEstado;
  DateTime? filtroFecha;
  bool isLoading = true; // Para mostrar indicador de carga mientras se obtienen los datos

  @override
  void initState() {
    super.initState();
    fetchPedidos(); // Llamar para obtener los pedidos al cargar la pantalla
  }

  // Función para obtener pedidos del backend
  Future<void> fetchPedidos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/pedidos/')); // URL del backend

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          pedidos = data.map((pedido) {
            return {
              "_id": pedido["_id"], 
              "cliente": pedido["nombreCliente"], 
              "estado": pedido["estado"], 
              "fecha": pedido["fechaCompra"].toString().substring(0, 10), // Convertir fecha a string corto
            };
          }).toList();

        // Ordena los pedidos por número de pedido (del más alto al más bajo)
        pedidos.sort((a, b) {
  
          int numA = int.parse(a["_id"].substring(1));  // Remover la "P" inicial y convertir a entero
          int numB = int.parse(b["_id"].substring(1));  // Remover la "P" inicial y convertir a entero
          
          return numB.compareTo(numA);  // Ordenar de mayor a menor
        });
          
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filtrar los pedidos según búsqueda, estado y fecha
  List<Map<String, dynamic>> _filterPedidos() {
    List<Map<String, dynamic>> filtrados = pedidos;

    if (searchQuery.isNotEmpty) {
      filtrados = filtrados.where((pedido) =>
          pedido['cliente'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          pedido['_id'].contains(searchQuery)).toList();
    }

    if (filtroEstado != null) {
      filtrados = filtrados.where((pedido) =>
          pedido['estado'] == filtroEstado).toList();
    }

    if (filtroFecha != null) {
      filtrados = filtrados.where((pedido) {
        DateTime fechaPedido = DateTime.parse(pedido['fecha']);
        return fechaPedido.isAtSameMomentAs(filtroFecha!) ||
               fechaPedido.isAfter(filtroFecha!);
      }).toList();
    }

    return filtrados;
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
              // Filtros de estado y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Flexible(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: filtroEstado,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red), // Línea de color rojo cuando no está enfocado
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0), // Línea de color rojo cuando está enfocado
                      ),
                      labelText: 'Estado:',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 94, 92, 92)), // Color de la etiqueta
                    ),
                    items: ['en preparación', 'enviado', 'entregado']
                        .map((estado) => DropdownMenuItem<String>(
                              value: estado,
                              child: Text(estado),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        filtroEstado = value;
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
                          });
                        }
                      },
                      child: Text('Fecha', style: TextStyle(color: const Color.fromARGB(255, 94, 92, 92))),
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
    // Función para obtener el detalle de un pedido específico
  Future<Map<String, dynamic>?> fetchDetallePedido(String pedidoId) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/pedidos/$pedidoId'));
      if (response.statusCode == 200) {
        return json.decode(response.body); // Detalles del pedido
      } else {
        print('Error al obtener detalle del pedido: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      return null;
    }
  }

  // Actualizar el estado de un pedido en el backend
  Future<void> actualizarEstadoPedido(String pedidoId, String nuevoEstado) async {
    try {
      print('Actualizando el pedido $pedidoId con estado $nuevoEstado'); 
      final response = await http.put(
        Uri.parse('http://192.168.247.186:8081/pedidos/$pedidoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        print('Pedido actualizado exitosamente en la base de datos');
      } else {
        print('Error al actualizar el pedido: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en la solicitud HTTP: $error');
    }
  }

// Cambiar el estado del pedido localmente y en la base de datos
void cambiarEstado(int index, String nuevoEstado) {
  print('Actualizando estado del pedido ${pedidos[index]['_id']} a $nuevoEstado'); 
  setState(() {
    pedidos[index]['estado'] = nuevoEstado;
  });

  // Obtener el ID del pedido que se va a actualizar
  String pedidoId = pedidos[index]['_id'];

  // Actualizar el estado en la base de datos
  actualizarEstadoPedido(pedidoId, nuevoEstado);
}

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> pedidosFiltrados = _filterPedidos();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Pedidos',
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
          ? Center(child: CircularProgressIndicator()) // Mostrar indicador de carga
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Barra de búsqueda y botón de filtro
                  Row(
                    children: [
                      // Barra de búsqueda
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
                              });
                            },
                            textAlign: TextAlign.left,
                            textCapitalization: TextCapitalization.sentences,  // Primera letra en mayúscula
                            keyboardType: TextInputType.text, 
                            decoration: InputDecoration(
                              hintText: 'Buscar pedido',
                              hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                              suffixIcon: Icon(Icons.search, color: Color(0xFF828282)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botón de filtro
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.filter_list, color: Color(0xFF828282)),
                            onPressed: _showFilterOptions,
                          ),
                        ],
                        
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pedidosFiltrados.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            final pedidoId = pedidosFiltrados[index]['_id'];
                            final pedidoDetalle = await fetchDetallePedido(pedidoId); // Obtener el pedido

                            if (pedidoDetalle != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetallePedido(pedido: pedidoDetalle),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al cargar detalles del pedido.')),
                              );
                            }
                          },
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: Color.fromARGB(255, 252, 251, 251),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: pedidosFiltrados[index]['estado'] == 'entregado'
                                    ? Colors.green
                                    : pedidosFiltrados[index]['estado'] == 'enviado'
                                        ? Colors.orange
                                        : Colors.red,
                                child: Icon(
                                  pedidosFiltrados[index]['estado'] == 'entregado'
                                      ? Icons.check
                                      : pedidosFiltrados[index]['estado'] == 'enviado'
                                          ? Icons.local_shipping
                                          : Icons.pending,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                  "Pedido #${pedidosFiltrados[index]['_id']} - ${pedidosFiltrados[index]['cliente']}"),
                              subtitle: Text(
                                  "Fecha: ${pedidosFiltrados[index]['fecha']} - Estado: ${pedidosFiltrados[index]['estado']}"),
                              trailing: PopupMenuButton<String>(
                                onSelected: (nuevoEstado) {
                                  // Cambiar el estado localmente y en la base de datos
                                  cambiarEstado(index, nuevoEstado);  // Llamar a la función que actualiza el estado
                                },
                                itemBuilder: (BuildContext context) {
                                  return ['en preparación', 'enviado', 'entregado']
                                      .map((String estado) {
                                    return PopupMenuItem<String>(
                                      value: estado,
                                      child: Text(estado),
                                    );
                                  }).toList();
                                },
                                child: Icon(Icons.more_vert),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


class DetallePedido extends StatelessWidget {
  final Map<String, dynamic> pedido; // El pedido se pasa desde la pantalla anterior
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  DetallePedido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    List<dynamic> productos = pedido['productos']; // Lista de productos desde el pedido


    int totalPagado = productos.fold(0, (sum, producto) {
      return (sum + producto['subtotal'] as int);
    });
    int total = totalPagado;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
      body: Container(
        color: Color.fromARGB(255, 253, 253, 253),
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles del pedido
            Text(
              'Pedido #${pedido['_id']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cliente: ${pedido['nombreCliente']}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Fecha: ${pedido['fechaCompra'].toString().substring(0, 10)}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Dirección: ${pedido['direccion']}',
              style: TextStyle(fontSize: 16),
            ),
              
            const SizedBox(height: 20),
            // Productos comprados
            Text(
              'Productos Comprados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
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
                          // Aquí suponemos que tienes una URL de imagen, si no, ajusta
                          Image.network(
                            productos[index]['imgUrl'],  // Asegúrate de que imgUrl sea la clave correcta
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              return Icon(Icons.broken_image, size: 50);  // Mostrar un ícono si hay un error al cargar la imagen
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto['nombre'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Cantidad: ${producto['cantidad']}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Precio: \$${formatPrice(producto['precio'])}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Subtotal:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '\$${formatPrice(producto['subtotal'])}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '\$${formatPrice(total)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
