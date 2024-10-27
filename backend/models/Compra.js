const mongoose = require('mongoose');

const compraSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  clienteId: { type: String, required: true, ref: 'Cliente' },  // Referencia al cliente
  direccion: { type: String, required: true },
  productos: [
    {
      _id: { type: String, ref: 'Producto', required: true },  // Referencia al producto
      nombre: { type: String },  // Nombre del producto obtenido de la BD
      cantidad: { type: Number, required: true },
      precio: { type: Number }, 
      imgUrl: {type: String}, // Precio obtenido de la BD
      subtotal: { type: Number, required: true }
    }
  ],
  total: { type: Number, required: true },  // Precio total de la compra
  fechaCompra: { type: Date, default: Date.now }  // Fecha de la compra
});

module.exports = mongoose.model('Compra', compraSchema);
