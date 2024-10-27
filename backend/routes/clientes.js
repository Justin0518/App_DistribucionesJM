const express = require('express');
const router = express.Router();
const {
  agregarCliente,
  obtenerClientes,
  actualizarCliente,
  eliminarCliente, 
  obtenerDetalleCliente,
  loginCliente,
  cambiarContraseña
} = require('../controllers/clientesController');

// Rutas más específicas primero

// Ruta para cambiar la contraseña
router.put('/cambiarContra', cambiarContraseña);

// Ruta para login
router.post('/login', loginCliente);

// Ruta para agregar un cliente
router.post('/agregar', agregarCliente);

// Rutas menos específicas

// Ruta para obtener todos los clientes
router.get('/', obtenerClientes);

// Ruta para obtener detalles de un cliente por ID
router.get('/:id', obtenerDetalleCliente);

// Ruta para actualizar un cliente por ID
router.put('/:id', actualizarCliente);

// Ruta para eliminar un cliente por ID
router.delete('/:id', eliminarCliente);


module.exports = router;
