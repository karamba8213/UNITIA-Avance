const prisma = require('../config/database')

async function createOrder({ restaurantId, items, customerName, customerEmail, customerPhone, notes }) {
  const restaurant = await prisma.restaurant.findUnique({
    where: { id: restaurantId },
    include: { cause: true },
  })

  if (!restaurant || !restaurant.isActive) {
    const err = new Error('Restaurant not found or inactive')
    err.status = 404
    throw err
  }

  if (!restaurant.causeId) {
    const err = new Error('Restaurant has not selected a cause')
    err.status = 400
    throw err
  }

  if (!items || items.length === 0) {
    const err = new Error('Order must have at least one item')
    err.status = 400
    throw err
  }

  // Fetch menu items to validate prices server-side
  const menuItemIds = items.map(i => i.menuItemId).filter(Boolean)
  const menuItems = await prisma.menuItem.findMany({
    where: { id: { in: menuItemIds }, restaurantId, isAvailable: true },
  })
  const menuMap = Object.fromEntries(menuItems.map(m => [m.id, m]))

  const orderItems = items.map(item => {
    const menu = menuMap[item.menuItemId]
    if (!menu) {
      const err = new Error(`Menu item ${item.menuItemId} not found or unavailable`)
      err.status = 400
      throw err
    }
    return {
      menuItemId: menu.id,
      name: menu.name,
      price: menu.price,   // always use server price
      quantity: Math.max(1, Math.floor(item.quantity)),
    }
  })

  const subtotal = orderItems.reduce((sum, i) => sum + i.price * i.quantity, 0)
  const donationAmount = parseFloat((subtotal * (restaurant.donationPercentage / 100)).toFixed(2))

  const order = await prisma.$transaction(async (tx) => {
    const newOrder = await tx.order.create({
      data: {
        restaurantId,
        causeId: restaurant.causeId,
        customerName,
        customerEmail,
        customerPhone,
        notes,
        subtotal: parseFloat(subtotal.toFixed(2)),
        donationAmount,
        status: 'CONFIRMED',
        items: {
          create: orderItems,
        },
      },
      include: { items: true, cause: { select: { name: true, slug: true } } },
    })

    await tx.donation.create({
      data: {
        restaurantId,
        causeId: restaurant.causeId,
        orderId: newOrder.id,
        amount: donationAmount,
        status: 'PENDING',
      },
    })

    return newOrder
  })

  return order
}

async function getRestaurantOrders(restaurantId, { page = 1, limit = 20, status } = {}) {
  const skip = (page - 1) * limit
  const where = { restaurantId, ...(status && { status }) }

  const [orders, total] = await Promise.all([
    prisma.order.findMany({
      where,
      include: {
        items: true,
        cause: { select: { name: true, slug: true } },
        donation: { select: { status: true, amount: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.order.count({ where }),
  ])

  return { orders, total, page, limit, pages: Math.ceil(total / limit) }
}

module.exports = { createOrder, getRestaurantOrders }
