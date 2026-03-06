const { Router } = require('express')
const { z } = require('zod')
const prisma = require('../config/database')

const router = Router()

// GET /public/causes/:slug — public cause page data
router.get('/causes/:slug', async (req, res, next) => {
  try {
    const cause = await prisma.cause.findUnique({
      where: { slug: req.params.slug },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        story: true,
        logo: true,
        images: true,
        targetAmount: true,
        createdAt: true,
        isActive: true,
        restaurants: {
          where: { isActive: true },
          select: { id: true, name: true, slug: true, logo: true },
          take: 10,
        },
      },
    })

    if (!cause || !cause.isActive) {
      return res.status(404).json({ success: false, error: 'Cause not found' })
    }

    const donationStats = await prisma.donation.aggregate({
      where: { causeId: cause.id, status: { in: ['PAID', 'CONFIRMED'] } },
      _sum: { amount: true },
      _count: true,
    })

    const totalRaised = donationStats._sum.amount || 0
    const progress = cause.targetAmount > 0
      ? Math.min(100, parseFloat(((totalRaised / cause.targetAmount) * 100).toFixed(1)))
      : null

    res.json({
      success: true,
      data: {
        ...cause,
        totalRaised: parseFloat(totalRaised.toFixed(2)),
        totalDonations: donationStats._count,
        progress,
      },
    })
  } catch (err) {
    next(err)
  }
})

// GET /public/restaurants/:slug — public restaurant order page
router.get('/restaurants/:slug', async (req, res, next) => {
  try {
    const restaurant = await prisma.restaurant.findUnique({
      where: { slug: req.params.slug },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        logo: true,
        address: true,
        donationPercentage: true,
        isActive: true,
        cause: {
          select: { id: true, name: true, slug: true, description: true, logo: true },
        },
        menuItems: {
          where: { isAvailable: true },
          select: { id: true, name: true, description: true, price: true, category: true, imageUrl: true },
          orderBy: [{ category: 'asc' }, { name: 'asc' }],
        },
      },
    })

    if (!restaurant || !restaurant.isActive) {
      return res.status(404).json({ success: false, error: 'Restaurant not found' })
    }

    res.json({ success: true, data: restaurant })
  } catch (err) {
    next(err)
  }
})

// GET /public/causes — featured causes for landing page
router.get('/causes', async (req, res, next) => {
  try {
    const causes = await prisma.cause.findMany({
      where: { isActive: true, isVerified: true },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        logo: true,
        targetAmount: true,
        _count: { select: { restaurants: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 6,
    })

    const causesWithStats = await Promise.all(
      causes.map(async (cause) => {
        const stats = await prisma.donation.aggregate({
          where: { causeId: cause.id, status: { in: ['PAID', 'CONFIRMED'] } },
          _sum: { amount: true },
        })
        const totalRaised = stats._sum.amount || 0
        return {
          ...cause,
          totalRaised: parseFloat(totalRaised.toFixed(2)),
          progress: cause.targetAmount > 0
            ? Math.min(100, parseFloat(((totalRaised / cause.targetAmount) * 100).toFixed(1)))
            : null,
        }
      })
    )

    res.json({ success: true, data: causesWithStats })
  } catch (err) {
    next(err)
  }
})

// GET /public/impact?email=xxx — customer impact tracker
// Shows a customer how much they've donated in total and broken down by cause
router.get('/impact', async (req, res, next) => {
  try {
    const emailSchema = z.string().email()
    const email = emailSchema.parse(req.query.email)

    const orders = await prisma.order.findMany({
      where: {
        customerEmail: email,
        status: 'CONFIRMED',
      },
      select: {
        id: true,
        donationAmount: true,
        subtotal: true,
        createdAt: true,
        cause: {
          select: { id: true, name: true, slug: true, logo: true, description: true },
        },
        restaurant: {
          select: { name: true, slug: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    })

    if (orders.length === 0) {
      return res.json({
        success: true,
        data: {
          totalDonated: 0,
          totalOrders: 0,
          byCause: [],
          recentOrders: [],
        },
      })
    }

    const totalDonated = orders.reduce((s, o) => s + o.donationAmount, 0)
    const totalOrders = orders.length

    // Group by cause
    const causeMap = {}
    for (const order of orders) {
      const cid = order.cause.id
      if (!causeMap[cid]) {
        causeMap[cid] = {
          cause: order.cause,
          totalDonated: 0,
          orderCount: 0,
        }
      }
      causeMap[cid].totalDonated += order.donationAmount
      causeMap[cid].orderCount += 1
    }

    const byCause = Object.values(causeMap)
      .map(c => ({
        ...c,
        totalDonated: parseFloat(c.totalDonated.toFixed(2)),
      }))
      .sort((a, b) => b.totalDonated - a.totalDonated)

    res.json({
      success: true,
      data: {
        totalDonated: parseFloat(totalDonated.toFixed(2)),
        totalOrders,
        byCause,
        recentOrders: orders.slice(0, 10).map(o => ({
          id: o.id,
          restaurant: o.restaurant,
          cause: o.cause,
          donationAmount: o.donationAmount,
          subtotal: o.subtotal,
          date: o.createdAt,
        })),
      },
    })
  } catch (err) {
    next(err)
  }
})

module.exports = router
