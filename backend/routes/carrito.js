const express = require('express');
const router = express.Router();
const { obtenerCarrito, agregarProductoCarrito, actualizarCantidadProducto, eliminarProductoCarrito, vaciarCarrito } = require('../controllers/carritoController');

// Obtener el carrito del cliente
router.get('/:clienteId', obtenerCarrito);

// Agregar un producto al carrito
router.post('/agregar', agregarProductoCarrito);

// Actualizar la cantidad de un producto en el carrito
router.put('/actualizar', actualizarCantidadProducto);

// Eliminar un producto del carrito
router.delete('/:clienteId/producto/:productoId', eliminarProductoCarrito);

router.put('/vaciar/:clienteId',vaciarCarrito)

module.exports = router;
