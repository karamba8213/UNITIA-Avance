require('dotenv').config()
const express = require('express')
const cors = require('cors')
const helmet = require('helmet')
const morgan = require('morgan')

const authRoutes = require('./routes/auth')
const restaurantRoutes = require('./routes/restaurants')
const causeRoutes = require('./routes/causes')
const orderRoutes = require('./routes/orders')
const donationRoutes = require('./routes/donations')
const publicRoutes = require('./routes/public')
const errorHandler = require('./middleware/error')

const app = express()

app.use(helmet())
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true,
}))
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'))
app.use(express.json())

app.get('/health', (req, res) => res.json({ status: 'ok', version: '1.0.0' }))

app.use('/api/v1/auth', authRoutes)
app.use('/api/v1/restaurants', restaurantRoutes)
app.use('/api/v1/causes', causeRoutes)
app.use('/api/v1/orders', orderRoutes)
app.use('/api/v1/donations', donationRoutes)
app.use('/api/v1/public', publicRoutes)

app.use(errorHandler)

const PORT = process.env.PORT || 4000
app.listen(PORT, () => {
  console.log(`Unitia API running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`)
})

module.exports = app
