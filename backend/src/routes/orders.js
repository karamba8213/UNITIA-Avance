const { Router } = require('express')
const { z } = require('zod')
const { authenticate, requireRole } = require('../middleware/auth')
const { createOrder, getRestaurantOrders } = require('../services/orderService')

const router = Router()

const orderSchema = z.object({
  restaurantId: z.string(),
  causeId: z.string(),
  customerId: z.string().optional(),
  customerName: z.string().min(2),
  customerEmail: z.string().email().optional(),
  customerPhone: z.string().optional(),
  orderType: z.enum(['DELIVERY', 'PICKUP']).default('DELIVERY'),
  notes: z.string().optional(),
  deliveryAddress: z.string().optional(),
  deliveryFee: z.number().optional(),
  paymentMethod: z.string().optional(),
  proofUrl: z.string().optional(),
  items: z.array(z.object({
    menuItemId: z.string(),
    quantity: z.number().int().positive(),
  })).min(1),
})

// POST /orders — create order (public, no auth needed — customers order via link)
router.post('/', async (req, res, next) => {
  try {
    const data = orderSchema.parse(req.body)
    const order = await createOrder(data)
    res.status(201).json({ success: true, data: order })
  } catch (err) {
    next(err)
  }
})

// GET /orders — restaurant's orders (auth required)
router.get('/', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const prisma = require('../config/database')
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const { page, limit, status } = req.query
    const result = await getRestaurantOrders(restaurant.id, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status,
    })
    res.json({ success: true, data: result })
  } catch (err) {
    next(err)
  }
})

// GET /orders/:id — single order detail (public for customer tracking)
router.get('/:id', async (req, res, next) => {
  try {
    const prisma = require('../config/database')
    const order = await prisma.order.findUnique({
      where: { id: req.params.id },
      include: {
        items: true,
        cause: { select: { name: true, slug: true, logo: true } },
        restaurant: { select: { name: true, slug: true, logo: true } },
      },
    })
    if (!order) return res.status(404).json({ success: false, error: 'Order not found' })
    res.json({ success: true, data: order })
  } catch (err) { next(err) }
})

// PATCH /orders/:id/status — restaurant updates order status
router.patch('/:id/status', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const prisma = require('../config/database')
    const { status, estimatedMinutes } = req.body
    const allowed = ['CONFIRMED', 'READY', 'COMPLETED', 'CANCELLED']
    if (!allowed.includes(status)) {
      return res.status(400).json({ success: false, error: 'Invalid status' })
    }
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const order = await prisma.order.findFirst({ where: { id: req.params.id, restaurantId: restaurant.id } })
    if (!order) return res.status(404).json({ success: false, error: 'Order not found' })

    const updateData = { status }
    if (status === 'CONFIRMED' && estimatedMinutes) {
      updateData.estimatedMinutes = parseInt(estimatedMinutes)
    }
    const updated = await prisma.order.update({ where: { id: req.params.id }, data: updateData })
    res.json({ success: true, data: updated })
  } catch (err) { next(err) }
})

// GET /orders/:id/messages — get chat messages for an order
router.get('/:id/messages', async (req, res, next) => {
  try {
    const prisma = require('../config/database')
    const messages = await prisma.message.findMany({
      where: { orderId: req.params.id },
      orderBy: { createdAt: 'asc' },
    })
    res.json({ success: true, data: messages })
  } catch (err) { next(err) }
})

// POST /orders/:id/messages — send a chat message
router.post('/:id/messages', async (req, res, next) => {
  try {
    const prisma = require('../config/database')
    const { text, senderRole, senderName } = req.body
    if (!text?.trim()) return res.status(400).json({ success: false, error: 'Message required' })
    if (!['RESTAURANT', 'CUSTOMER'].includes(senderRole)) return res.status(400).json({ success: false, error: 'Invalid senderRole' })
    if (!senderName?.trim()) return res.status(400).json({ success: false, error: 'senderName required' })

    // Verify order exists
    const order = await prisma.order.findUnique({ where: { id: req.params.id } })
    if (!order) return res.status(404).json({ success: false, error: 'Order not found' })

    const message = await prisma.message.create({
      data: { orderId: req.params.id, senderRole, senderName: senderName.trim(), text: text.trim() },
    })
    res.status(201).json({ success: true, data: message })
  } catch (err) { next(err) }
})

module.exports = router
