const { Router } = require('express')
const { z } = require('zod')
const { authenticate, requireRole } = require('../middleware/auth')
const { createOrder, getRestaurantOrders } = require('../services/orderService')

const router = Router()

const orderSchema = z.object({
  restaurantId: z.string(),
  customerName: z.string().min(2),
  customerEmail: z.string().email().optional(),
  customerPhone: z.string().optional(),
  notes: z.string().optional(),
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

// GET /orders/:id — single order detail
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const prisma = require('../config/database')
    const order = await prisma.order.findUnique({
      where: { id: req.params.id },
      include: {
        items: true,
        cause: { select: { name: true, slug: true } },
        restaurant: { select: { name: true, slug: true } },
        donation: true,
      },
    })
    if (!order) return res.status(404).json({ success: false, error: 'Order not found' })

    // Verify ownership
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (req.user.role === 'RESTAURANT' && order.restaurantId !== restaurant?.id) {
      return res.status(403).json({ success: false, error: 'Not authorized' })
    }

    res.json({ success: true, data: order })
  } catch (err) {
    next(err)
  }
})

module.exports = router
