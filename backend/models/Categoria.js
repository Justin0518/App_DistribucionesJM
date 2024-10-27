const mongoose = require('mongoose');
const { appConfig } = require('../config');

const categoriaSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  nombreCategoria: { type: String, required: true },
  imgUrl: String
});

categoriaSchema.methods.setImgUrl = function setImgUrl(filename) {
  const { host, port } = appConfig;
  this.imgUrl = `${host}:${port}/public/${filename}`; // Generar URL completa para la imagen
};

module.exports = mongoose.model('Categoria', categoriaSchema);

