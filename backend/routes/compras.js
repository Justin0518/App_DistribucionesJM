const express = require('express');
const router = express.Router();
const { obtenerCompras,agregarCompra } = require('../controllers/comprasController');

// Ruta para obtener todas las compras
router.get('/', obtenerCompras);

// Ruta para agregar una compra
router.post('/agregar', agregarCompra);



module.exports = router;
