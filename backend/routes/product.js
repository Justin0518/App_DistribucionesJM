const express = require('express')
const upload = require('../libs/storage')
const { addProduct, getProducts, updateProduct, getProductById, deleteProduct, obtenerProductosPorSubcategoria, obtenerProductosPorCategoria } = require('../controllers/productController')
const api = express.Router()

api.post('/products', upload.single('image'), addProduct)
api.get('/products', getProducts)
api.put('/products/:id', upload.single('image'), updateProduct)
api.get('/products/:id', getProductById);
api.delete('/products/:id', deleteProduct);
api.get('/subcategoria/:subcategoriaId', obtenerProductosPorSubcategoria);
api.get('/categoria/:categoriaId', obtenerProductosPorCategoria);


module.exports = api