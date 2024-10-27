const mongoose = require('mongoose');
const { appConfig } = require('../config');

const subcategoriaSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  nombreSub: { type: String, required: true },
  categoriaId: { type: String, required: true, ref: 'Categoria' },
  imgUrl: String
});

subcategoriaSchema.methods.setImgUrl = function setImgUrl(filename) {
  const { host, port } = appConfig;
  this.imgUrl = `${host}:${port}/public/${filename}`; // Generar URL completa para la imagen
};

module.exports = mongoose.model('Subcategoria', subcategoriaSchema);
