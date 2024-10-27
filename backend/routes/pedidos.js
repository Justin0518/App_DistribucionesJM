const express = require('express');
const router = express.Router();
const {
  obtenerPedidos,
  obtenerPedidoPorId,
  actualizarPedido,
  eliminarPedido,
  obtenerPedidosPorCliente,
  pedidoNuevo,
  pedidosVistos
} = require('../controllers/pedidosController');


// Ruta para obtener los pedidos de un cliente específico
router.get('/cliente/:clienteId', obtenerPedidosPorCliente);

// Ruta para obtener nuevos pedidos
router.get('/recibido', pedidoNuevo);

// Ruta para marcar pedidos como vistos
router.put('/marcar', pedidosVistos);

// Ruta para obtener todos los pedidos
router.get('/', obtenerPedidos);

// Ruta para obtener un pedido por ID
router.get('/:id', obtenerPedidoPorId);

// Ruta para actualizar el estado de un pedido por ID
router.put('/:id', actualizarPedido);

// Ruta para eliminar un pedido por ID
router.delete('/:id', eliminarPedido);

module.exports = router;
