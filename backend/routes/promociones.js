const express = require('express');
const router = express.Router();
const {
  agregarPromocion,
  obtenerPromociones,
  actualizarPromocion,
  eliminarPromocion
} = require('../controllers/promocionesController');

// Ruta para agregar una promoción
router.post('/agregar', agregarPromocion);

// Ruta para obtener todas las promociones
router.get('/', obtenerPromociones);

// Ruta para actualizar una promoción por ID
router.put('/:id', actualizarPromocion);

// Ruta para eliminar una promoción por ID
router.delete('/:id', eliminarPromocion);

module.exports = router;
