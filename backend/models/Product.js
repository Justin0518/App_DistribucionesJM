const mongoose = require('mongoose')
const { appConfig } = require('../config')

const Schema = mongoose.Schema

const ProductSchema = Schema({
  _id: String, 
  nombreProducto: String,
  cantidad: Number,
  categoriaId: String,
  subcategoriaId: String, 
  precio: Number,
  estado: String,
  imgUrl: String,
  descripcion: String
}, {
})

ProductSchema.methods.setImgUrl = function setImgUrl (filename) {
  const { host, port } = appConfig
  this.imgUrl = `${host}:${port}/public/${filename}`
}

module.exports = mongoose.model('Products', ProductSchema)