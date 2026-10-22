const admin = require('firebase-admin');
const path  = require('path');

admin.initializeApp({
  credential: admin.credential.cert(path.resolve(__dirname, '../firebase-admin.json')),
});

const auth = admin.auth();
const db   = admin.firestore();

async function main() {
  const user = await auth.getUserByEmail('causa@test.com');
  const uid  = user.uid;

  await db.collection('causes').doc(uid).set({
    userId:       uid,
    name:         'Comedor Los Girasoles',
    slug:         'los-girasoles',
    description:  'Brindamos comidas a niños en situación de vulnerabilidad en el barrio La Esperanza.',
    story:        'Desde 2018 damos de comer a más de 200 chicos por día. Empezamos con una olla y hoy tenemos una cocina completa gracias a personas como vos. Cada donación nos permite comprar ingredientes frescos, mantener el espacio y darle a cada niño un plato caliente todos los días.',
    logo:         null,
    images:       [],
    targetAmount: 500000,
    totalRaised:  87500,
    helpersCount: 12,
    isVerified:   true,
    createdAt:    admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // Actualizar user doc
  await db.collection('users').doc(uid).set({ role: 'cause', name: 'Demo Causa', email: 'causa@test.com' }, { merge: true });

  // Vincular el restaurante demo a esta causa
  const restSnap = await db.collection('restaurants').where('slug', '==', 'la-parrilla-demo').limit(1).get();
  if (!restSnap.empty) {
    await restSnap.docs[0].ref.update({ causeId: uid, causeName: 'Comedor Los Girasoles' });
    console.log('✓ Restaurante demo vinculado a esta causa');
  }

  console.log(`✓ Causa creada (UID: ${uid})`);
  console.log('  Nombre:   Comedor Los Girasoles');
  console.log('  Objetivo: $500.000');
  console.log('  Recaudado: $87.500 (17.5%)');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
