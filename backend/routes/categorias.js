const express = require('express');
const router = express.Router();
const upload = require('../libs/storage');
const { obtenerCategorias, updateCategoria, obtenerCategoriasConProductos } = require('../controllers/categoriasController');

// Ruta para obtener todas las categorías
router.get('/', obtenerCategorias);

// Ruta para actualizar una categoría (incluyendo imagen)
router.put('/:id', upload.single('image'), updateCategoria);

// Ruta para obtener categorías con sus productos
router.get('/con-productos', obtenerCategoriasConProductos); 

module.exports = router;
