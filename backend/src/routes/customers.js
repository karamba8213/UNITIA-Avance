const { Router } = require('express')
const { z } = require('zod')
const { authenticate, requireRole } = require('../middleware/auth')
const prisma = require('../config/database')

const router = Router()

function isSameDay(date) {
  const today = new Date()
  return (
    date.getFullYear() === today.getFullYear() &&
    date.getMonth() === today.getMonth() &&
    date.getDate() === today.getDate()
  )
}

// GET /customers/me
router.get('/me', authenticate, requireRole('CUSTOMER'), async (req, res, next) => {
  try {
    let customer = await prisma.customer.findUnique({
      where: { userId: req.user.id },
      include: { user: { select: { name: true, email: true, image: true } } },
    })
    if (!customer) return res.status(404).json({ success: false, error: 'Customer not found' })

    // Auto-expire selected cause if it's from a previous day
    if (customer.selectedCauseId && customer.selectedCauseAt && !isSameDay(customer.selectedCauseAt)) {
      customer = await prisma.customer.update({
        where: { id: customer.id },
        data: { selectedCauseId: null, selectedCauseAt: null },
        include: { user: { select: { name: true, email: true, image: true } } },
      })
    }

    res.json({
      success: true,
      data: {
        ...customer,
        name: customer.user.name,
        email: customer.user.email,
        image: customer.user.image,
      },
    })
  } catch (err) { next(err) }
})

// PATCH /customers/me
const addressSchema = z.object({
  label: z.string().min(1).max(50),
  address: z.string().min(1).max(200),
})

const updateSchema = z.object({
  phone: z.string().optional(),
  savedAddresses: z.array(addressSchema).optional(),
  selectedCauseId: z.string().optional().nullable(),
})

router.patch('/me', authenticate, requireRole('CUSTOMER'), async (req, res, next) => {
  try {
    const data = updateSchema.parse(req.body)
    const updateData = {}
    if (data.phone !== undefined) updateData.phone = data.phone
    if (data.savedAddresses !== undefined) updateData.savedAddresses = data.savedAddresses
    if (data.selectedCauseId !== undefined) {
      updateData.selectedCauseId = data.selectedCauseId
      updateData.selectedCauseAt = data.selectedCauseId ? new Date() : null
    }
    const customer = await prisma.customer.update({
      where: { userId: req.user.id },
      data: updateData,
    })
    res.json({ success: true, data: customer })
  } catch (err) { next(err) }
})

// GET /customers/me/orders
router.get('/me/orders', authenticate, requireRole('CUSTOMER'), async (req, res, next) => {
  try {
    const customer = await prisma.customer.findUnique({ where: { userId: req.user.id } })
    if (!customer) return res.status(404).json({ success: false, error: 'Customer not found' })

    const orders = await prisma.order.findMany({
      where: { customerId: customer.id },
      include: {
        items: true,
        cause: { select: { id: true, name: true, slug: true, logo: true } },
        restaurant: { select: { name: true, slug: true, logo: true } },
      },
      orderBy: { createdAt: 'desc' },
    })
    res.json({ success: true, data: orders })
  } catch (err) { next(err) }
})

module.exports = router
