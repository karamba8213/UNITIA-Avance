/**
 * firestore-setup.js
 *
 * Initialises the Unitia Firestore structure using the Admin SDK.
 * Run once to verify connectivity and seed demo data (optional).
 *
 * Usage:
 *   node scripts/firestore-setup.js [--seed]
 *
 * Options:
 *   --seed   Also write sample restaurant, cause, order & donation documents.
 */

const admin = require('firebase-admin');
const path  = require('path');

// ── Init ─────────────────────────────────────────────────────────────────────
const serviceAccount = require(path.join(__dirname, '..', 'firebase-admin.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db   = admin.firestore();
const seed = process.argv.includes('--seed');

// ── Schema docs ──────────────────────────────────────────────────────────────
// These _schema sentinel documents document the expected fields for each
// collection without interfering with real data.
const SCHEMAS = {
  'restaurants/_schema': {
    _note:              'Doc ID = Firebase Auth UID of the restaurant owner',
    userId:             'string  — Firebase Auth UID',
    name:               'string',
    slug:               'string  — unique, URL-safe',
    description:        'string | null',
    logo:               'string | null  — Storage URL',
    address:            'string | null',
    phone:              'string | null',
    donationPercentage: 'number  — e.g. 5.0',
    causeId:            'string | null  — ref to causes/{id}',
    causeName:          'string | null  — denormalised',
    isVerified:         'boolean',
    isActive:           'boolean',
    // Aggregates kept in sync via batch writes
    totalOrders:        'number',
    totalRevenue:       'number',
    totalDonationsPending:   'number',
    totalDonationsPaid:      'number',
    totalDonationsConfirmed: 'number',
    createdAt:          'timestamp',
    updatedAt:          'timestamp',
  },

  'restaurants/_schema/menu/_schema': {
    _note:       'Subcollection — one doc per menu item',
    name:        'string',
    description: 'string | null',
    price:       'number',
    category:    'string | null',
    imageUrl:    'string | null',
    isAvailable: 'boolean',
    createdAt:   'timestamp',
    updatedAt:   'timestamp',
  },

  'causes/_schema': {
    _note:        'Doc ID = Firebase Auth UID of the cause owner',
    userId:       'string  — Firebase Auth UID',
    name:         'string',
    slug:         'string  — unique, URL-safe',
    description:  'string',
    story:        'string  — long text',
    logo:         'string | null',
    images:       'string[]  — Storage URLs',
    targetAmount: 'number',
    totalRaised:  'number  — confirmed donations only, updated via increment',
    isVerified:   'boolean',
    isActive:     'boolean',
    createdAt:    'timestamp',
    updatedAt:    'timestamp',
  },

  'orders/_schema': {
    _note:          'Doc ID = auto-generated',
    restaurantId:   'string  — ref to restaurants/{id}',
    restaurantName: 'string  — denormalised',
    causeId:        'string  — ref to causes/{id}',
    causeName:      'string  — denormalised',
    customerName:   'string',
    customerEmail:  'string | null',
    customerPhone:  'string | null',
    notes:          'string | null',
    // items is an embedded array (avoids subcollection overhead for small lists)
    items: [
      {
        menuItemId: 'string | null',
        name:       'string',
        price:      'number',
        quantity:   'number',
      },
    ],
    subtotal:       'number',
    donationAmount: 'number',
    status:         '"pending" | "confirmed" | "cancelled"',
    donationStatus: '"pending" | "paid" | "confirmed" | "disputed"',
    createdAt:      'timestamp',
    updatedAt:      'timestamp',
  },

  'donations/_schema': {
    _note:          'Doc ID = same as the corresponding order ID (1-to-1)',
    orderId:        'string  — ref to orders/{id}',
    restaurantId:   'string  — ref to restaurants/{id}',
    restaurantName: 'string  — denormalised',
    causeId:        'string  — ref to causes/{id}',
    causeName:      'string  — denormalised',
    customerName:   'string  — denormalised for cause dashboard',
    amount:         'number',
    status:         '"pending" | "paid" | "confirmed" | "disputed"',
    paidAt:         'timestamp | null',
    confirmedAt:    'timestamp | null',
    notes:          'string | null',
    createdAt:      'timestamp',
    updatedAt:      'timestamp',
  },
};

// ── Sample seed data ──────────────────────────────────────────────────────────
const SAMPLE_CAUSE_ID      = 'cause_demo_001';
const SAMPLE_RESTAURANT_ID = 'restaurant_demo_001';

async function writeSchemas() {
  console.log('Writing schema sentinel documents…');
  const batch = db.batch();

  for (const [path, data] of Object.entries(SCHEMAS)) {
    const parts = path.split('/');
    let ref = db.collection(parts[0]).doc(parts[1]);
    if (parts.length === 4) {
      ref = ref.collection(parts[2]).doc(parts[3]);
    }
    batch.set(ref, { ...data, _isSchema: true }, { merge: true });
  }

  await batch.commit();
  console.log('  ✓ Schema docs written.');
}

async function seedDemoData() {
  console.log('Seeding demo data…');

  const now = admin.firestore.FieldValue.serverTimestamp();

  // Cause
  await db.collection('causes').doc(SAMPLE_CAUSE_ID).set({
    userId:       'demo_cause_user',
    name:         'Comedor Los Girasoles',
    slug:         'los-girasoles',
    description:  'Brindamos comidas a niños en situación de vulnerabilidad.',
    story:        'Desde 2018 damos de comer a más de 200 chicos por día en el barrio La Esperanza.',
    logo:         null,
    images:       [],
    targetAmount: 50000,
    totalRaised:  0,
    isVerified:   true,
    isActive:     true,
    createdAt:    now,
    updatedAt:    now,
  }, { merge: true });

  // Restaurant
  await db.collection('restaurants').doc(SAMPLE_RESTAURANT_ID).set({
    userId:             'demo_restaurant_user',
    name:               'La Parrilla de Juan',
    slug:               'parrilla-juan',
    description:        'La mejor parrilla del barrio.',
    logo:               null,
    address:            'Av. Siempreviva 742',
    phone:              '+54 11 1234-5678',
    donationPercentage: 5,
    causeId:            SAMPLE_CAUSE_ID,
    causeName:          'Comedor Los Girasoles',
    isVerified:         true,
    isActive:           true,
    totalOrders:        0,
    totalRevenue:       0,
    totalDonationsPending:   0,
    totalDonationsPaid:      0,
    totalDonationsConfirmed: 0,
    createdAt:          now,
    updatedAt:          now,
  }, { merge: true });

  // Sample menu items
  const menuRef = db.collection('restaurants').doc(SAMPLE_RESTAURANT_ID).collection('menu');
  await menuRef.add({
    name:        'Bife de chorizo',
    description: '400g con papas fritas',
    price:       2800,
    category:    'Carnes',
    imageUrl:    null,
    isAvailable: true,
    createdAt:   now,
    updatedAt:   now,
  });
  await menuRef.add({
    name:        'Empanadas (x6)',
    description: 'Carne cortada a cuchillo',
    price:       1200,
    category:    'Entradas',
    imageUrl:    null,
    isAvailable: true,
    createdAt:   now,
    updatedAt:   now,
  });

  // Sample order + donation (atomic)
  const orderRef    = db.collection('orders').doc();
  const donationRef = db.collection('donations').doc(orderRef.id);
  const subtotal    = 4000;
  const donation    = subtotal * 0.05;

  const batch = db.batch();

  batch.set(orderRef, {
    restaurantId:   SAMPLE_RESTAURANT_ID,
    restaurantName: 'La Parrilla de Juan',
    causeId:        SAMPLE_CAUSE_ID,
    causeName:      'Comedor Los Girasoles',
    customerName:   'María García',
    customerEmail:  'maria@ejemplo.com',
    customerPhone:  null,
    notes:          null,
    items: [
      { menuItemId: null, name: 'Bife de chorizo', price: 2800, quantity: 1 },
      { menuItemId: null, name: 'Empanadas (x6)',  price: 1200, quantity: 1 },
    ],
    subtotal:       subtotal,
    donationAmount: donation,
    status:         'confirmed',
    donationStatus: 'pending',
    createdAt:      now,
    updatedAt:      now,
  });

  batch.set(donationRef, {
    orderId:        orderRef.id,
    restaurantId:   SAMPLE_RESTAURANT_ID,
    restaurantName: 'La Parrilla de Juan',
    causeId:        SAMPLE_CAUSE_ID,
    causeName:      'Comedor Los Girasoles',
    customerName:   'María García',
    amount:         donation,
    status:         'pending',
    paidAt:         null,
    confirmedAt:    null,
    notes:          null,
    createdAt:      now,
    updatedAt:      now,
  });

  await batch.commit();

  console.log('  ✓ Demo cause, restaurant, menu items, order & donation created.');
  console.log(`    Order ID: ${orderRef.id}`);
}

// ── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  try {
    await writeSchemas();
    if (seed) {
      await seedDemoData();
    } else {
      console.log('  (skipping seed — pass --seed to write demo data)');
    }
    console.log('\n✅  Firestore setup complete.');
    process.exit(0);
  } catch (err) {
    console.error('❌  Error:', err);
    process.exit(1);
  }
})();
