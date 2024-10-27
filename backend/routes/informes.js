const express = require('express');
const router = express.Router();
const {
  obtenerVentasTotales,
  obtenerProductosMasVendidos,
  obtenerClientesActivos
} = require('../controllers/informesController');

router.get('/ventas-totales', obtenerVentasTotales);
router.get('/productos-mas-vendidos', obtenerProductosMasVendidos);
router.get('/clientes-activos', obtenerClientesActivos);

module.exports = router;
