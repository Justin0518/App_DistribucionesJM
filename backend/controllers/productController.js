const fs = require('fs'); // Para manejar la eliminación de archivos
const path = require('path');
const Product = require('../models/Product');
const Secuencia = require('../models/Secuencia'); // Importar el modelo de secuencia

// Función para generar el próximo código de producto
async function generarCodigoProducto() {
  try {
    const secuencia = await Secuencia.findOneAndUpdate(
      { nombre: 'producto' },  // Buscar la secuencia de productos
      { $inc: { valor: 1 } },  // Incrementar el valor en 1
      { new: true, upsert: true }  // Si no existe, crearla
    );
    const codigoProducto = `P${(secuencia.valor).toString().padStart(3, '0')}`;  // Empieza desde P004
    return codigoProducto;  
  } catch (error) {
    throw new Error('Error al generar el código de producto');
  }
}

// Función para eliminar una imagen del servidor
const eliminarImagen = (imagenPath) => {
  const fullPath = path.join(__dirname, '../storage/imgs', imagenPath);
  if (fs.existsSync(fullPath)) {
    fs.unlink(fullPath, (err) => {
      if (err) {
        console.error('Error al eliminar la imagen:', err);
      } else {
        console.log('Imagen eliminada:', imagenPath);
      }
    });
  }
};

async function addProduct (req, res) {
  try {
    const {
        nombreProducto,
        cantidad,
        categoriaId,
        subcategoriaId, 
        precio,
        estado,
        descripcion
    } = req.body

    // Generar el código del producto
    const nuevoCodigoProducto = await generarCodigoProducto();

    const product = new Product({
        _id: nuevoCodigoProducto,
        nombreProducto,
        cantidad,
        categoriaId,
        subcategoriaId, 
        precio,
        estado,
        descripcion
    });

    if (req.file) {
      const { filename } = req.file;
      product.setImgUrl(filename);
    }
        // Verificar si el producto ya existe
    const productoExistente = await Product.findOne({ nombreProducto });
    if (productoExistente) {
      return res.status(409).json({ message: 'El nombre del producto ya existe' });
    }

    const productStored = await product.save();
    res.status(201).send({ productStored });
  } catch (e) {
    res.status(500).send({ message: e.message });
  }
}
// Controlador para eliminar un producto
async function deleteProduct (req, res) {
  try {
    const { id } = req.params;

    const productoEliminado = await Product.findByIdAndDelete(id);
    if (!productoEliminado) {
      return res.status(404).json({ message: 'Producto no encontrado' });
    }

    res.status(200).json({ message: 'Producto eliminado exitosamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar el producto', error });
  }
};

async function getProductById(req, res) {
  try {
    
    const productoId = req.params.id;  // Extraemos el id del parámetro de la ruta
    const producto = await Product.findById(productoId);  // Buscar producto por su _id

    if (!producto) {
      return res.status(404).json({ message: 'Producto no encontrado' });
    }

    res.status(200).json(producto);  // Enviar los detalles del producto
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener el producto', error });
  }
};
// Controlador para obtener productos por categoría
async function obtenerProductosPorCategoria (req, res) {
  try {
    const { categoriaId } = req.params;

    // Asegúrate de que el subcategoriaId esté correctamente trimmeado y en el formato correcto
    const productos = await Product.find({ categoriaId: categoriaId.trim() });

    if (!productos || productos.length === 0) {
      return res.status(404).json({ message: 'No se encontraron productos para esta categoría' });
    }

    res.status(200).json(productos);
  } catch (error) {
    console.error('Error al obtener productos por categoría:', error);
    res.status(500).json({ message: 'Error al obtener productos', error });
  }
};

// Controlador para obtener productos por subcategoría
async function obtenerProductosPorSubcategoria (req, res) {
  try {
    const { subcategoriaId } = req.params;

    // Asegúrate de que el subcategoriaId esté correctamente trimmeado y en el formato correcto
    const productos = await Product.find({ subcategoriaId: subcategoriaId.trim() });

    if (!productos || productos.length === 0) {
      return res.status(404).json({ message: 'No se encontraron productos para esta subcategoría' });
    }

    res.status(200).json(productos);
  } catch (error) {
    console.error('Error al obtener productos por subcategoría:', error);
    res.status(500).json({ message: 'Error al obtener productos', error });
  }
};


async function getProducts (req, res) {
  const products = await Product.find().lean().exec();
  res.status(200).send({ products });
}

async function updateProduct(req, res) {
  try {
    const { id } = req.params;
    const updateFields = req.body; // Campos que se quieren actualizar

    const product = await Product.findById(id);

    if (!product) {
      return res.status(404).send({ message: 'Producto no encontrado' });
    }

    // Si se está subiendo una nueva imagen, elimina la imagen anterior
    if (req.file) {
      if (product.imgUrl) {
        const oldImage = product.imgUrl.split('/').pop(); // Obtener el nombre del archivo de la imagen anterior
        eliminarImagen(oldImage); // Eliminar la imagen anterior
      }
      const { filename } = req.file;
      product.setImgUrl(filename); // Asignar la nueva imagen
    }

    // Actualizar otros campos
    for (let key in updateFields) {
      product[key] = updateFields[key];
    }

    const productUpdated = await product.save();

    res.status(200).send({ productUpdated });
  } catch (e) {
    res.status(500).send({ message: e.message });
  }
}

module.exports = {
  getProductById,
  addProduct,
  getProducts,
  updateProduct,
  deleteProduct,
  generarCodigoProducto,
  obtenerProductosPorSubcategoria,
  obtenerProductosPorCategoria
};
