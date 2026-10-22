const admin = require('firebase-admin');
const path  = require('path');

admin.initializeApp({
  credential: admin.credential.cert(path.resolve(__dirname, '../firebase-admin.json')),
});

const auth = admin.auth();
const db   = admin.firestore();

async function main() {
  const user = await auth.getUserByEmail('restaurante@test.com');
  const uid  = user.uid;

  // Causa de prueba para vincular
  const causeSnap = await db.collection('causes').where('slug', '==', 'los-girasoles').limit(1).get();
  const cause     = causeSnap.empty ? null : { id: causeSnap.docs[0].id, name: causeSnap.docs[0].data().name };

  // Actualizar restaurante con datos completos
  await db.collection('restaurants').doc(uid).set({
    userId:             uid,
    name:               'La Parrilla Demo',
    slug:               'la-parrilla-demo',
    description:        'El mejor asado de la ciudad, cada pedido suma a una causa real.',
    address:            'Av. Corrientes 1234, CABA',
    phone:              '+54 11 4567-8901',
    category:           'Parrilla',
    city:               'Buenos Aires',
    donationPercentage: 5,
    causeId:            cause?.id ?? null,
    causeName:          cause?.name ?? null,
    isVerified:         true,
    logo:               null,
    totalDonated:       0,
    createdAt:          admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // Menú
  const menuRef = db.collection('restaurants').doc(uid).collection('menu');

  const items = [
    // Entradas
    { name: 'Empanadas (x6)',       category: 'Entradas',   price: 4800,  description: 'Empanadas de carne cortada a cuchillo, jugosas y crocantes.', isAvailable: true },
    { name: 'Provoleta',            category: 'Entradas',   price: 3200,  description: 'Queso provolone a la parrilla con orégano y tomate.', isAvailable: true },
    { name: 'Morcilla y chorizo',   category: 'Entradas',   price: 3800,  description: 'Chorizos y morcilla a la parrilla.', isAvailable: true },

    // Principales
    { name: 'Bife de chorizo',      category: 'Principales', price: 9800,  description: '400g de bife de chorizo a punto, con papas fritas.', isAvailable: true },
    { name: 'Vacío a la parrilla',  category: 'Principales', price: 8500,  description: 'Vacío entero con chimichurri de la casa.', isAvailable: true },
    { name: 'Tira de asado',        category: 'Principales', price: 8900,  description: 'Tira de asado de novillo con ensalada mixta.', isAvailable: true },
    { name: 'Pollo al disco',       category: 'Principales', price: 6500,  description: 'Pollo en salsa criolla con papas.', isAvailable: true },
    { name: 'Matambre a la pizza',  category: 'Principales', price: 7200,  description: 'Matambre fino con mozzarella, tomate y aceitunas.', isAvailable: true },

    // Bebidas
    { name: 'Gaseosa (500ml)',      category: 'Bebidas',    price: 1200,  description: 'Coca, Sprite o Fanta.', isAvailable: true },
    { name: 'Agua mineral',         category: 'Bebidas',    price: 900,   description: 'Con o sin gas.', isAvailable: true },
    { name: 'Cerveza (pinta)',       category: 'Bebidas',    price: 2200,  description: 'Rubia de barril bien fría.', isAvailable: true },
    { name: 'Vino de la casa (copa)', category: 'Bebidas',  price: 1800,  description: 'Malbec o Cabernet.', isAvailable: true },

    // Postres
    { name: 'Flan casero',          category: 'Postres',    price: 2100,  description: 'Flan con dulce de leche y crema.', isAvailable: true },
    { name: 'Ensalada de frutas',   category: 'Postres',    price: 1900,  description: 'Frutas de estación con crema o helado.', isAvailable: true },
  ];

  const batch = db.batch();
  for (const item of items) {
    const ref = menuRef.doc();
    batch.set(ref, { ...item, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }
  await batch.commit();

  console.log(`✓ Restaurante actualizado (UID: ${uid})`);
  console.log(`✓ ${items.length} items de menú creados`);
  if (cause) console.log(`✓ Vinculado a causa: ${cause.name}`);
  else console.log('⚠ Sin causa vinculada (no se encontró causa demo)');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
