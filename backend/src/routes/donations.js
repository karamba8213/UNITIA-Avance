const { Router } = require('express')
const { authenticate, requireRole } = require('../middleware/auth')
const prisma = require('../config/database')
const donationService = require('../services/donationService')

const router = Router()

// GET /donations — list donations (restaurant or cause)
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { status, page, limit } = req.query
    const opts = { status, page: parseInt(page) || 1, limit: parseInt(limit) || 20 }

    if (req.user.role === 'RESTAURANT') {
      const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
      if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })
      const result = await donationService.getRestaurantDonations(restaurant.id, opts)
      return res.json({ success: true, data: result })
    }

    if (req.user.role === 'CAUSE') {
      const cause = await prisma.cause.findUnique({ where: { userId: req.user.id } })
      if (!cause) return res.status(404).json({ success: false, error: 'Cause not found' })
      const result = await donationService.getCauseDonations(cause.id, opts)
      return res.json({ success: true, data: result })
    }

    res.status(403).json({ success: false, error: 'Not authorized' })
  } catch (err) {
    next(err)
  }
})

// PATCH /donations/:id/pay — restaurant marks donation as paid
router.patch('/:id/pay', authenticate, requireRole('RESTAURANT'), async (req, res, next) => {
  try {
    const restaurant = await prisma.restaurant.findUnique({ where: { userId: req.user.id } })
    if (!restaurant) return res.status(404).json({ success: false, error: 'Restaurant not found' })

    const { notes, paymentMethod, proofUrl } = req.body
    const donation = await donationService.markDonationPaid(
      req.params.id,
      restaurant.id,
      { notes, paymentMethod, proofUrl }
    )
    res.json({ success: true, data: donation })
  } catch (err) {
    next(err)
  }
})

// PATCH /donations/:id/confirm — cause confirms receipt
router.patch('/:id/confirm', authenticate, requireRole('CAUSE'), async (req, res, next) => {
  try {
    const cause = await prisma.cause.findUnique({ where: { userId: req.user.id } })
    if (!cause) return res.status(404).json({ success: false, error: 'Cause not found' })

    const donation = await donationService.confirmDonationReceived(req.params.id, cause.id)
    res.json({ success: true, data: donation })
  } catch (err) {
    next(err)
  }
})

// PATCH /donations/:id/dispute — cause disputes (did not receive payment)
router.patch('/:id/dispute', authenticate, requireRole('CAUSE'), async (req, res, next) => {
  try {
    const cause = await prisma.cause.findUnique({ where: { userId: req.user.id } })
    if (!cause) return res.status(404).json({ success: false, error: 'Cause not found' })

    const { reason } = req.body
    const donation = await donationService.disputeDonation(req.params.id, cause.id, { reason })
    res.json({ success: true, data: donation })
  } catch (err) {
    next(err)
  }
})

module.exports = router
