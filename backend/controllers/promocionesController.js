const Promocion = require('../models/Promocion');

// Agregar una nueva promoción
exports.agregarPromocion = async (req, res) => {
  try {
    const { _id, titulo, descripcion, validoHasta, estado } = req.body;

    const nuevaPromocion = new Promocion({
      _id,
      titulo,
      descripcion,
      validoHasta,
      estado
    });

    await nuevaPromocion.save();
    res.status(201).json({ message: 'Promoción agregada exitosamente', promocion: nuevaPromocion });
  } catch (error) {
    res.status(500).json({ message: 'Error al agregar la promoción', error });
  }
};

// Obtener todas las promociones
exports.obtenerPromociones = async (req, res) => {
  try {
    const promociones = await Promocion.find();
    res.status(200).json(promociones);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener las promociones', error });
  }
};

// Actualizar una promoción por ID
exports.actualizarPromocion = async (req, res) => {
  try {
    const { id } = req.params;
    const promocionActualizada = await Promocion.findByIdAndUpdate(id, req.body, { new: true });

    if (!promocionActualizada) {
      return res.status(404).json({ message: 'Promoción no encontrada' });
    }

    res.status(200).json({ message: 'Promoción actualizada exitosamente', promocion: promocionActualizada });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar la promoción', error });
  }
};

// Eliminar una promoción por ID
exports.eliminarPromocion = async (req, res) => {
  try {
    const { id } = req.params;
    const promocionEliminada = await Promocion.findByIdAndDelete(id);

    if (!promocionEliminada) {
      return res.status(404).json({ message: 'Promoción no encontrada' });
    }

    res.status(200).json({ message: 'Promoción eliminada correctamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar la promoción', error });
  }
};
