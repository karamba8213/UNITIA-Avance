const { Router } = require('express')
const { z } = require('zod')
const { authenticate, requireRole } = require('../middleware/auth')
const prisma = require('../config/database')

const router = Router()

// GET /restaurants/me — get my restaurant profile
router.get('/me', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const restaurant = await prisma.restaurant.findUnique({
      where: { userId: req.user.id },
      include: { cause: { select: { id: true, name: true, slug: true, logo: true } } },
    })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })
    res.json({ success: true, data: restaurant })
  } catch (err) {
    next(err)
  }
})

// PATCH /restaurants/me — update profile
const updateSchema = z.object({
  name: z.string().min(2).optional(),
  description: z.string().optional(),
  address: z.string().optional(),
  phone: z.string().optional(),
  logo: z.string().url().optional(),
  donationPercentage: z.number().min(15).max(100).optional(),
})

router.patch('/me', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const data = updateSchema.parse(req.body)
    const restaurant = await prisma.restaurant.update({
      where: { userId: req.user.id },
      data,
      include: { cause: { select: { id: true, name: true, slug: true } } },
    })
    res.json({ success: true, data: restaurant })
  } catch (err) {
    next(err)
  }
})

// GET /restaurants/me/menu — get menu items
router.get('/me/menu', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const items = await prisma.menuItem.findMany({
      where: { restaurantId: restaurant.id },
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    })
    res.json({ success: true, data: items })
  } catch (err) {
    next(err)
  }
})

// POST /restaurants/me/menu — create menu item
const menuItemSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  price: z.number().positive(),
  category: z.string().optional(),
  imageUrl: z.string().url().optional(),
  isAvailable: z.boolean().optional(),
})

router.post('/me/menu', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const data = menuItemSchema.parse(req.body)
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const item = await prisma.menuItem.create({
      data: { ...data, restaurantId: restaurant.id },
    })
    res.status(201).json({ success: true, data: item })
  } catch (err) {
    next(err)
  }
})

// PATCH /restaurants/me/menu/:id — update menu item
router.patch('/me/menu/:id', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const data = menuItemSchema.partial().parse(req.body)
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const item = await prisma.menuItem.updateMany({
      where: { id: req.params.id, restaurantId: restaurant.id },
      data,
    })
    if (item.count === 0) return res.status(404).json({ success: false, error: 'Menu item not found' })
    res.json({ success: true, data: { updated: true } })
  } catch (err) {
    next(err)
  }
})

// DELETE /restaurants/me/menu/:id — soft delete (mark unavailable)
router.delete('/me/menu/:id', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    await prisma.menuItem.updateMany({
      where: { id: req.params.id, restaurantId: restaurant.id },
      data: { isAvailable: false },
    })
    res.json({ success: true, data: { deleted: true } })
  } catch (err) {
    next(err)
  }
})

// GET /restaurants/me/dashboard — stats overview
router.get('/me/dashboard', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const [totalOrders, todayOrders, donationSummary] = await Promise.all([
      prisma.order.count({ where: { restaurantId: restaurant.id } }),
      prisma.order.findMany({
        where: { restaurantId: restaurant.id, createdAt: { gte: today } },
        select: { subtotal: true, donationAmount: true },
      }),
      prisma.donation.groupBy({
        by: ['status'],
        where: { restaurantId: restaurant.id },
        _sum: { amount: true },
        _count: true,
      }),
    ])

    const todayRevenue = todayOrders.reduce((s, o) => s + o.subtotal, 0)
    const todayDonations = todayOrders.reduce((s, o) => s + o.donationAmount, 0)

    const summaryMap = Object.fromEntries(
      donationSummary.map(d => [d.status, { total: d._sum.amount || 0, count: d._count }])
    )

    res.json({
      success: true,
      data: {
        totalOrders,
        todayOrders: todayOrders.length,
        todayRevenue: parseFloat(todayRevenue.toFixed(2)),
        todayDonations: parseFloat(todayDonations.toFixed(2)),
        donations: {
          pending: summaryMap.PENDING || { total: 0, count: 0 },
          paid: summaryMap.PAID || { total: 0, count: 0 },
          confirmed: summaryMap.CONFIRMED || { total: 0, count: 0 },
        },
      },
    })
  } catch (err) {
    next(err)
  }
})

module.exports = router
