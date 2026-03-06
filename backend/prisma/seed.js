const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')

const prisma = new PrismaClient()

async function main() {
  console.log('Seeding database...')

  const hash = await bcrypt.hash('password123', 12)

  // --- CAUSE 1 ---
  const causeUser = await prisma.user.upsert({
    where: { email: 'comedor@unitia.test' },
    update: {},
    create: { email: 'comedor@unitia.test', password: hash, name: 'Comedor Esperanza', role: 'CAUSE' },
  })
  const cause1 = await prisma.cause.upsert({
    where: { userId: causeUser.id },
    update: {},
    create: {
      userId: causeUser.id,
      name: 'Comedor Esperanza',
      slug: 'comedor-esperanza',
      description: 'Brindamos almuerzo diario a 200 niños en situación de vulnerabilidad.',
      story: 'El Comedor Esperanza nació en 2015 cuando un grupo de vecinos del barrio decidió que ningún niño debería quedarse sin comer.\n\nHoy damos 200 almuerzos diarios de lunes a viernes. Con tu ayuda podemos llegar a más familias y sostener nuestra cocina todo el año.',
      targetAmount: 500000,
      isVerified: true,
    },
  })

  // --- CAUSE 2 ---
  const causeUser2 = await prisma.user.upsert({
    where: { email: 'refugio@unitia.test' },
    update: {},
    create: { email: 'refugio@unitia.test', password: hash, name: 'Refugio Verde', role: 'CAUSE' },
  })
  const cause2 = await prisma.cause.upsert({
    where: { userId: causeUser2.id },
    update: {},
    create: {
      userId: causeUser2.id,
      name: 'Refugio Verde',
      slug: 'refugio-verde',
      description: 'Rescatamos y rehabilitamos animales abandonados en el área metropolitana.',
      story: 'Rescatamos perros y gatos en situación de calle, los rehabilitamos y buscamos hogares responsables. Operamos 100% con voluntarios y donaciones.',
      targetAmount: 200000,
      isVerified: true,
    },
  })

  // --- RESTAURANT 1 ---
  const restUser1 = await prisma.user.upsert({
    where: { email: 'lafamiliar@unitia.test' },
    update: {},
    create: { email: 'lafamiliar@unitia.test', password: hash, name: 'La Familiar', role: 'RESTAURANT' },
  })
  const rest1 = await prisma.restaurant.upsert({
    where: { userId: restUser1.id },
    update: {},
    create: {
      userId: restUser1.id,
      name: 'La Familiar',
      slug: 'la-familiar',
      description: 'Cocina casera de calidad. Almuerzo y cena todos los días.',
      address: 'Av. Corrientes 1234, CABA',
      phone: '+54 11 4444-5555',
      donationPercentage: 5,
      causeId: cause1.id,
      isVerified: true,
    },
  })

  // Menu items
  const menuItems1 = [
    { name: 'Milanesa napolitana', description: 'Con papas fritas y ensalada', price: 1800, category: 'Platos principales' },
    { name: 'Pollo al horno', description: 'Con puré casero', price: 1600, category: 'Platos principales' },
    { name: 'Empanadas (x6)', description: 'Surtidas de carne y pollo', price: 900, category: 'Entradas' },
    { name: 'Ensalada mixta', description: 'Lechuga, tomate, zanahoria', price: 700, category: 'Entradas' },
    { name: 'Agua mineral', price: 350, category: 'Bebidas' },
    { name: 'Gaseosa', price: 450, category: 'Bebidas' },
    { name: 'Tiramisú', description: 'Porción individual', price: 650, category: 'Postres' },
  ]
  for (const item of menuItems1) {
    await prisma.menuItem.upsert({
      where: { id: `seed-${rest1.id}-${item.name.toLowerCase().replace(/\s/g, '-')}` },
      update: {},
      create: { id: `seed-${rest1.id}-${item.name.toLowerCase().replace(/\s/g, '-')}`, restaurantId: rest1.id, ...item },
    })
  }

  // --- RESTAURANT 2 ---
  const restUser2 = await prisma.user.upsert({
    where: { email: 'elrinconcito@unitia.test' },
    update: {},
    create: { email: 'elrinconcito@unitia.test', password: hash, name: 'El Rinconcito', role: 'RESTAURANT' },
  })
  const rest2 = await prisma.restaurant.upsert({
    where: { userId: restUser2.id },
    update: {},
    create: {
      userId: restUser2.id,
      name: 'El Rinconcito',
      slug: 'el-rinconcito',
      description: 'Pizza artesanal y pastas frescas.',
      address: 'Belgrano 567, Rosario',
      donationPercentage: 8,
      causeId: cause2.id,
      isVerified: true,
    },
  })

  const menuItems2 = [
    { name: 'Pizza muzzarella', description: 'Grande 8 porciones', price: 2200, category: 'Pizzas' },
    { name: 'Pizza cuatro quesos', price: 2600, category: 'Pizzas' },
    { name: 'Tallarines al pesto', description: 'Pasta fresca', price: 1400, category: 'Pastas' },
    { name: 'Ravioles de ricota', description: 'Con salsa fileto', price: 1600, category: 'Pastas' },
    { name: 'Birra artesanal', price: 600, category: 'Bebidas' },
  ]
  for (const item of menuItems2) {
    await prisma.menuItem.upsert({
      where: { id: `seed-${rest2.id}-${item.name.toLowerCase().replace(/\s/g, '-')}` },
      update: {},
      create: { id: `seed-${rest2.id}-${item.name.toLowerCase().replace(/\s/g, '-')}`, restaurantId: rest2.id, ...item },
    })
  }

  console.log('Seed complete.')
  console.log('Test accounts (password: password123):')
  console.log('  Restaurant: lafamiliar@unitia.test  → /r/la-familiar')
  console.log('  Restaurant: elrinconcito@unitia.test → /r/el-rinconcito')
  console.log('  Cause:      comedor@unitia.test      → /c/comedor-esperanza')
  console.log('  Cause:      refugio@unitia.test      → /c/refugio-verde')
}

main()
  .catch(e => { console.error(e); process.exit(1) })
  .finally(() => prisma.$disconnect())
