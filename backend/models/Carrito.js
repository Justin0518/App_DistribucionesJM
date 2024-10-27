const mongoose = require('mongoose');

const carritoSchema = new mongoose.Schema({
  clienteId: { type: String, required: true, ref: 'Cliente' },  // Referencia al cliente
  productos: [
    {
      _id: { type: String, ref: 'Producto', required: true },  // Referencia al producto
      nombre: { type: String },  // Nombre del producto obtenido de la BD
      cantidad: { type: Number, required: true },
      precio: { type: Number },  // Precio unitario
      imgUrl: { type: String },  // Imagen del producto
      subtotal: { type: Number, required: true }  // Subtotal calculado en base a la cantidad
    }
  ],
  total: { type: Number, default: 0 },  // Total del carrito
});

module.exports = mongoose.model('Carrito', carritoSchema);
