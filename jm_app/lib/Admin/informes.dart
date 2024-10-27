import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Necesario para el formato de fechas
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necesario para el formato de fechas

class Informes extends StatefulWidget {
  
  @override
  _InformesState createState() => _InformesState();
}

class _InformesState extends State<Informes> {
  DateTime? fechaInicio;
  DateTime? fechaFin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Informes',
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
      body: Column(
        children: [
          _buildDateRangePicker(),
          const SizedBox(height: 10),
          Flexible(
            child: _buildInformeCard(
              title: 'Ventas Totales',
              description: 'Ver el detalle completo de las ventas.',
              icon: Icons.attach_money,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformeVentasTotales(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _buildInformeCard(
              title: 'Productos Más Vendidos',
              description: 'Conoce los productos con más ventas.',
              icon: Icons.shopping_bag,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformeProductosMasVendidos(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _buildInformeCard(
              title: 'Clientes Activos',
              description: 'Detalles sobre los clientes más activos.',
              icon: Icons.people,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformeClientesActivos(
                      fechaInicio: fechaInicio,
                      fechaFin: fechaFin,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget para el rango de fechas
  Widget _buildDateRangePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fechaInicio != null && fechaFin != null
                ? 'Desde: ${DateFormat('dd/MM/yyyy').format(fechaInicio!)}\nHasta: ${DateFormat('dd/MM/yyyy').format(fechaFin!)}'
                : 'Seleccione un rango de fechas',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          ElevatedButton(
            onPressed: _selectDateRange,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Seleccionar Fechas', style: TextStyle(color: Colors.white)),

          ),
        ],
      ),
    );
  }

  // Función para abrir el selector de rango de fechas
  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: fechaInicio != null && fechaFin != null
          ? DateTimeRange(start: fechaInicio!, end: fechaFin!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        fechaInicio = picked.start;
        fechaFin = picked.end;
      });
    }
  }

Widget _buildInformeCard({
  required String title,
  required String description,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Ajusta el espacio entre las cartas
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85, // Ancho de las tarjetas
        height: 120, // Ajuste de altura
        child: Card(
          elevation: 3, // Reduce un poco la sombra para un aspecto más sutil
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Reduce el padding interno
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(icon, color: Colors.white),
                    radius: 30,
                  ),
                  const SizedBox(width: 16), // Espacio entre el icono y los textos
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}



class InformeVentasTotales extends StatefulWidget {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  InformeVentasTotales({required this.fechaInicio, required this.fechaFin});

  @override
  _InformeVentasTotalesState createState() => _InformeVentasTotalesState();
}

class _InformeVentasTotalesState extends State<InformeVentasTotales> {
  int totalVentas = 0;
  bool isLoading = true;
  List<dynamic> historialVentas = [];
    String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    fetchVentasTotales();
  }

  Future<void> fetchVentasTotales() async {
    try {
      final fechaInicio = widget.fechaInicio != null
          ? DateFormat('yyyy-MM-dd').format(widget.fechaInicio!)
          : '2024-01-01'; // Fecha predeterminada si no se selecciona
      final fechaFin = widget.fechaFin != null
          ? DateFormat('yyyy-MM-dd').format(widget.fechaFin!)
          : '2024-12-31'; // Fecha predeterminada si no se selecciona

      final response = await http.get(
        Uri.parse('http://192.168.247.186:8081/informes/ventas-totales?fechaInicio=$fechaInicio&fechaFin=$fechaFin'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalVentas = (data['totalVentas'] ?? 0).toInt();
          print(totalVentas);
          historialVentas = data['historialVentas'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las ventas totales');
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
      appBar: AppBar(
        title: const Text(
          'Ventas Totales',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFDFDDDD),
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de Ventas:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${formatPrice(totalVentas)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Historial de ventas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: historialVentas.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text('Venta #${index + 1}'),
                          subtitle: Text('Fecha: 2024-01-0${index + 1}'),

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
// Para formatear las fechas

class InformeProductosMasVendidos extends StatefulWidget {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  InformeProductosMasVendidos({this.fechaInicio, this.fechaFin});

  @override
  _InformeProductosMasVendidosState createState() => _InformeProductosMasVendidosState();
}

class _InformeProductosMasVendidosState extends State<InformeProductosMasVendidos> {
  List<dynamic> productosMasVendidos = [];
  bool isLoading = true;
    String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'es');
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    fetchProductosMasVendidos();
  }

  Future<void> fetchProductosMasVendidos() async {
    try {
      final fechaInicio = widget.fechaInicio != null
          ? DateFormat('yyyy-MM-dd').format(widget.fechaInicio!)
          : '2024-01-01';
      final fechaFin = widget.fechaFin != null
          ? DateFormat('yyyy-MM-dd').format(widget.fechaFin!)
          : '2024-12-31';

      final response = await http.get(
        Uri.parse(
          'http://192.168.247.186:8081/informes/productos-mas-vendidos?fechaInicio=$fechaInicio&fechaFin=$fechaFin',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productosMasVendidos = data; // Captura la lista de productos
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener productos más vendidos');
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
      appBar: AppBar(
        title: const Text(
          'Productos Más Vendidos',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFDFDDDD),
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ranking de Productos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: productosMasVendidos.isEmpty
                        ? Text('No se encontraron productos más vendidos.')
                        : ListView.builder(
                            itemCount: productosMasVendidos.length,
                            itemBuilder: (context, index) {
                              final producto = productosMasVendidos[index];
                              return Card(
                                elevation: 4,
                                child: ListTile(
                                  title: Text(producto['nombreProducto']),
                                  subtitle: Text('${formatPrice(producto['totalVendido'])} unidades vendidas'),
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
// Para formatear las fechas

class InformeClientesActivos extends StatefulWidget {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  InformeClientesActivos({this.fechaInicio, this.fechaFin});

  @override
  _InformeClientesActivosState createState() => _InformeClientesActivosState();
}

class _InformeClientesActivosState extends State<InformeClientesActivos> {
  int clientesActivos = 0;
  int totalClientes = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClientesActivos();
  }

  Future<void> fetchClientesActivos() async {
    try {
      final fechaInicio = widget.fechaInicio != null
          ? DateFormat('yyyy-MM-dd').format(widget.fechaInicio!)
          : '2024-01-01';
      final fechaFin = widget.fechaFin != null
          ? DateFormat('yyyy-MM-dd').format(widget.fechaFin!)
          : '2024-12-31';

      final response = await http.get(
        Uri.parse(
          'http://192.168.247.186:8081/informes/clientes-activos?fechaInicio=$fechaInicio&fechaFin=$fechaFin',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          clientesActivos = data['clientesActivos'] ?? 0;
          totalClientes = data['totalClientes'] ?? 0;
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los clientes activos');
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
      appBar: AppBar(
        title: const Text(
          'Clientes Activos',
          style: TextStyle(
            color: Color(0xFFEC2020),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFFDFDDDD),
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clientes Totales:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$totalClientes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Clientes Activos:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$clientesActivos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Lista de Clientes Activos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: clientesActivos, // Usa el número de clientes activos
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text('Cliente Activo #${index + 1}'),
                          subtitle: Text('Email: cliente${index + 1}@example.com'),
                          trailing: Icon(Icons.check_circle, color: Colors.green),
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
