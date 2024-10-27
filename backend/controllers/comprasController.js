const Compra = require('../models/Compra');
const Cliente = require('../models/Clientes');
const Carrito = require('../models/Carrito');
const Pedido = require('../models/Pedido'); // Importar el modelo de pedidos
const Secuencia = require('../models/Secuencia'); // Importar el modelo de secuencia

// Función para obtener el próximo código de compra
async function generarCodigoCompra() {
  try {
    const secuencia = await Secuencia.findOneAndUpdate(
      { nombre: 'compra' }, // Buscar la secuencia de compra
      { $inc: { valor: 1 } }, // Incrementar el valor en 1
      { new: true, upsert: true }  // Si no existe, crearla
    );
    return `C${secuencia.valor.toString().padStart(4, '0')}`; // Ejemplo: C0001, C0002...
  } catch (error) {
    throw new Error('Error al generar el código de compra');
  }
}

// Función para obtener el próximo código de pedido
async function generarCodigoPedido() {
  try {
    const secuencia = await Secuencia.findOneAndUpdate(
      { nombre: 'pedido' }, // Buscar la secuencia de pedido
      { $inc: { valor: 1 } }, // Incrementar el valor en 1
      { new: true, upsert: true }  // Si no existe, crearla
    );
    return `P${secuencia.valor.toString().padStart(4, '0')}`; // Ejemplo: P0001, P0002...
  } catch (error) {
    throw new Error('Error al generar el código de pedido');
  }
}



// Obtener todas las compras
exports.obtenerCompras = async (req, res) => {
  try {
    const compras = await Compra.find();
    res.status(200).json(compras);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener compras', error });
  }
};

// Confirmar la compra y crear un pedido basado en el carrito
exports.agregarCompra = async (req, res) => {

  const { clienteId, direccion } = req.body; // Recibimos la dirección en la solicitud
  
  try {
    // Verificar si el cliente existe
    const cliente = await Cliente.findById(clienteId);
    if (!cliente) {
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    // Verificar si la dirección está presente
    if (!direccion || direccion.trim() === '') {
      return res.status(400).json({ message: 'La dirección es requerida' });
    }

    // Obtener el carrito del cliente
    const carrito = await Carrito.findOne({ clienteId });
    if (!carrito || carrito.productos.length === 0) {
      return res.status(404).json({ message: 'El carrito está vacío o no existe' });
    }

    // Generar los códigos secuenciales para compra y pedido
    const nuevoCodigoCompra = await generarCodigoCompra();
    const nuevoCodigoPedido = await generarCodigoPedido();

    // Crear una nueva compra con los productos del carrito y la dirección
    const nuevaCompra = new Compra({
      _id: nuevoCodigoCompra,
      clienteId: clienteId,
      productos: carrito.productos, // Utilizar los productos del carrito
      total: carrito.total, // Usar el total del carrito
      fechaCompra: new Date(),
      direccion: direccion // Agregar la dirección en la compra
    });

    // Guardar la compra en la base de datos
    const compraGuardada = await nuevaCompra.save();

    // Crear un nuevo pedido basado en la compra y la dirección
    const nuevoPedido = new Pedido({
      _id: nuevoCodigoPedido,
      clienteId: clienteId,
      nombreCliente: `${cliente.nombres} ${cliente.apellidos}`, // Nombre del cliente
      estado: 'en preparación', // Estado inicial del pedido
      fechaCompra: nuevaCompra.fechaCompra,
      productos: carrito.productos, // Los productos que vienen del carrito
      total: carrito.total, 
      visto: false,
      direccion: direccion // Agregar la dirección en el pedido
    });

    // Guardar el nuevo pedido en la base de datos
    const pedidoGuardado = await nuevoPedido.save();

    // Vaciar el carrito después de confirmar la compra
    await Carrito.findOneAndUpdate(
      { clienteId },
      { $set: { productos: [], total: 0 } } // Vaciar los productos y el total
    );

    res.status(201).json({ message: 'Compra confirmada', compra: compraGuardada, pedido: pedidoGuardado });
  } catch (error) {
    console.error('Error al confirmar la compra y crear el pedido:', error);
    res.status(500).json({ message: 'Error al confirmar la compra y crear el pedido', error });
  }
};
