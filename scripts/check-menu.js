const admin = require('firebase-admin');
const path  = require('path');
admin.initializeApp({ credential: admin.credential.cert(path.resolve(__dirname, '../firebase-admin.json')) });
const db = admin.firestore();

async function main() {
  const user = await admin.auth().getUserByEmail('restaurante@test.com');
  const uid  = user.uid;
  console.log('UID:', uid);

  // Verificar restaurante
  const rest = await db.collection('restaurants').doc(uid).get();
  console.log('Restaurante existe:', rest.exists, rest.data()?.name);

  // Verificar menú sin filtros
  const all = await db.collection('restaurants').doc(uid).collection('menu').get();
  console.log('Items totales en menu:', all.size);

  // Verificar con filtro isAvailable
  const avail = await db.collection('restaurants').doc(uid).collection('menu').where('isAvailable', '==', true).get();
  console.log('Items con isAvailable=true:', avail.size);
  
  avail.forEach(d => console.log(' -', d.data().name, '| category:', d.data().category, '| isAvailable:', d.data().isAvailable));
  process.exit(0);
}
main().catch(e => { console.error(e); process.exit(1); });
