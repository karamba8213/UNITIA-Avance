const admin = require('firebase-admin');
const path  = require('path');

admin.initializeApp({
  credential: admin.credential.cert(path.resolve(__dirname, '../firebase-admin.json')),
});

const auth = admin.auth();
const db   = admin.firestore();

async function createUser({ email, password, name, role, profile }) {
  let user;
  try {
    user = await auth.getUserByEmail(email);
    console.log(`Ya existe: ${email}`);
  } catch {
    user = await auth.createUser({ email, password, displayName: name });
    console.log(`Creado: ${email}`);
  }

  await db.collection('users').doc(user.uid).set({ email, name, role }, { merge: true });

  if (role === 'restaurant') {
    await db.collection('restaurants').doc(user.uid).set({
      userId: user.uid, name: profile.name, description: profile.description,
      donationPercentage: profile.donationPercentage, slug: profile.slug,
      logo: null, address: null, causeId: null, totalDonated: 0,
    }, { merge: true });
  } else if (role === 'cause') {
    await db.collection('causes').doc(user.uid).set({
      userId: user.uid, name: profile.name, description: profile.description,
      targetAmount: profile.targetAmount, totalRaised: 0,
      slug: profile.slug, logo: null, story: '',
    }, { merge: true });
  }
  return user.uid;
}

async function main() {
  await createUser({
    email: 'restaurante@test.com', password: 'test1234', name: 'Demo Restaurante',
    role: 'restaurant',
    profile: { name: 'La Parrilla Demo', description: 'Restaurante de prueba', donationPercentage: 5, slug: 'la-parrilla-demo' },
  });
  await createUser({
    email: 'causa@test.com', password: 'test1234', name: 'Demo Causa',
    role: 'cause',
    profile: { name: 'Comedor Los Girasoles', description: 'Causa de prueba', targetAmount: 10000, slug: 'los-girasoles' },
  });
  console.log('\n✓ Listo');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
