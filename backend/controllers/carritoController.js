const Carrito = require('../models/Carrito');
const Producto = require('../models/Product');

// Obtener el carrito del cliente
exports.obtenerCarrito = async (req, res) => {
  const { clienteId } = req.params;
  try {
    const carrito = await Carrito.findOne({ clienteId });
    if (!carrito) {
      return res.status(404).json({ message: 'Carrito no encontrado' });
    }
    res.status(200).json(carrito);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener el carrito', error });
  }
};

// Agregar producto al carrito
exports.agregarProductoCarrito = async (req, res) => {
  const { clienteId, productoId, cantidad } = req.body;

  try {
    // Verificar si el cliente tiene un carrito
    let carrito = await Carrito.findOne({ clienteId });
    if (!carrito) {
      carrito = new Carrito({ clienteId, productos: [] });
    }

    // Verificar si el producto ya está en el carrito
    const productoExistente = carrito.productos.find(p => p._id === productoId);

    if (productoExistente) {
      // Actualizar la cantidad y el subtotal si el producto ya existe en el carrito
      productoExistente.cantidad += cantidad;
      productoExistente.subtotal = productoExistente.cantidad * productoExistente.precio;
    } else {
      // Obtener el producto de la base de datos
      const producto = await Producto.findById(productoId);
      if (!producto) {
        return res.status(404).json({ message: 'Producto no encontrado' });
      }

      // Agregar nuevo producto al carrito
      carrito.productos.push({
        _id: producto._id,
        nombre: producto.nombreProducto,
        cantidad: cantidad,
        precio: producto.precio,
        imgUrl: producto.imgUrl,
        subtotal: producto.precio * cantidad
      });
    }

    // Recalcular el total del carrito
    carrito.total = carrito.productos.reduce((acc, p) => acc + p.subtotal, 0);

    // Guardar el carrito actualizado
    await carrito.save();

    res.status(200).json(carrito);
  } catch (error) {
    res.status(500).json({ message: 'Error al agregar producto al carrito', error });
  }
};

// Actualizar la cantidad de un producto en el carrito
exports.actualizarCantidadProducto = async (req, res) => {
  const { clienteId, productoId, nuevaCantidad } = req.body;

  try {
    const carrito = await Carrito.findOne({ clienteId });
    if (!carrito) {
      return res.status(404).json({ message: 'Carrito no encontrado' });
    }

    const producto = carrito.productos.find(p => p._id === productoId);
    if (!producto) {
      return res.status(404).json({ message: 'Producto no encontrado en el carrito' });
    }

    // Actualizar la cantidad y el subtotal del producto
    producto.cantidad = nuevaCantidad;
    producto.subtotal = nuevaCantidad * producto.precio;

    // Recalcular el total del carrito
    carrito.total = carrito.productos.reduce((acc, p) => acc + p.subtotal, 0);

    await carrito.save();

    res.status(200).json(carrito);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar el producto en el carrito', error });
  }
};

// Eliminar un producto del carrito
exports.eliminarProductoCarrito = async (req, res) => {
  const { clienteId, productoId } = req.params;

  try {
    const carrito = await Carrito.findOne({ clienteId });
    if (!carrito) {
      return res.status(404).json({ message: 'Carrito no encontrado' });
    }

    // Eliminar el producto del carrito
    carrito.productos = carrito.productos.filter(p => p._id !== productoId);

    // Recalcular el total del carrito
    carrito.total = carrito.productos.reduce((acc, p) => acc + p.subtotal, 0);

    await carrito.save();

    res.status(200).json(carrito);
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar el producto del carrito', error });
  }
};


exports.vaciarCarrito = async (req, res) => {
  const { clienteId } = req.params;
  try {
    // Vaciar el carrito del cliente
    await Carrito.findOneAndUpdate(
      { clienteId },
      { $set: { productos: [], total: 0 } }
    );
    res.status(200).json({ message: 'Carrito vaciado con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al vaciar el carrito', error });
  }
};