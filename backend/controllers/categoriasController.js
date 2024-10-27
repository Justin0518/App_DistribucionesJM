const Categoria = require('../models/Categoria');
const Product = require('../models/Product');
const fs = require('fs');
const path = require('path');

// Obtener categorías con sus productos
exports.obtenerCategoriasConProductos = async (req, res) => {
  try {
    // Obtener todas las categorías
    const categorias = await Categoria.find().lean();

    // Obtener productos para cada categoría
    const categoriasConProductos = await Promise.all(
      categorias.map(async (categoria) => {
        const productos = await Product.find({ categoriaId: categoria._id }).lean();
        return {
          ...categoria,
          productos, // Añadir productos a la categoría
        };
      })
    );

    res.status(200).json(categoriasConProductos);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener categorías con productos', error });
  }
};

// Obtener todas las categorías
exports.obtenerCategorias = async (req, res) => {
  try {
    const categorias = await Categoria.find();
    res.status(200).json(categorias);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener las categorías', error });
  }
};

// Función para eliminar una imagen del sistema
const eliminarImagen = (filename) => {
  const imagePath = path.join(__dirname, '../storage/imgs', filename);
  fs.unlink(imagePath, (err) => {
    if (err) {
      console.error(`Error al eliminar la imagen: ${err}`);
    } else {
      console.log('Imagen eliminada correctamente');
    }
  });
};

// Actualizar la categoría (incluyendo la imagen)
exports.updateCategoria = async (req, res) => {
  try {
    const { id } = req.params;
    const updateFields = req.body; // Campos que se quieren actualizar

    const categoria = await Categoria.findById(id);

    if (!categoria) {
      return res.status(404).send({ message: 'Categoria no encontrada' });
    }

    // Si se está subiendo una nueva imagen, elimina la imagen anterior
    if (req.file) {
      if (categoria.imgUrl) {
        const oldImage = categoria.imgUrl.split('/').pop(); // Obtener el nombre del archivo de la imagen anterior
        eliminarImagen(oldImage); // Eliminar la imagen anterior
      }
      const { filename } = req.file;
      categoria.setImgUrl(filename); // Asignar la nueva imagen
    }

    // Actualizar otros campos
    for (let key in updateFields) {
      categoria[key] = updateFields[key];
    }

    const categoriaUpdated = await categoria.save();

    res.status(200).send({ categoriaUpdated });
  } catch (e) {
    res.status(500).send({ message: e.message });
  }
};
