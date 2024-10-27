const mongoose = require('mongoose');

const promocionSchema = new mongoose.Schema({
  _id: { type: String, required: true }, // ID personalizado
  titulo: { type: String, required: true },
  descripcion: { type: String, required: true },
  validoHasta: { type: Date, required: true },
  estado: { type: String, enum: ['activo', 'inactivo'], default: 'activo' },
});

module.exports = mongoose.model('Promocion', promocionSchema);
