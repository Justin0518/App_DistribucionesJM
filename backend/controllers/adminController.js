const Admin = require('../models/Admin');
const bcrypt = require('bcrypt');

// Controlador para el inicio de sesión del administrador
exports.loginAdmin = async (req, res) => {
  try {
    const { email, contraseña } = req.body;

    // Buscar al administrador por email
    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(404).json({ message: 'Administrador no encontrado' });
    }

    // Verificar la contraseña
    const isMatch = await bcrypt.compare(contraseña, admin.contraseña);
    if (!isMatch) {
      return res.status(401).json({ message: 'Contraseña incorrecta' });
    }

    // Si las credenciales son correctas
    res.status(200).json({ message: 'Inicio de sesión exitoso', adminId: admin._id });
  } catch (error) {
    res.status(500).json({ message: 'Error al iniciar sesión', error });
  }
};

// Crear un nuevo administrador (opcional, solo para pruebas)
exports.crearAdmin = async (req, res) => {
  try {
    const { email, contraseña } = req.body;

    // Hashear la contraseña antes de guardarla
    const hashedPassword = await bcrypt.hash(contraseña, 10);

    const nuevoAdmin = new Admin({
      email,
      contraseña: hashedPassword,
    });

    await nuevoAdmin.save();
    res.status(201).json({ message: 'Administrador creado exitosamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al crear administrador', error });
  }
};
