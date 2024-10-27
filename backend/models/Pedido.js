const mongoose = require('mongoose');

const pedidoSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  clienteId: { type: String, required: true },
  nombreCliente: { type: String, required: true },
  estado: { type: String, enum: ['en preparación', 'enviado', 'entregado'], default: 'en preparación' },
  fechaCompra: { type: Date, required: true, default: Date.now },
  direccion: { type: String, required: true },
  productos: [
    {
      _id: { type: String, ref: 'Producto', required: true }, 
      nombre: { type: String, required: true },  // Asegurarse de que el nombre del producto sea requerido y asignado
      cantidad: { type: Number, required: true },
      precio: { type: Number, required: true },  // Precio del producto desde la BD
      subtotal: { type: Number, required: true },
      imgUrl: {type: String, required: true}
    }
  ],
  total: { type: Number, required: true } ,
  visto: { type: Boolean, default: false } 
});

module.exports = mongoose.model('Pedido', pedidoSchema);
