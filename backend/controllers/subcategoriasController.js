const Subcategoria = require('../models/Subcategoria');

// Obtener subcategorías por ID de categoría
exports.obtenerSubcategoriasPorCategoria = async (req, res) => {
    try {
      const { categoriaId } = req.params;
      const subcategorias = await Subcategoria.find({ categoriaId });
      res.status(200).json(subcategorias);
    } catch (error) {
      res.status(500).json({ message: 'Error al obtener las subcategorías', error });
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
exports.updateSubcategoria = async (req, res) => {
  try {
    const { id } = req.params;
    const updateFields = req.body; // Campos que se quieren actualizar

    const subcategoria = await Subcategoria.findById(id);

    if (!subcategoria) {
      return res.status(404).send({ message: 'Categoria no encontrada' });
    }

    // Si se está subiendo una nueva imagen, elimina la imagen anterior
    if (req.file) {
      if (subcategoria.imgUrl) {
        const oldImage = subcategoria.imgUrl.split('/').pop(); // Obtener el nombre del archivo de la imagen anterior
        eliminarImagen(oldImage); // Eliminar la imagen anterior
      }
      const { filename } = req.file;
      subcategoria.setImgUrl(filename); // Asignar la nueva imagen
    }

    // Actualizar otros campos
    for (let key in updateFields) {
      subcategoria[key] = updateFields[key];
    }

    const subcategoriaUpdated = await subcategoria.save();

    res.status(200).send({ subcategoriaUpdated });
  } catch (e) {
    res.status(500).send({ message: e.message });
  }
};