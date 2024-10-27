const mongoose = require('mongoose');

const clienteSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    nombres: { type: String, required: true },
    apellidos: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    telefono: { type: String, required: true },
    direccion: { type: String },
    estado: { type: String, enum: ['activo', 'inactivo'], default: 'activo' },
    contraseña: { type: String, required: true },
    isPasswordTemporary: { type: Boolean, default: true },

}, );

module.exports = mongoose.model('Clientes', clienteSchema);
