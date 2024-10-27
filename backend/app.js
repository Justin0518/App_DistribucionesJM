const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const productRoutes = require('./routes/product')
const clientesRoutes = require('./routes/clientes')
const comprasRoutes = require('./routes/compras')
const promocionesRoutes = require('./routes/promociones')
const pedidosRoutes = require('./routes/pedidos')
const informesRoutes = require('./routes/informes');
const categoriasRoutes = require('./routes/categorias');
const subcategoriasRoutes = require('./routes/subcategorias');
const carritoRoutes = require('./routes/carrito')
const adminRoutes = require('./routes/admin')


const app = express()

app.use(cors())

app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

app.use('/public', express.static(`${__dirname}/storage/imgs`))

app.use('/v1', productRoutes)

app.use('/clientes', clientesRoutes)
app.use('/compras', comprasRoutes)
app.use('/promociones', promocionesRoutes)
app.use('/pedidos', pedidosRoutes)
app.use('/informes', informesRoutes)
app.use('/categorias', categoriasRoutes)
app.use('/subcategorias', subcategoriasRoutes)
app.use('/carrito', carritoRoutes)
app.use('/admin', adminRoutes)

module.exports = app
