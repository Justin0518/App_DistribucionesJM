import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jm_app/login.dart';


class InventarioAdmin extends StatefulWidget {

  final VoidCallback openDrawer;

  InventarioAdmin({required this.openDrawer});

  @override
  _InventarioState createState() => _InventarioState();
}

class _InventarioState extends State<InventarioAdmin> {
  List<Map<String, dynamic>> productos = [];
  bool? mostrarActivos;
  String searchQuery = "";


  Future<void> fetchProductos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/v1/products/'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('products') && data['products'] != null) {
          final List<dynamic> productosData = data['products'];

          setState(() {
            productos = productosData.map((producto) => {
                  "nombre": producto["nombreProducto"],
                  "stock": producto["cantidad"],
                  "activo": producto["estado"] == "Activo",
                  "imgUrl": producto["imgUrl"] ?? '',
                  "_id": producto["_id"]
                }).toList();
          });
        } else {
          throw Exception('La clave "products" no se encuentra en la respuesta o es null');
        }
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en la conexión o la estructura de datos: $error');
    }
  }

  Future<void> updateProducto(String id, bool nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.39.186:8081/v1/products/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'estado': nuevoEstado ? 'Activo' : 'Inactivo',
        }),
      );

      if (response.statusCode == 200) {
        print('Producto actualizado correctamente.');
      } else {
        print('Error al actualizar producto: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en la conexión o actualización: $error');
    }
  }
void toggleProducto(int index, List<Map<String, dynamic>> productosFiltrados) {
  // Encuentra el producto en la lista original por su ID
  String productId = productosFiltrados[index]['_id'];
  int originalIndex = productos.indexWhere((producto) => producto['_id'] == productId);

  if (originalIndex != -1) {
    setState(() {
      // Cambia el estado del producto en la lista original
      productos[originalIndex]['activo'] = !productos[originalIndex]['activo'];

      // Actualiza también la lista filtrada (opcional)
      productosFiltrados[index]['activo'] = productos[originalIndex]['activo'];
    });

    // Llama a la función de actualización para sincronizar con el backend
    updateProducto(productId, productos[originalIndex]['activo']);
  } else {
    print('Error: No se encontró el producto en la lista original');
  }
}


  // Filtrar productos por búsqueda y estado (activo/inactivo)
  List<Map<String, dynamic>> _filterProducts(String query) {
    List<Map<String, dynamic>> productosFiltrados = productos;

    // Filtrar por búsqueda
    if (query.isNotEmpty) {
      productosFiltrados = productosFiltrados
          .where((producto) => producto['nombre'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    // Filtrar por estado (activo o inactivo)
    if (mostrarActivos != null) {
      productosFiltrados = productosFiltrados
          .where((producto) => producto['activo'] == mostrarActivos)
          .toList();
    }

    return productosFiltrados;
  }

void _showFilterOptions() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // Permite ajustar mejor el modal a la pantalla
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.35,  // Ajustamos la altura al 35% de la pantalla
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filtrar productos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Mostrar solo productos activos"),
                onTap: () {
                  setState(() {
                    mostrarActivos = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text("Mostrar solo productos inactivos"),
                onTap: () {
                  setState(() {
                    mostrarActivos = false;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text("Mostrar todos los productos"),
                onTap: () {
                  setState(() {
                    mostrarActivos = null;  // Mostrar todos
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}





  @override
  void initState() {
    super.initState();
    fetchProductos();
  }

  Future<void> _navigateToAddProduct() async {
    // Esperamos el resultado de la pantalla de agregar producto
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgregarProducto()),
    );

    // Si se agregó un producto, refrescamos la lista
    if (result != null && result == 'refresh') {
      fetchProductos();  // Volver a cargar los productos
    }
  }

  Future<void> _navigateToEditProduct(String productId) async {
    // Esperamos el resultado de la pantalla de editar producto
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetallesProducto(productId: productId)),
    );

    // Si se editó un producto, refrescamos la lista
    if (result != null && result == 'refresh') {
      fetchProductos();  // Volver a cargar los productos
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> productosFiltrados = _filterProducts(searchQuery);

   return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Stack(
          children: [
            AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff000000), Color(0xff434343)],
                    stops: [0, 1],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                ),
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
            Positioned(
              top: -103,
              left: 181,
              child: Container(
                width: 268,
                height: 249,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF2B109).withOpacity(0.07),
                      Color(0xFFE2590B).withOpacity(0.07),
                      Color(0xFFFF20909).withOpacity(0.07),
                    ],
                    stops: [0.5, 0.61, 0.81],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -103,
              left: 210,
              child: Container(
                width: 167,
                height: 167,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF2B109).withOpacity(0.9),
                      Color(0xFFE2590B).withOpacity(0.09),
                      Color(0xFFFF20909).withOpacity(0.09),
                    ],
                    stops: [0.5, 0.61, 0.81],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -46,
              left: 281,
              child: Container(
                width: 100,
                height: 83,
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
            Positioned(
              top: 29,
              left: 10,
              child: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF), size: 30),
                    onPressed: widget.openDrawer,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Container(
          child: Column(
            children: [
              
              const SizedBox(height: 15),
              // Logo en el centro de la pantalla
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                ),
              ),
              const SizedBox(height: 16),
              // Barra de búsqueda y filtrado
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
                          });
                        },
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto',
                          hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                          suffixIcon: Icon(Icons.search, color: Color(0xFF828282)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Color(0xFF828282)),
                    onPressed: _showFilterOptions,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Lista de productos
              Expanded(
                child: ListView.builder(
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _navigateToEditProduct(productosFiltrados[index]['_id']);
                      },
                      child: Card(
                        color: Color.fromARGB(255, 252, 251, 251),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          leading: productosFiltrados[index]['imgUrl'].isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(productosFiltrados[index]['imgUrl']),
                                  backgroundColor: Colors.transparent,
                                )
                              : CircleAvatar(
                                  child: Icon(Icons.person, color: Colors.white),
                                  backgroundColor: Colors.grey,
                                ),
                          title: Text(productosFiltrados[index]['nombre']),
                          subtitle: Text(
                              "Stock: ${productosFiltrados[index]['stock']} - ${productosFiltrados[index]['activo'] ? 'Activo' : 'Inactivo'}"),
                          trailing: Switch(
                            value: productosFiltrados[index]['activo'],
                            onChanged: (value) {
                              toggleProducto(index, productosFiltrados);
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,  // Llamar la función de navegación
        backgroundColor: Colors.red,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}





class AgregarProducto extends StatefulWidget {
  @override
  _AgregarProductoState createState() => _AgregarProductoState();
}

class _AgregarProductoState extends State<AgregarProducto> {
  final _formKey = GlobalKey<FormState>();
  String nombreProducto = '';
  int cantidadStock = 0;
  int precio = 0;
  String categoriaSeleccionada = ''; // Categoría seleccionada
  String subcategoriaSeleccionada = ''; // Subcategoría seleccionada
  List<Map<String, String>> categorias = [];// Lista de categorías obtenidas del backend
  List<Map<String, String>>subcategorias = []; // Lista de subcategorías relacionadas
  TextEditingController codigoProductoController = TextEditingController();
  TextEditingController nombreProductoController = TextEditingController();
  TextEditingController cantidadStockController = TextEditingController();
  TextEditingController precioController = TextEditingController();

  File? _image; // Almacenará la imagen seleccionada
  bool hasImage = false; // Nuevo estado que controla si hay una imagen seleccionada
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchCategorias(); // Cargar categorías desde el backend
  }

  // Función para seleccionar una imagen desde la galería
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path); // Guardamos la imagen seleccionada
        hasImage = true;  // Actualizamos el estado para indicar que hay una imagen
      } else {
        print('No se seleccionó ninguna imagen.');
      }
    });
  }

  Future<void> fetchCategorias() async {
    final response = await http.get(Uri.parse('http://192.168.39.186:8081/categorias/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        categorias = data.map((cat) {
          return {
            "id": cat['_id'] as String,
            "nombre": cat['nombreCategoria'] as String
          };
        }).toList().cast<Map<String, String>>();
        print('Categorías cargadas: $categorias');
      });
    } else {
      print('Error al cargar categorías: ${response.statusCode}');
    }
  }

  Future<void> fetchSubcategorias(String categoriaId) async {
    final response = await http.get(Uri.parse('http://192.168.39.186:8081/subcategorias/$categoriaId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        subcategorias = data.map((sub) {
          return {
            "id": sub['_id'] as String,
            "nombre": sub['nombreSub'] as String
          };
        }).toList().cast<Map<String, String>>();
      });
    } else {
      print('Error al cargar subcategorías: ${response.statusCode}');
    }
  }

  Future<void> agregarProducto() async {
    // Verifica que todos los campos estén completos antes de enviar
    if (nombreProducto.isEmpty || cantidadStock <= 0 || precio <= 0 || categoriaSeleccionada.isEmpty || subcategoriaSeleccionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Crear la solicitud multipart para enviar datos junto con la imagen
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('http://192.168.39.186:8081/v1/products')
      );

      // Agregar los campos de texto
      request.fields['nombreProducto'] = nombreProducto;
      request.fields['cantidad'] = cantidadStock.toString();
      request.fields['precio'] = precio.toString();
      request.fields['categoriaId'] = categoriaSeleccionada;
      request.fields['subcategoriaId'] = subcategoriaSeleccionada;

      // Verificar si la imagen fue seleccionada
      if (hasImage) {
        var imageStream = http.ByteStream(_image!.openRead());
        var imageLength = await _image!.length();
        var multipartFile = http.MultipartFile(
          'image',  // Nombre del campo en el backend
          imageStream, 
          imageLength,
          filename: _image!.path.split('/').last,
        );
        request.files.add(multipartFile);  // Adjuntar la imagen al request
      }

      // Enviar la solicitud
      var response = await request.send();

      // Procesar la respuesta
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpiar los controladores
        codigoProductoController.clear();
        nombreProductoController.clear();
        cantidadStockController.clear();
        precioController.clear();
        // Limpiar los campos después de agregar el producto
        setState(() {
          categoriaSeleccionada = '';
          subcategoriaSeleccionada = '';
          _image = null;  // Resetear la imagen seleccionada
          hasImage = false;  // Cambiar el estado de la imagen a "sin imagen"
        });
        Navigator.pop(context, 'refresh');
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: el código del producto ya existe'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar producto: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la solicitud HTTP: $error'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Agregar Producto',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFDFDDDD),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(  // Aquí agregamos el scroll
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage, // Al tocar la cámara, seleccionamos una imagen
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _image != null ? FileImage(_image!) : null, // Muestra la imagen si está seleccionada
                    child: _image == null
                        ? Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                        : null, // Si no hay imagen, muestra el ícono de cámara
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Nombre del producto
              TextField(
                controller: nombreProductoController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 253, 253, 253),
                  labelText: 'Nombre del Producto',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el nombre del producto',
                  hintStyle: TextStyle(color: Colors.grey),
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    nombreProducto = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Cantidad Disponible
              TextField(
                controller: cantidadStockController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 253, 253, 253),
                  labelText: 'Cantidad Disponible',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese la cantidad disponible',
                  hintStyle: TextStyle(color: Colors.grey),
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    cantidadStock = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Precio
              TextField(
                controller: precioController, 
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 253, 253, 253),
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese el precio',
                  hintStyle: TextStyle(color: Colors.grey),
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    precio = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Categoría
              DropdownButtonFormField<String>(
                value: categoriaSeleccionada.isNotEmpty ? categoriaSeleccionada : null,
                items: categorias.map<DropdownMenuItem<String>>((Map<String, String> categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria['id'],  // El valor del DropdownMenuItem debe ser un String (el ID de la categoría)
                    child: Text(categoria['nombre']!),  // El texto visible debe ser el nombre de la categoría
                  );
                }).toList(),  // Convierte la lista dinámica en una lista de DropdownMenuItem<String>
                onChanged: (String? nuevaCategoriaId) {
                  setState(() {
                    categoriaSeleccionada = nuevaCategoriaId!;
                  });
                  
                  // Llamar a la función para cargar subcategorías usando el ID de la categoría seleccionada
                  fetchSubcategorias(categoriaSeleccionada);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 253, 253, 253),
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subcategoría
              DropdownButtonFormField<String>(
                value: subcategoriaSeleccionada.isNotEmpty ? subcategoriaSeleccionada : null,
                items: subcategorias.map<DropdownMenuItem<String>>((Map<String, String> subcategoria) {
                  return DropdownMenuItem<String>(
                    value: subcategoria['id'],  // Usar el ID de la subcategoría
                    child: Text(subcategoria['nombre']!),
                  );
                }).toList(),
                onChanged: (String? nuevaSubcategoriaId) {
                  setState(() {
                    subcategoriaSeleccionada = nuevaSubcategoriaId!;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 253, 253, 253),
                  labelText: 'Subcategoría',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Botón de Guardar Producto
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    agregarProducto();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
                  ),
                  child: const Text('Agregar',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class DetallesProducto extends StatefulWidget {
  final String productId;

  DetallesProducto({required this.productId});

  @override
  _DetalleProductoState createState() => _DetalleProductoState();
}

class _DetalleProductoState extends State<DetallesProducto> {
  late TextEditingController nombreController;
  late TextEditingController cantidadController;
  late TextEditingController precioController;

  String categoriaSeleccionada = ''; // Categoría seleccionada
  String subcategoriaSeleccionada = ''; // Subcategoría seleccionada
  List<Map<String, String>> categorias = []; // Lista de categorías obtenidas del backend
  List<Map<String, String>> subcategorias = []; // Lista de subcategorías relacionadas

  String? imageUrl;  // Aquí manejaremos la URL de la imagen en lugar de un File
  File? _image;
  bool hasImage = false;
  final picker = ImagePicker();

  bool isLoading = true; // Para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    // Cargar los detalles del producto al iniciar
    fetchProducto(widget.productId);
  }

  // Función para obtener los detalles del producto desde la base de datos
  Future<void> fetchProducto(String id) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/v1/products/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nombreController = TextEditingController(text: data['nombreProducto']);
          cantidadController = TextEditingController(text: data['cantidad'].toString());
          precioController = TextEditingController(text: data['precio'].toString());

          categoriaSeleccionada = data['categoriaId'];
          subcategoriaSeleccionada = data['subcategoriaId'];

          // Asignar la URL de la imagen si existe
          imageUrl = data['imgUrl'] ?? '';
          isLoading = false; // Termina la carga
        });

        // Cargar categorías y subcategorías
        fetchCategorias();
        fetchSubcategorias(categoriaSeleccionada);
      } else {
        throw Exception('Error al cargar el producto: ${response.statusCode}');
      }
    } catch (error) {
      print('Error al cargar el producto: $error');
    }
  }

  // Función para seleccionar una imagen desde la galería
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path); // Guardamos la imagen seleccionada
        hasImage = true;
      }
    });
  }

  Future<void> fetchCategorias() async {
    final response = await http.get(Uri.parse('http://192.168.39.186:8081/categorias/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        categorias = data.map((cat) {
          return {
            "id": cat['_id'] as String,
            "nombre": cat['nombreCategoria'] as String
          };
        }).toList().cast<Map<String, String>>();
      });
    } else {
      print('Error al cargar categorías: ${response.statusCode}');
    }
  }

  Future<void> fetchSubcategorias(String categoriaId) async {
    final response = await http.get(Uri.parse('http://192.168.39.186:8081/subcategorias/$categoriaId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        subcategorias = data.map((sub) {
          return {
            "id": sub['_id'] as String,
            "nombre": sub['nombreSub'] as String
          };
        }).toList().cast<Map<String, String>>();
      });
    }  else {
      print('Error al cargar subcategorías: ${response.statusCode}');
    }
  }

  // Función para guardar los cambios
  Future<void> guardarCambios() async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://192.168.39.186:8081/v1/products/${widget.productId}'),
      );

      // Agregar los campos de texto
      request.fields['nombreProducto'] = nombreController.text;
      request.fields['cantidad'] = cantidadController.text;
      request.fields['precio'] = precioController.text;
      request.fields['categoriaId'] = categoriaSeleccionada;
      request.fields['subcategoriaId'] = subcategoriaSeleccionada;

      // Verificar si se seleccionó una nueva imagen
      if (hasImage) {
        var imageStream = http.ByteStream(_image!.openRead());
        var imageLength = await _image!.length();
        var multipartFile = http.MultipartFile(
          'image',  // Nombre del campo de la imagen en el backend
          imageStream,
          imageLength,
          filename: _image!.path.split('/').last,
        );
        request.files.add(multipartFile); // Adjuntar la imagen al request
      }

      // Enviar la solicitud
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'refresh'); // Regresar a la pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el producto: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la solicitud HTTP: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para eliminar el producto
  Future<void> eliminarProducto() async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.39.186:8081/v1/products/${widget.productId}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'refresh'); // Regresar y refrescar la pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el producto: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la solicitud HTTP: $error'),
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
          'Editar Producto',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: hasImage && _image != null
                              ? FileImage(_image!)
                              : (imageUrl != null && imageUrl!.isNotEmpty)
                                  ? NetworkImage(imageUrl!) as ImageProvider
                                  : null,
                          child: (_image == null && (imageUrl == null || imageUrl!.isEmpty)) 
                            ? Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                            : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Nombre del producto
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 253, 253, 253),
                        labelText: 'Nombre del Producto',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Cantidad Disponible
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 253, 253, 253),
                        labelText: 'Cantidad Disponible',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Precio
                    TextField(
                      controller: precioController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 253, 253, 253),
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Categoría
                    DropdownButtonFormField<String>(
                      value: categoriaSeleccionada,
                      items: categorias.map<DropdownMenuItem<String>>((Map<String, String> categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria['id'],
                          child: Text(categoria['nombre']!),
                        );
                      }).toList(),
                      onChanged: (String? nuevaCategoriaId) {
                        setState(() {
                          categoriaSeleccionada = nuevaCategoriaId!;
                        });
                        fetchSubcategorias(categoriaSeleccionada);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 253, 253, 253),
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Subcategoría
                    DropdownButtonFormField<String>(
                      value: subcategorias.isNotEmpty 
                        ? subcategorias.firstWhere(
                            (subcategoria) => subcategoria['id'] == subcategoriaSeleccionada, 
                            orElse: () => {"id": ""})['id']  // Si no se encuentra, devuelve un mapa con id vacío
                        : null,
                      items: subcategorias.map<DropdownMenuItem<String>>((Map<String, String> subcategoria) {
                        return DropdownMenuItem<String>(
                          value: subcategoria['id'],  // Usar el ID de la subcategoría
                          child: Text(subcategoria['nombre']!),  // Mostrar el nombre de la subcategoría
                        );
                      }).toList(),
                      onChanged: (String? nuevaSubcategoriaId) {
                        setState(() {
                          subcategoriaSeleccionada = nuevaSubcategoriaId!;
                          print('Nueva subcategoría seleccionada: $subcategoriaSeleccionada');
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 253, 253, 253),
                        labelText: 'Subcategoría',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    // Botón de Guardar Cambios
                    Center(
                      child: ElevatedButton(
                        onPressed: guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        ),
                        child: const Text('Guardar cambios', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20), // Separación entre los botones
                    // Botón de Eliminar Producto
                    Center(
                      child: ElevatedButton(
                        onPressed: eliminarProducto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        ),
                        child: const Text('Eliminar Producto', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
