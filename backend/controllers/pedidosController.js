const Pedido = require('../models/Pedido');

// Obtener todos los pedidos
exports.obtenerPedidos = async (req, res) => {
    try {
      const pedidos = await Pedido.find();
      res.status(200).json(pedidos);
    } catch (error) {
      res.status(500).json({ message: 'Error al obtener pedidos', error });
    }
  };

// Obtener los pedidos de un cliente por su ID, incluyendo la dirección
exports.obtenerPedidosPorCliente = async (req, res) => {
  try {
    const clienteId = req.params.clienteId;
    
    // Encuentra los pedidos y realiza una referencia a la colección de Cliente para incluir la dirección
    const pedidos = await Pedido.find({ clienteId })
      .sort({ fechaCompra: -1 })
      .populate('clienteId', 'direccion nombres apellidos'); // Incluye dirección y otros campos relevantes del cliente

    if (pedidos.length === 0) {
      return res.status(404).json({ message: 'No se encontraron pedidos para este cliente' });
    }

    // Formatea cada pedido para incluir la dirección del cliente en la respuesta
    const pedidosConDireccion = pedidos.map(pedido => ({
      ...pedido.toObject(),
      direccion: pedido.clienteId.direccion, // Incluye la dirección en cada pedido
      nombreCliente: `${pedido.clienteId.nombres} ${pedido.clienteId.apellidos}`
    }));

    res.status(200).json(pedidosConDireccion);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener los pedidos', error });
  }
};

  
// Obtener un pedido por ID
exports.obtenerPedidoPorId = async (req, res) => {
  try {
    const pedido = await Pedido.findById(req.params.id);
    if (!pedido) {
      return res.status(404).json({ message: 'Pedido no encontrado' });
    }
    res.status(200).json(pedido);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener pedido', error });
  }
};

// Actualizar el estado de un pedido
exports.actualizarPedido = async (req, res) => {
  try {
    const { estado } = req.body;
    console.log(`Estado recibido: ${estado}`); 
    const pedidoActualizado = await Pedido.findByIdAndUpdate(req.params.id, { estado }, { new: true });
    if (!pedidoActualizado) {
      return res.status(404).json({ message: 'Pedido no encontrado' });
    }
    res.status(200).json(pedidoActualizado);
  } catch (error) {
    console.log('Error al actualizar el pedido:', error);
    res.status(500).json({ message: 'Error al actualizar el pedido', error });
  }
};

// Eliminar un pedido
exports.eliminarPedido = async (req, res) => {
  try {
    const pedidoEliminado = await Pedido.findByIdAndDelete(req.params.id);
    if (!pedidoEliminado) {
      return res.status(404).json({ message: 'Pedido no encontrado' });
    }
    res.status(200).json({ message: 'Pedido eliminado correctamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar pedido', error });
  }
};

exports.pedidoNuevo = async (req, res) => {
  try {
    console.log('Verificando si hay nuevos pedidos no vistos...');

    // Verificar si la base de datos está devolviendo pedidos no vistos
    const nuevosPedidos = await Pedido.find({ visto: false });
    console.log('Pedidos no vistos encontrados:', nuevosPedidos); // Esto mostrará los pedidos encontrados

    // Verificar si hay pedidos no vistos
    const hayNuevosPedidos = nuevosPedidos.length > 0;
    console.log('¿Hay nuevos pedidos?', hayNuevosPedidos);

    if (nuevosPedidos.length === 0) {
      return res.status(404).json({ message: 'No se encontraron pedidos para este cliente' });
    }
    // Enviar la respuesta
    res.json({ hayNuevosPedidos });
  } catch (error) {
    // Mostrar más detalles del error
    console.error('Error al verificar nuevos pedidos:', error);
    res.status(500).json({ message: 'Error al verificar nuevos pedidos', error: error.message });
  }
};


// Endpoint 2: Marcar pedidos como vistos
exports.pedidosVistos = async (req, res) => {
  try {
    await Pedido.updateMany({ visto: false }, { $set: { visto: true } }); // Marcar todos los pedidos no vistos como vistos
    res.status(200).json({ message: 'Pedidos marcados como vistos' });
  } catch (error) {
    console.error('Error al marcar pedidos como vistos:', error);
    res.status(500).json({ message: 'Error al marcar pedidos como vistos' });
  }
};