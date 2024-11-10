import 'package:flutter/material.dart';
import 'package:jm_app/Cliente/carrito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jm_app/login.dart';
import 'package:intl/intl.dart';




class Inicio extends StatefulWidget {
  final VoidCallback openDrawer;
  final String clienteId; 
  final Function actualizarCarrito;

  Inicio({required this.openDrawer, required this.clienteId, required this.actualizarCarrito});

  @override
  _InicioState createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  List<dynamic> categorias = [];
  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];
  bool isLoading = true;
  int _precioMin = 0; // Rango de precio mínimo para filtrar
  int _precioMax = 100000; // Rango de precio máximo para filtrar
  String searchQuery = ""; // Variable para almacenar el texto de búsqueda
  // Formatear el precio en la vista
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();

    fetchCategorias(); // Obtener las categorías y productos desde el backend
  }




// Función para agregar un producto al carrito
  Future<void> agregarProductoAlCarrito(String clienteId, String productId, int cantidad) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.39.186:8081/carrito/agregar'), // Endpoint para agregar productos al carrito
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': clienteId, // Cliente que añade el producto
          'productoId': productId,
          'cantidad': cantidad, // Cantidad inicial, puedes cambiarla según el contexto
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto añadido al carrito')),
        );
        widget.actualizarCarrito(); 
      } else {
        throw Exception('Error al añadir el producto al carrito');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir el producto')),
      );
    }
  }    // Función para navegar a la pantalla de productos
  void verProductos(String clienteId, String categoriaId, String categoriaNombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductosScreen(clienteId: clienteId,categoriaId: categoriaId, categoriaNombre: categoriaNombre, actualizarCarrito: widget.actualizarCarrito),
      ),
    );
  }
  // Función para obtener las categorías con sus productos desde el backend
  Future<void> fetchCategorias() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/categorias/con-productos')); // Cambiar la URL
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categorias = data;
          // Filtrar solo productos activos
          productos = categorias.expand((categoria) => categoria['productos']).where((producto) => producto['estado'] == 'Activo').toList();
          productosFiltrados = List.from(productos); // Inicializa productosFiltrados con todos los productos
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las categorías con productos');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filtrar productos según la búsqueda
  void _filterProductos() {
    setState(() {
      if (searchQuery.isEmpty) {
        productosFiltrados = productos; // Mostrar todos los productos si no hay búsqueda
      } else {
        productosFiltrados = productos.where((producto) {
          return producto['nombreProducto']
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

// Función para abrir el modal de filtrado de precios
void _showPriceFilter() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filtrar por Precio",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Desde: \$${_precioMin}"),
                    Text("Hasta: \$${_precioMax}"),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.red[100],
                    thumbColor: Colors.red,
                    overlayColor: Colors.red.withOpacity(0.2),
                    valueIndicatorColor: Colors.red,
                  ),
                  child: RangeSlider(
                    values: RangeValues(
                      _precioMin.toDouble(),
                      _precioMax.toDouble(),
                    ),
                    min: 0,
                    max: 100000,
                    divisions: 50,
                    labels: RangeLabels(
                      "\$${_precioMin}",
                      "\$${_precioMax}",
                    ),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _precioMin = values.start.round(); // Convertir a int
                        _precioMax = values.end.round();   // Convertir a int
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyPriceFilter(); // Aplicar el filtro de precio
                    },
                    child: Text("Aplicar filtro", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


void _applyPriceFilter() {
  setState() {
    productosFiltrados = productos.where((producto) {
      int precio = producto['precio'] is int
          ? producto['precio']
          : (producto['precio'] ?? 0).toInt();
      return precio >= _precioMin && precio <= _precioMax;
    }).toList();
  }
}


  @override
  Widget build(BuildContext context) {
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                    ),

                    const SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15), // Aplica padding externo a todo el contenedor
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SearchScreen(clienteId: widget.clienteId, actualizarCarrito: widget.actualizarCarrito)),
                                );
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Color(0xFFE4E4E4)),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 15),
                                    Icon(Icons.search, color: Color(0xFF828282)),
                                    SizedBox(width: 10),
                                    Text(
                                      "Buscar productos...",
                                      style: TextStyle(color: Color(0xFFB0B0B0)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.filter_list),
                            onPressed: _showPriceFilter
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: categorias.map<Widget>((categoria) {
                        // Filtrar los productos de la categoría actual por precio
                        List<dynamic> productosFiltradosCategoria = categoria['productos']
                            .where((producto) =>
                                producto['estado'] == 'Activo' && // Solo productos activos
                                producto['precio'] >= _precioMin &&
                                producto['precio'] <= _precioMax) // Filtro de precio aplicado
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(categoria['nombreCategoria'], Icons.category),
                            _buildProductList(productosFiltradosCategoria),
                            if (categoria['productos'] != null && categoria['productos'].length > 5)
                              Center(
                                child: TextButton(
                                  onPressed: () => verProductos(
                                    widget.clienteId,
                                    categoria['_id'],
                                    categoria['nombreCategoria'],
                                  ),
                                  child: const Text(
                                    'Ver más',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),


                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellow),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProductList(List<dynamic> productosCategorias) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productosCategorias.length, 
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Navegar a la pantalla de detalle de producto cuando se toca una tarjeta
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleProducto(productId: productosCategorias[index]['_id'],clienteId: widget.clienteId, actualizarCarrito: widget.actualizarCarrito),
                ),
              );
            },
            child: _buildProductCard(productosCategorias[index]),
          );
        },
      ),
    );
  }

Widget _buildProductCard(Map<String, dynamic> producto) {
  bool sinStock = producto['cantidad'] == 0; // Verificamos si no hay stock

  return Container(
    width: 160, // Ajusta el ancho para cartas más grandes
    margin: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 9.0),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE4E4E4)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            image: DecorationImage(
              image: NetworkImage(producto['imgUrl']),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 35, // Ajustamos la altura para que todos los nombres ocupen el mismo espacio
                child: Text(
                  producto['nombreProducto'],
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  maxLines: 2, // Limitar a dos líneas
                  overflow: TextOverflow.ellipsis, // Si el texto es muy largo, usar puntos suspensivos
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\$${formatPrice(producto['precio'])}', // Formato de precio
                style: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity, // Asegura que el botón ocupe todo el ancho disponible
                height: 30, // Ajusta la altura del botón
                child: ElevatedButton(
                  onPressed: sinStock
                      ? null // Deshabilita el botón si no hay stock
                      : () {
                          // Si hay stock, agregar producto al carrito
                          agregarProductoAlCarrito(widget.clienteId, producto['_id'], 1);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sinStock ? Colors.white : Colors.red, // Fondo blanco si no hay stock
                    side: BorderSide(color: Colors.red), // Borde rojo
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                  ),
                  child: Text(
                    sinStock ? 'Sin stock' : 'Añadir al carrito', // Texto cambia según disponibilidad
                    style: TextStyle(
                      color: sinStock ? Colors.red : Colors.white, // Texto rojo si no hay stock, blanco si lo hay
                      fontSize: 12, // Ajustar tamaño de fuente si es necesario
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}


class DetalleProducto extends StatefulWidget {
  final String productId;
  final String clienteId;
  final Function actualizarCarrito;

  DetalleProducto({required this.productId, required this.clienteId, required this.actualizarCarrito});

  @override
  _DetalleProductoState createState() => _DetalleProductoState();
}

class _DetalleProductoState extends State<DetalleProducto> {
  Map<String, dynamic>? producto; // Producto obtenido desde el backend
  int cantidad = 1;
  bool isLoading = true;
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    fetchProducto(); // Obtener el producto por su ID
  }

  // Función para obtener los detalles del producto desde el backend
  Future<void> fetchProducto() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.39.186:8081/v1/products/${widget.productId}'), // Ajusta la URL según tu backend
      );

      if (response.statusCode == 200) {
        setState(() {
          producto = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener el producto');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para agregar el producto al carrito
  Future<void> agregarProductoAlCarrito() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.39.186:8081/carrito/agregar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': widget.clienteId,
          'productoId': widget.productId,
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto añadido al carrito')),
        );
        widget.actualizarCarrito();
      } else {
        throw Exception('Error al añadir el producto al carrito');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir el producto')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    bool sinStock = producto?['cantidad'] == 0; // Verificamos si el producto está sin stock

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF828282)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          producto?['nombreProducto'] ?? 'Cargando...',
          style: const TextStyle(
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del producto
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(producto?['imgUrl'] ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Nombre del producto
                    Text(
                      producto?['nombreProducto'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color.fromARGB(255, 37, 37, 37),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Precio del producto
                    Text(
                      '\$${formatPrice(producto?['precio'])}', // Formato de precio
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Descripción del producto
                    const Text(
                      'Descripción:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      producto?['descripcion'] ?? 'No disponible',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón de agregar al carrito
            Expanded(
              child: ElevatedButton(
                onPressed: sinStock ? null : agregarProductoAlCarrito,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sinStock ? null : Colors.red, // Sin fondo si no hay stock
                  side: BorderSide(color: Colors.red), // Borde rojo en cualquier estado
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  sinStock ? 'Sin stock' : 'Agregar al carrito',
                  style: TextStyle(
                    color: sinStock ? Colors.red : Colors.white, // Texto rojo si no hay stock, blanco si lo hay
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
class ProductosScreen extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;
  final String clienteId;
  final Function actualizarCarrito;

  ProductosScreen({required this.clienteId, required this.categoriaId, required this.categoriaNombre, required this.actualizarCarrito });

  @override
  _ProductosScreenState createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];
  bool isLoading = true;
  int _precioMin = 0; // Rango de precio mínimo para filtrar
  int _precioMax = 100000; // Rango de precio máximo para filtrar
  String searchQuery = ""; // Variable para almacenar el texto de búsqueda
  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    fetchProductos(); // Llamar para obtener los productos desde el backend
  }

// Función para agregar un producto al carrito
  Future<void> agregarProductoAlCarrito(String clienteId, String productId, int cantidad) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.39.186:8081/carrito/agregar'), // Endpoint para agregar productos al carrito
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': clienteId, // Cliente que añade el producto
          'productoId': productId,
          'cantidad': cantidad, // Cantidad inicial, puedes cambiarla según el contexto
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto añadido al carrito')),
        );
        widget.actualizarCarrito();
      } else {
        throw Exception('Error al añadir el producto al carrito');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir el producto')),
      );
    }
  }

  // Función para obtener los productos desde el backend
  Future<void> fetchProductos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/v1//categoria/${widget.categoriaId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productos = data;
          productosFiltrados = productos; // Inicialmente mostrar todos los productos
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los productos');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filtrar productos según la búsqueda
  void _filterProductos() {
    setState(() {
      productosFiltrados = productos.where((producto) {
        return producto['nombreProducto'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

// Función para abrir el modal de filtrado de precios
void _showPriceFilter() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filtrar por Precio",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Desde: \$${_precioMin}"),
                    Text("Hasta: \$${_precioMax}"),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.red[100],
                    thumbColor: Colors.red,
                    overlayColor: Colors.red.withOpacity(0.2),
                    valueIndicatorColor: Colors.red,
                  ),
                  child: RangeSlider(
                    values: RangeValues(_precioMin.toDouble(), _precioMax.toDouble()),
                    min: 0,
                    max: 100000,
                    divisions: 50,
                    labels: RangeLabels(
                      "\$${_precioMin}",
                      "\$${_precioMax}",
                    ),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _precioMin = values.start.toInt(); // Convertir de double a int
                        _precioMax = values.end.toInt();   // Convertir de double a int
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyPriceFilter(); // Aplicar el filtro de precio
                    },
                    child: Text("Aplicar filtro", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  // Aplicar el filtro de precios
  void _applyPriceFilter() {
    setState(() {
      productosFiltrados = productos.where((producto) {
        double precio = producto['precio'].toDouble();
        return precio >= _precioMin && precio <= _precioMax;
      }).toList();
    });
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
        title: Text(
          widget.categoriaNombre,
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFFFFFFF),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0, // Borde inferior
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFDFDDDD),
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Barra de búsqueda y botón de filtrar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0), // Ajusta el padding aquí
            child: Row(
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
                          _filterProductos(); // Filtrar productos al escribir en la barra de búsqueda
                        });
                      },
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto',
                        hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                        suffixIcon: Icon(Icons.search, color: Color(0xFF828282)), // Coloca el ícono a la derecha
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF828282)),
                  onPressed: _showPriceFilter, // Llamar al modal de filtrado
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: GridView.builder(
                      itemCount: productosFiltrados.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Número de columnas
                        childAspectRatio: 0.65, // Relación de aspecto para ajustar la altura de los productos
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final producto = productosFiltrados[index];
                        return _buildProductCard(producto);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

   // Función para construir cada carta de producto
  Widget _buildProductCard(dynamic producto) {
    bool sinStock = producto['cantidad'] == 0; // Verificar si no hay stock

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 9.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E4)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: NetworkImage(producto['imgUrl']), // Cargar imagen del producto
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40, // Ajustar la altura del contenedor de nombre
                  child: Text(
                    producto['nombreProducto'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Manejo de desbordamiento de texto
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${formatPrice(producto['precio'])}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width: double.infinity, // Ajustar el botón al ancho del contenedor
                  height: 30, // Ajustar la altura del botón
                  child: ElevatedButton(
                    onPressed: sinStock
                        ? null // Deshabilitar el botón si no hay stock
                        : () {
                            agregarProductoAlCarrito(widget.clienteId, producto['_id'], 1);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sinStock ? null : Colors.red, // Sin fondo si no hay stock
                      side: BorderSide(color: Colors.red), // Borde rojo en cualquier estado
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                    child: Text(
                      sinStock ? 'Sin stock' : 'Añadir al carrito',
                      style: TextStyle(
                        color: sinStock ? Colors.red : Colors.white, // Texto rojo si no hay stock, blanco si lo hay
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final String clienteId;
  final Function actualizarCarrito;

  SearchScreen({required this.clienteId, required this.actualizarCarrito});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];
  bool isLoading = true;
  String searchQuery = "";


  @override
  void initState() {
    super.initState();
    fetchProductos(); // Cargar todos los productos al inicio
  }

  Future<void> fetchProductos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.39.186:8081/v1/products')); // Cambia según tu endpoint correcto

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body); // Decodificar la respuesta
        setState(() {
          productos = data['products']; // Acceder al campo 'products' que contiene la lista de productos
          productosFiltrados = []; // Inicializar productosFiltrados vacío
          isLoading = false;
        });
        print('Productos cargados: ${productos.length}');
      } else {
        throw Exception('Error al obtener los productos');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterProductos(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        productosFiltrados = []; // Si no hay query, la lista filtrada está vacía
      } else {
        productosFiltrados = productos.where((producto) {
          final productoNombre = producto['nombreProducto'].toLowerCase();
          final input = searchQuery.toLowerCase();
          return productoNombre.contains(input);
        }).toList();
      }

      // Imprime la cantidad de productos filtrados para depuración
      print("Productos filtrados: ${productosFiltrados.length}");
    });
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
        title: TextField(
          autofocus: true, // Abre el teclado automáticamente
          onChanged: (value) => _filterProductos(value), // Filtrar productos al escribir
          decoration: InputDecoration(
            hintText: "Buscar productos...",
            border: InputBorder.none,
          ),
        ),
        actions: [
          
          IconButton(
            icon: Icon(Icons.close_sharp),
            onPressed: () {
              Navigator.pop(context); // Cierra la pantalla de búsqueda
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : searchQuery.isEmpty
              ? Container() // Pantalla en blanco cuando no hay nada escrito
              : ListView.builder(
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(productosFiltrados[index]['nombreProducto']),
                      onTap: () {
                        // Al tocar un producto, navega a su detalle
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleProducto(
                              productId: productosFiltrados[index]['_id'], clienteId: widget.clienteId, actualizarCarrito: widget.actualizarCarrito
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
