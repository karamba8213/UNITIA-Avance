/**
 * Crea 4 causas de prueba en Firebase Auth + Firestore.
 * Uso: node scripts/seed-causes.js
 */

const admin = require('firebase-admin');
const path  = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'firebase-admin.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db   = admin.firestore();
const auth = admin.auth();
const now  = admin.firestore.FieldValue.serverTimestamp();

const CAUSES = [
  {
    email:    'causa.ninos@unitia.test',
    password: 'Unitia2024!',
    data: {
      name:         'Niños con Futuro',
      slug:         'ninos-con-futuro',
      description:  'Becas y útiles escolares para niños en zonas rurales de Sinaloa.',
      story:        'En 2021 un grupo de maestros voluntarios decidió que ningún niño debería dejar la escuela por falta de recursos. Hoy apoyamos a más de 300 familias en 12 comunidades rurales de Sinaloa, entregando útiles, uniformes y becas mensuales. Cada pedido que haces financia directamente el futuro de un niño.',
      targetAmount: 120000,
      totalRaised:  84350,
      helpersCount: 312,
      isVerified:   true,
    },
  },
  {
    email:    'causa.adultos@unitia.test',
    password: 'Unitia2024!',
    data: {
      name:         'Abuelos Felices',
      slug:         'abuelos-felices',
      description:  'Comidas diarias y compañía para adultos mayores en situación de abandono.',
      story:        'Miles de adultos mayores en México viven solos y con acceso limitado a alimentos nutritivos. Nuestra red de voluntarios visita hogares cada semana, lleva comida caliente y ofrece compañía. Con tu apoyo podemos llegar a más colonias y cambiar la vida de quienes más lo necesitan.',
      targetAmount: 80000,
      totalRaised:  41200,
      helpersCount: 198,
      isVerified:   true,
    },
  },
  {
    email:    'causa.ambiente@unitia.test',
    password: 'Unitia2024!',
    data: {
      name:         'Mochis Verde',
      slug:         'mochis-verde',
      description:  'Reforestación y limpieza de ríos y playas en el norte de Sinaloa.',
      story:        'Los Mochis y sus alrededores enfrentan serios problemas de contaminación en ríos y zonas costeras. Organizamos jornadas de limpieza mensuales y hemos plantado más de 5,000 árboles en los últimos 2 años. Cada donación nos permite comprar más plantas nativas y equipar a nuestros voluntarios.',
      targetAmount: 60000,
      totalRaised:  22800,
      helpersCount: 134,
      isVerified:   true,
    },
  },
  {
    email:    'causa.salud@unitia.test',
    password: 'Unitia2024!',
    data: {
      name:         'Salud Para Todos',
      slug:         'salud-para-todos',
      description:  'Consultas médicas y medicamentos gratuitos para familias sin seguro.',
      story:        'Millones de mexicanos no tienen acceso a servicios de salud básicos. Nuestras brigadas médicas voluntarias ofrecen consultas, estudios básicos y medicamentos sin costo en comunidades marginadas. Con cada pedido que realizas financias una consulta o un tratamiento para alguien que de otra manera no podría pagarlo.',
      targetAmount: 200000,
      totalRaised:  97600,
      helpersCount: 521,
      isVerified:   true,
    },
  },
];

(async () => {
  try {
    for (const cause of CAUSES) {
      // 1. Firebase Auth
      let uid;
      try {
        const existing = await auth.getUserByEmail(cause.email);
        uid = existing.uid;
        console.log(`Ya existe: ${cause.email} → ${uid}`);
      } catch {
        const user = await auth.createUser({
          email:         cause.email,
          password:      cause.password,
          displayName:   cause.data.name,
          emailVerified: true,
        });
        uid = user.uid;
        console.log(`Creado: ${cause.email} → ${uid}`);
      }

      // 2. users doc
      await db.collection('users').doc(uid).set({
        email:    cause.email,
        name:     cause.data.name,
        role:     'cause',
        photoUrl: null,
      }, { merge: true });

      // 3. causes doc
      await db.collection('causes').doc(uid).set({
        userId:    uid,
        images:    [],
        logo:      null,
        createdAt: now,
        ...cause.data,
      }, { merge: true });

      console.log(`  ✓ ${cause.data.name} — meta $${cause.data.targetAmount.toLocaleString()}, recaudado $${cause.data.totalRaised.toLocaleString()}\n`);
    }

    console.log('══════════════════════════════════════════');
    console.log('  4 causas listas');
    console.log('══════════════════════════════════════════');
    console.log('  Contraseña para todas: Unitia2024!');
    console.log('');
    for (const c of CAUSES) {
      console.log(`  ${c.data.name.padEnd(22)} ${c.email}`);
    }
    console.log('══════════════════════════════════════════\n');

    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
})();
