const { Router } = require('express')
const { z } = require('zod')
const { authenticate, requireRole } = require('../middleware/auth')
const prisma = require('../config/database')

const router = Router()

// GET /causes/me
router.get('/me', authenticate, requireRole('CAUSE'), async (req, res, next) => {
  try {
    const cause = await prisma.cause.findUnique({
      where: { userId: req.user.id },
      include: {
        restaurants: {
          where: { isActive: true },
          select: { id: true, name: true, slug: true, logo: true, donationPercentage: true },
        },
      },
    })
    if (!cause) return res.status(404).json({ success: false, error: 'Cause not found' })
    res.json({ success: true, data: cause })
  } catch (err) {
    next(err)
  }
})

// PATCH /causes/me
const updateSchema = z.object({
  name: z.string().min(2).optional(),
  description: z.string().optional(),
  story: z.string().optional(),
  logo: z.string().url().optional(),
  images: z.array(z.string().url()).optional(),
  targetAmount: z.number().min(0).optional(),
  bankName: z.string().optional(),
  bankHolder: z.string().optional(),
  bankClabe: z.string().optional(),
  bankAccount: z.string().optional(),
})

router.patch('/me', authenticate, requireRole('CAUSE'), async (req, res, next) => {
  try {
    const data = updateSchema.parse(req.body)
    const cause = await prisma.cause.update({
      where: { userId: req.user.id },
      data,
    })
    res.json({ success: true, data: cause })
  } catch (err) {
    next(err)
  }
})

// GET /causes/me/dashboard
router.get('/me/dashboard', authenticate, requireRole('CAUSE'), async (req, res, next) => {
  try {
    const cause = await prisma.cause.findUnique({ where: { userId: req.user.id } })
    if (!cause) return res.status(404).json({ success: false, error: 'Cause not found' })

    const [donationSummary, restaurantCount, recentDonations] = await Promise.all([
      prisma.donation.groupBy({
        by: ['status'],
        where: { causeId: cause.id },
        _sum: { amount: true },
        _count: true,
      }),
      prisma.restaurant.count({ where: { causeId: cause.id, isActive: true } }),
      prisma.donation.findMany({
        where: { causeId: cause.id },
        include: {
          restaurant: { select: { name: true, slug: true } },
          order: { select: { createdAt: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),
    ])

    const summaryMap = Object.fromEntries(
      donationSummary.map(d => [d.status, { total: d._sum.amount || 0, count: d._count }])
    )

    const totalRaised =
      ((summaryMap.PAID?.total || 0) + (summaryMap.CONFIRMED?.total || 0))

    const progress = cause.targetAmount > 0
      ? Math.min(100, parseFloat(((totalRaised / cause.targetAmount) * 100).toFixed(1)))
      : null

    res.json({
      success: true,
      data: {
        totalRaised: parseFloat(totalRaised.toFixed(2)),
        targetAmount: cause.targetAmount,
        progress,
        restaurantCount,
        donations: {
          pending: summaryMap.PENDING || { total: 0, count: 0 },
          paid: summaryMap.PAID || { total: 0, count: 0 },
          confirmed: summaryMap.CONFIRMED || { total: 0, count: 0 },
        },
        recentDonations,
      },
    })
  } catch (err) {
    next(err)
  }
})

// GET /causes/list — browse all verified causes (for restaurant selection)
router.get('/list', authenticate, async (req, res, next) => {
  try {
    const causes = await prisma.cause.findMany({
      where: { isActive: true, isVerified: true },
      select: { id: true, name: true, slug: true, description: true, logo: true, targetAmount: true },
      orderBy: { name: 'asc' },
    })
    res.json({ success: true, data: causes })
  } catch (err) {
    next(err)
  }
})

module.exports = router
