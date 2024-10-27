const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    contraseña: { type: String, required: true },
})

module.exports = mongoose.model('Admin', adminSchema);
