const Clientes = require('../models/Clientes');
const Compra = require('../models/Compra');
const Secuencia = require('../models/Secuencia');
const bcrypt = require('bcrypt');

// Función para obtener el próximo código de compra
async function generarCodigoCliente() {
  try {
    const secuencia = await Secuencia.findOneAndUpdate(
      { nombre: 'cliente' }, // Buscar la secuencia de compra
      { $inc: { valor: 1 } }, // Incrementar el valor en 1
      { new: true, upsert: true }  // Si no existe, crearla
    );
    return `Cl${secuencia.valor.toString().padStart(3, '0')}`; // Ejemplo: C0001, C0002...
  } catch (error) {
    throw new Error('Error al generar el código de compra');
  }
}


// Agregar un nuevo cliente
exports.agregarCliente = async (req, res) => {
  try {
    const { nombres, apellidos, email, telefono, direccion, estado, contraseña } = req.body;

    // Verificar si los campos obligatorios están presentes
    if (!nombres || !apellidos || !email || !telefono || !contraseña) {
      return res.status(400).json({ message: 'Por favor, complete todos los campos obligatorios' });
    }

    // Verificar si el correo ya existe en la base de datos
    const clienteExistente = await Clientes.findOne({ email });
    if (clienteExistente) {
      return res.status(400).json({ message: 'El correo electrónico ya está en uso' });
    }

    // Generar un código único para el cliente
    const nuevoCodigoCliente = await generarCodigoCliente();

    // Encriptar la contraseña usando bcrypt
    const salt = await bcrypt.genSalt(10);
    const contraseñaEncriptada = await bcrypt.hash(contraseña, salt);

    // Crear un nuevo cliente con la contraseña encriptada
    const nuevoCliente = new Clientes({
      _id: nuevoCodigoCliente,  // Usamos el _id personalizado
      nombres,
      apellidos,
      email,
      telefono,
      direccion,
      estado,
      contraseña: contraseñaEncriptada, // Guardamos la contraseña encriptada
    });

    // Guardar el cliente en la base de datos
    await nuevoCliente.save();
    res.status(201).json({ message: 'Cliente agregado exitosamente', cliente: nuevoCliente });
  } catch (error) {
    // Si ocurre un error relacionado con un correo electrónico duplicado
    if (error.code === 11000) {
      return res.status(400).json({ message: 'El correo electrónico ya está en uso' });
    }
    console.error('Error al agregar cliente:', error);
    // Si ocurre otro tipo de error
    res.status(500).json({ message: 'Error al agregar cliente', error });
  }
};



// Obtener todos los clientes
exports.obtenerClientes = async (req, res) => {
  try {
    const clientes = await Clientes.find();
    res.status(200).json(clientes);
    console.log('hola');
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener clientes', error });
  }
};

// Actualizar un cliente
exports.actualizarCliente = async (req, res) => {
  try {
    const { id } = req.params;
    const clienteActualizado = await Clientes.findByIdAndUpdate(id, req.body, { new: true });
    if (!clienteActualizado) {
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }
    res.status(200).json(clienteActualizado);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar cliente', error });
  }
};

// Eliminar un cliente
exports.eliminarCliente = async (req, res) => {
  try {
    const { id } = req.params;
    const clienteEliminado = await Clientes.findByIdAndDelete(id);
    if (!clienteEliminado) {
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }
    res.status(200).json({ message: 'Cliente eliminado correctamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar cliente', error });
  }
};



// Obtener detalles de un cliente con historial de compras
exports.obtenerDetalleCliente = async (req, res) => {
  try {
    const { id } = req.params;

    // Encontrar el cliente por su ID
    const cliente = await Clientes.findById(id);
    if (!cliente) {
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    // Obtener el historial de compras del cliente
    const historialCompras = await Compra.find({ clienteId: id });

    // Devolver los detalles del cliente y su historial de compras
    res.status(200).json({
      cliente,
      historialCompras
    });
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener los detalles del cliente', error });
  }
};


exports.loginCliente = async (req, res) => {
  const { email, contraseña } = req.body;

  try {
    const cliente = await Clientes.findOne({ email });
    if (!cliente) {
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    const isMatch = await bcrypt.compare(contraseña, cliente.contraseña);
    if (!isMatch) {
      return res.status(401).json({ message: 'Contraseña incorrecta' });
    }
    // Retornar el cliente con su _id
    return res.status(200).json({ _id: cliente._id, isPasswordTemporary: cliente.isPasswordTemporary});


    if (cliente.isPasswordTemporary) {
      return res.status(200).json({ message: 'Contraseña temporal, necesita ser actualizada', requiresPasswordChange: true });
    }

    // Si la contraseña no es temporal
    return res.status(200).json({ message: 'Login exitoso', requiresPasswordChange: false });
  } catch (error) {
    res.status(500).json({ message: 'Error en el servidor', error });
  }
};

exports.cambiarContraseña = async (req, res) => {
  console.log('Ruta cambiar-contraseña fue llamada');  // Verifica que la ruta se llama
  const { email, nuevaContraseña } = req.body;

  try {
    const cliente = await Clientes.findOne({ email });
    if (!cliente) {
      console.log('Cliente no encontrado:', email);
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    const salt = await bcrypt.genSalt(10);
    const contraseñaHasheada = await bcrypt.hash(nuevaContraseña, salt);

    cliente.contraseña = contraseñaHasheada;
    cliente.isPasswordTemporary = false;
    await cliente.save();

    res.status(200).json({ message: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    console.log('Error:', error);
    res.status(500).json({ message: 'Error al actualizar la contraseña', error });
  }
};
