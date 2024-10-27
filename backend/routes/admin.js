const express = require('express');
const { loginAdmin, crearAdmin } = require('../controllers/adminController');

const router = express.Router();

// Ruta para iniciar sesión como administrador
router.post('/login', loginAdmin);

// Ruta opcional para crear un nuevo administrador
router.post('/crear', crearAdmin);

module.exports = router;
