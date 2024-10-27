import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Categorias extends StatefulWidget {

  final String clienteId; 
  final Function actualizarCarrito;

  Categorias({required this.clienteId, required this.actualizarCarrito});

  @override
  _CategoriasState createState() => _CategoriasState();
}

class _CategoriasState extends State<Categorias> {
  List<dynamic> categorias = [];
  List<dynamic> subcategorias = [];
  bool isLoading = true;
  bool mostrandoSubcategorias = false;
  String? categoriaSeleccionadaId;
  String? categoriaSeleccionadaNombre; // Variable para almacenar el nombre de la categoría seleccionada


  @override
  void initState() {
    super.initState();
    fetchCategorias(); // Llamar para obtener las categorías desde el backend
  }

  // Función para obtener las categorías desde el backend
  Future<void> fetchCategorias() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/categorias/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categorias = data;
          isLoading = false;
          mostrandoSubcategorias = false; // Asegurarse de mostrar categorías
        });
      } else {
        throw Exception('Error al obtener las categorías');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }
    // Función para navegar a la pantalla de productos
  void verProductos(String clienteId, String subcategoriaId, String subcategoriaNombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductosScreen(clienteId: clienteId,subcategoriaId: subcategoriaId, subcategoriaNombre: subcategoriaNombre, actualizarCarrito: widget.actualizarCarrito),
      ),
    );
  }

  // Función para obtener las subcategorías desde el backend
  Future<void> fetchSubcategorias(String categoriaId, String categoriaNombre) async {
    try {
      setState(() {
        isLoading = true; // Mostrar indicador de carga
        categoriaSeleccionadaNombre = categoriaNombre; // Guardar el nombre de la categoría seleccionada
      });
      final response = await http.get(Uri.parse('http://192.168.247.186:8081/subcategorias/$categoriaId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          subcategorias = data;
          mostrandoSubcategorias = true; // Cambiar el estado para mostrar subcategorías
          categoriaSeleccionadaId = categoriaId;
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las subcategorías');
      }
    } catch (error) {
      print('Error al conectar con el backend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para regresar a la lista de categorías
  void mostrarCategorias() {
    setState(() {
      mostrandoSubcategorias = false; // Volver a mostrar categorías
      categoriaSeleccionadaNombre = null; // Limpiar el nombre de la categoría seleccionada
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: mostrandoSubcategorias
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Color(0xFF828282)),
                onPressed: mostrarCategorias, // Regresar a las categorías
              )
            : null,
        title: Text(
          mostrandoSubcategorias ? categoriaSeleccionadaNombre ?? 'Subcategorías' : 'Categorías',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: ListView.builder(
                itemCount: mostrandoSubcategorias ? subcategorias.length : categorias.length,
                padding: EdgeInsets.symmetric(vertical: 40.0),
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (!mostrandoSubcategorias) {
                    // Mostrando las categorías
                    final categoria = categorias[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: Image.network(
                            categoria['imgUrl'], // Cargar la imagen desde la URL
                            width: 85,
                            height: 85,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            categoria['nombreCategoria'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                          onTap: () => fetchSubcategorias(categoria['_id'], categoria['nombreCategoria']), // Cargar subcategorías y pasar el nombre de la categoría
                        ),
                        SizedBox(height: 30),
                        Container(
                          color: Color(0xFFDFDDDD),
                          height: 1,
                        ),
                        if (index == categorias.length - 1) // Si es el último elemento
                          SizedBox(height: 0) // Eliminar el espacio adicional en blanco
                        else
                          SizedBox(height: 50), // Mantener el espaciado entre las categorías
                      ],
                    );
                  } else {
                    // Mostrando las subcategorías
                    final subcategoria = subcategorias[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: Image.network(
                          subcategoria['imgUrl'], // Cargar la imagen desde la URL
                            width: 85,
                            height: 85,
                            fit: BoxFit.cover,
                          ),// Ajustar el ícono de la subcategoría
                          title: Text(
                            subcategoria['nombreSub'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                          onTap: () => verProductos(widget.clienteId, subcategoria['_id'], subcategoria['nombreSub']), // Navegar a la pantalla de productos
                        ),
                        SizedBox(height: 30),
                        Container(
                          color: Color(0xFFDFDDDD),
                          height: 1,
                        ),
                        if (index == subcategorias.length - 1) // Si es el último elemento
                          SizedBox(height: 0) // Eliminar el espacio adicional en blanco
                        else
                          SizedBox(height: 50), // Mantener el espaciado entre las categorías
                      ],
                    );
                  }
                },
              ),
            ),
    );
  }
}



class ProductosScreen extends StatefulWidget {
  final String subcategoriaId;
  final String subcategoriaNombre;
  final String clienteId; 
  final Function actualizarCarrito;

  ProductosScreen({required this.clienteId, required this.subcategoriaId, required this.subcategoriaNombre, required this.actualizarCarrito});

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
  int carritoCount = 0;
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
        Uri.parse('http://192.168.247.186:8081/carrito/agregar'), // Endpoint para agregar productos al carrito
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

Future<void> fetchProductos() async {
  try {
    print("Fetching products for subcategory ID: ${widget.subcategoriaId}");
    final response = await http.get(Uri.parse('http://192.168.247.186:8081/v1/subcategoria/${widget.subcategoriaId.trim()}'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      print("Productos recibidos: ${data.length}");  // Muestra la cantidad de productos recibidos
      setState(() {
        productos = data
          .where((producto) => producto['estado'] == 'Activo')
          .toList();
        
        print("Productos filtrados: ${productos.length}"); // Verifica que el filtrado funcione
        
        productosFiltrados = productos; // Asigna todos los productos filtrados a productosFiltrados
        isLoading = false;
      });
    } else {
      print("Error HTTP: ${response.statusCode}, respuesta: ${response.body}");
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
  setState(() {
    productosFiltrados = productos.where((producto) {
      int precio = producto['precio'] is int
          ? producto['precio']
          : (producto['precio'] ?? 0).toInt();    
      
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
          widget.subcategoriaNombre,
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


Widget _buildProductCard(Map<String, dynamic> producto) {
  bool sinStock = producto['cantidad'] == 0; // Verificamos si no hay stock

  return GestureDetector(
    onTap: () {
      // Navegar a la pantalla de detalle del producto
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleProducto(
            productId: producto['_id'], // ID del producto
            clienteId: widget.clienteId, // ID del cliente
            actualizarCarrito: widget.actualizarCarrito, // Función de actualización del carrito
          ),
        ),
      );
    },
    child: Container(
      width: 160, // Ajusta el ancho para cartas más grandes
      margin: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 20.0),
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
                  '\$${formatPrice(producto['precio'])}',
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
        Uri.parse('http://192.168.247.186:8081/v1/products/${widget.productId}'), // Ajusta la URL según tu backend
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
        Uri.parse('http://192.168.247.186:8081/carrito/agregar'),
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
                    '\$${formatPrice(producto?['precio'])}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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