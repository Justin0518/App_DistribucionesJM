import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Clientes extends StatefulWidget {
  @override
  _ClientesState createState() => _ClientesState();
}

class _ClientesState extends State<Clientes> {
  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> clientesFiltrados = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchClientes(); // Llamar para obtener clientes del backend
  }

  // Función para manejar el retorno al agregar un cliente
  Future<void> _agregarCliente() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgregarCliente()),
    );

    // Si el resultado es 'refresh', recargar la lista de clientes
    if (result == 'refresh') {
      fetchClientes();
    }
  }

  // Función para obtener clientes del backend
  Future<void> fetchClientes() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/clientes/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          clientes = data.map((cliente) {
            return {
              "_id": cliente["_id"],
              "nombre": "${cliente['nombres']} ${cliente['apellidos']}",
              "email": cliente["email"],
              "telefono": cliente["telefono"],
              "activo": cliente["estado"] == "activo"
            };
          }).toList();
          clientesFiltrados = List.from(clientes);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para filtrar clientes según la búsqueda
  void _filtrarClientes(String query) {
    setState(() {
      searchQuery = query;
      clientesFiltrados = clientes.where((cliente) {
        final nombreCompleto = cliente['nombre'].toLowerCase();
        final emailCliente = cliente['email'].toLowerCase();
        final queryLower = query.toLowerCase();

        return nombreCompleto.contains(queryLower) || emailCliente.contains(queryLower);
      }).toList();
    });
  }

  // Función para eliminar cliente del backend
  Future<void> eliminarCliente(String clienteId) async {
    try {
      final response = await http.delete(Uri.parse('http://192.168.39.186:8081/clientes/$clienteId'));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cliente eliminado correctamente'),
          backgroundColor: Colors.green,
        ));

        // Actualizar la lista de clientes después de la eliminación
        fetchClientes();
      } else {
        print('Error al eliminar cliente: ${response.statusCode}');
      }
    } catch (error) {
      print('Error al eliminar cliente: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Clientes',
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
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Barra de búsqueda
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Color(0xFFE4E4E4)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        _filtrarClientes(value);
                      },
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente',
                        hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                        suffixIcon: Icon(Icons.search, color: Color(0xFF828282)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista de clientes filtrados
                  Expanded(
                    child: ListView.builder(
                      itemCount: clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = clientesFiltrados[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                cliente['nombre'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                cliente['email'],
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  eliminarCliente(cliente['_id']);
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleCliente(clienteId: cliente['_id']),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarCliente,
        backgroundColor: Colors.red,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}




class DetalleCliente extends StatefulWidget {
  final String clienteId;

  DetalleCliente({required this.clienteId});

  @override
  _DetalleClienteState createState() => _DetalleClienteState();
}

class _DetalleClienteState extends State<DetalleCliente> {
  Map<String, dynamic> cliente = {};
  List<dynamic> historialCompras = [];
  bool isLoading = true;
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    fetchDetalleCliente();
  }

  Future<void> fetchDetalleCliente() async {
    final clienteId = widget.clienteId;
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/clientes/$clienteId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cliente = data['cliente'];
          historialCompras = data['historialCompras'];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los detalles del cliente: ${response.statusCode}');
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
          'Detalle del Cliente',
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
          : Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Datos del cliente
                  Text(
                    'Nombre: ${cliente['nombres']} ${cliente['apellidos']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Email: ${cliente['email']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Teléfono: ${cliente['telefono']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),

                  // Historial de compras
                  Text(
                    'Historial de Compras',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: historialCompras.isNotEmpty
                        ? ListView.builder(
                            itemCount: historialCompras.length,
                            itemBuilder: (context, index) {
                              final compra = historialCompras[index];
                              return Card(
                                elevation: 3,
                                child: ExpansionTile(
                                  title: Text(
                                    'Fecha de compra: ${compra['fechaCompra'].substring(0, 10)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(), // Evitar conflicto de scrolls
                                      itemCount: compra['productos'].length,
                                      itemBuilder: (context, prodIndex) {
                                        final producto = compra['productos'][prodIndex];
                                        return ListTile(
                                          title: Text(producto['nombre']),
                                          subtitle: Text('Cantidad: ${producto['cantidad']}'),
                                          trailing: Text(
                                            '\$${formatPrice(producto['subtotal'])}',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Total: \$${formatPrice(compra['total'])}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'No hay historial de compras',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}





class AgregarCliente extends StatefulWidget {
  @override
  _AgregarClienteState createState() => _AgregarClienteState();
}

class _AgregarClienteState extends State<AgregarCliente> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  TextEditingController nombreController = TextEditingController();
  TextEditingController apellidoController = TextEditingController();
  TextEditingController telefonoController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController confirmarEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmarPasswordController = TextEditingController();

  // Expresión regular para validar el formato de un correo electrónico
  final RegExp emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[cC][oO][mM]$");

  // Función para enviar los datos al backend y agregar el cliente
  Future<void> agregarCliente() async {
    final url = Uri.parse('http://192.168.39.186:8081/clientes/agregar'); // Reemplaza con tu URL del backend

    final body = json.encode({
      "_id": "C${DateTime.now().millisecondsSinceEpoch}", // Generar un ID temporal único
      "nombres": nombreController.text,
      "apellidos": apellidoController.text,
      "telefono": telefonoController.text,
      "email": emailController.text,
      "contraseña": passwordController.text, // Añadimos la contraseña
      "estado": "activo"
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 201) {
        // Si la solicitud fue exitosa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpiar todos los campos
        nombreController.clear();
        apellidoController.clear();
        telefonoController.clear();
        emailController.clear();
        confirmarEmailController.clear();
        passwordController.clear();
        confirmarPasswordController.clear();
        Navigator.pop(context, 'refresh');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar el cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF828282)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Agregar Cliente',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombres',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: telefonoController,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  } else if (value.length != 10) {
                    return 'El número debe tener 10 dígitos';
                  } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'El número solo debe contener dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  } else if (!emailRegExp.hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmarEmailController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Correo Electrónico',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != emailController.text) {
                    return 'Los correos electrónicos no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  } else if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmarPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      agregarCliente(); // Llamar a la función para agregar el cliente
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
                  ),
                  child: Text(
                    'Agregar Cliente',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
