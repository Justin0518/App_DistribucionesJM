const express = require('express');
const router = express.Router();
const upload = require('../libs/storage');
const  {obtenerSubcategoriasPorCategoria, updateSubcategoria} = require('../controllers/subcategoriasController');

// Ruta para obtener subcategorías por categoría ID
router.get('/:categoriaId', obtenerSubcategoriasPorCategoria);
// Ruta para actualizar una subcategoría (incluyendo imagen)
router.put('/:id', upload.single('image'), updateSubcategoria);

module.exports = router;