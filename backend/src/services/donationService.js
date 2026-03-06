const prisma = require('../config/database')

async function getRestaurantDonations(restaurantId, { status, page = 1, limit = 20 } = {}) {
  const skip = (page - 1) * limit
  const where = { restaurantId, ...(status && { status }) }

  const [donations, total, summary] = await Promise.all([
    prisma.donation.findMany({
      where,
      include: {
        cause: { select: { name: true, slug: true, logo: true } },
        order: { select: { createdAt: true, customerName: true, subtotal: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.donation.count({ where: { restaurantId } }),
    prisma.donation.groupBy({
      by: ['status'],
      where: { restaurantId },
      _sum: { amount: true },
      _count: true,
    }),
  ])

  return { donations, total, page, limit, pages: Math.ceil(total / limit), summary }
}

async function getCauseDonations(causeId, { status, page = 1, limit = 20 } = {}) {
  const skip = (page - 1) * limit
  const where = { causeId, ...(status && { status }) }

  const [donations, total, summary] = await Promise.all([
    prisma.donation.findMany({
      where,
      include: {
        restaurant: { select: { name: true, slug: true, logo: true } },
        order: { select: { createdAt: true, subtotal: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.donation.count({ where: { causeId } }),
    prisma.donation.groupBy({
      by: ['status'],
      where: { causeId },
      _sum: { amount: true },
      _count: true,
    }),
  ])

  return { donations, total, page, limit, pages: Math.ceil(total / limit), summary }
}

async function markDonationPaid(donationId, restaurantId, notes) {
  const donation = await prisma.donation.findUnique({ where: { id: donationId } })

  if (!donation) {
    const err = new Error('Donation not found')
    err.status = 404
    throw err
  }
  if (donation.restaurantId !== restaurantId) {
    const err = new Error('Not authorized to update this donation')
    err.status = 403
    throw err
  }
  if (donation.status !== 'PENDING') {
    const err = new Error(`Cannot mark donation as paid — current status: ${donation.status}`)
    err.status = 400
    throw err
  }

  return prisma.donation.update({
    where: { id: donationId },
    data: { status: 'PAID', paidAt: new Date(), notes },
  })
}

async function confirmDonationReceived(donationId, causeId) {
  const donation = await prisma.donation.findUnique({ where: { id: donationId } })

  if (!donation) {
    const err = new Error('Donation not found')
    err.status = 404
    throw err
  }
  if (donation.causeId !== causeId) {
    const err = new Error('Not authorized to confirm this donation')
    err.status = 403
    throw err
  }
  if (donation.status !== 'PAID') {
    const err = new Error(`Cannot confirm donation — current status: ${donation.status}`)
    err.status = 400
    throw err
  }

  return prisma.donation.update({
    where: { id: donationId },
    data: { status: 'CONFIRMED', confirmedAt: new Date() },
  })
}

module.exports = {
  getRestaurantDonations,
  getCauseDonations,
  markDonationPaid,
  confirmDonationReceived,
}
