const mongoose = require('mongoose');

const secuenciaSchema = new mongoose.Schema({
  nombre: { type: String, required: true, unique: true }, // Para distinguir entre 'pedido' y 'compra'
  valor: { type: Number, default: 0 }  // El valor actual de la secuencia
});

module.exports = mongoose.model('Secuencia', secuenciaSchema);
