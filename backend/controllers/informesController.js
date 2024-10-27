const Compra = require('../models/Compra');
const Cliente = require('../models/Clientes');


exports.obtenerVentasTotales = async (req, res) => {
  try {
    const { fechaInicio, fechaFin } = req.query;

    const ventasTotales = await Compra.aggregate([
      {
        $match: {
          fechaCompra: {
            $gte: new Date(fechaInicio),
            $lte: new Date(fechaFin)
          }
        }
      },
      {
        $group: {
          _id: null,
          totalVentas: { $sum: "$total" },
          totalCompras: { $sum: 1 }
        }
      }
    ]);

    // Obtener el historial de ventas
    const historialVentas = await Compra.find({
      fechaCompra: {
        $gte: new Date(fechaInicio),
        $lte: new Date(fechaFin)
      }
    }).select('fechaCompra total'); // Aquí puedes seleccionar los campos que necesites

    res.status(200).json({
      totalVentas: ventasTotales[0]?.totalVentas || 0,
      totalCompras: ventasTotales[0]?.totalCompras || 0,
      historialVentas
    });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener las ventas totales', error });
  }
};

// Obtener productos más vendidos
exports.obtenerProductosMasVendidos = async (req, res) => {
  try {
    const { fechaInicio, fechaFin } = req.query;

    const productosMasVendidos = await Compra.aggregate([
      {
        $match: {
          fechaCompra: {
            $gte: new Date(fechaInicio),
            $lte: new Date(fechaFin)
          }
        }
      },
      { $unwind: "$productos" }, // Descomponer el array de productos
      {
        $group: {
          _id: "$productos._id",  // Agrupar por productoId
          nombreProducto: { $first: "$productos.nombre" },
          totalVendido: { $sum: "$productos.cantidad" }
        }
      },
      { $sort: { totalVendido: -1 } },  // Ordenar por la cantidad más alta
      { $limit: 5 } 
    ]);

    res.status(200).json(productosMasVendidos);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener los productos más vendidos', error });
  }
};



// Obtener clientes activos (que han hecho compras) y total de clientes
exports.obtenerClientesActivos = async (req, res) => {
  try {
    const { fechaInicio, fechaFin } = req.query;

    // Obtener el número total de clientes
    const totalClientes = await Cliente.countDocuments();

    // Obtener los clientes que han hecho compras en el rango de fechas
    const clientesActivos = await Compra.aggregate([
      {
        $match: {
          fechaCompra: {
            $gte: new Date(fechaInicio),
            $lte: new Date(fechaFin)
          }
        }
      },
      {
        $group: {
          _id: "$clienteId", // Agrupar por clienteId
        }
      }
    ]);

    res.status(200).json({
      totalClientes,
      clientesActivos: clientesActivos.length // Cantidad de clientes activos
    });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener los clientes activos', error });
  }
};
