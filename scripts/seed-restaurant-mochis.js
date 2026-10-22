/**
 * Crea un usuario restaurante de prueba en Firebase Auth + Firestore
 * y publica 10 platillos. Restaurante ubicado en Los Mochis, Sinaloa.
 *
 * Uso: node scripts/seed-restaurant-mochis.js
 */

const admin = require('firebase-admin');
const path  = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'firebase-admin.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db   = admin.firestore();
const auth = admin.auth();
const now  = admin.firestore.FieldValue.serverTimestamp();

// ── Credenciales del usuario de prueba ────────────────────
const EMAIL    = 'restaurante.mochis@unitia.test';
const PASSWORD = 'Unitia2024!';

// ── Datos del restaurante ─────────────────────────────────
const RESTAURANT = {
  name:               'El Sinaloa Grill',
  slug:               'el-sinaloa-grill',
  description:        'Mariscos y antojitos sinaloenses en el corazón de Los Mochis.',
  address:            'Blvd. Jiquilpan 450, Centro, Los Mochis, Sinaloa',
  phone:              '+52 668 812 0000',
  city:               'Los Mochis',
  category:           'Mariscos',
  donationPercentage: 15,
  isVerified:         true,
  causeId:            null,
  causeName:          null,
  latitude:           25.7895,
  longitude:          -108.9863,
};

// ── 10 platillos ──────────────────────────────────────────
const MENU = [
  { name: 'Aguachile de camarón',    description: 'Camarón fresco en salsa verde con pepino y cebolla morada.', price: 180, category: 'Mariscos' },
  { name: 'Ceviche de marlín',       description: 'Marlín ahumado marinado con limón, jitomate y cilantro.',    price: 150, category: 'Mariscos' },
  { name: 'Tostadas de jaiba',       description: 'Jaiba desmenuzada sobre tostada crujiente, 3 piezas.',       price: 130, category: 'Mariscos' },
  { name: 'Camarones a la diabla',   description: 'Camarones jumbo en salsa roja picante con arroz.',           price: 220, category: 'Mariscos' },
  { name: 'Tacos de marlin (x3)',    description: 'Marlín ahumado, pico de gallo y aguacate.',                  price: 110, category: 'Tacos'    },
  { name: 'Burrito sinaloense',      description: 'Carne asada, frijoles, queso asadero y pico de gallo.',      price: 95,  category: 'Antojitos' },
  { name: 'Pozole rojo',             description: 'Caldo de maíz con cerdo, tostadas, orégano y limón.',        price: 120, category: 'Sopas'    },
  { name: 'Agua de tamarindo 500ml', description: 'Agua fresca artesanal de tamarindo.',                        price: 35,  category: 'Bebidas'  },
  { name: 'Chilorio con huevo',      description: 'Platillo tradicional sinaloense con tortillas de harina.',   price: 90,  category: 'Antojitos' },
  { name: 'Flan napolitano',         description: 'Flan casero con cajeta y nuez.',                             price: 65,  category: 'Postres'  },
];

// ── Main ──────────────────────────────────────────────────
(async () => {
  try {
    // 1. Crear usuario en Firebase Auth (o recuperar si ya existe)
    let uid;
    try {
      const existing = await auth.getUserByEmail(EMAIL);
      uid = existing.uid;
      console.log(`Usuario ya existe: ${uid}`);
    } catch {
      const user = await auth.createUser({
        email:         EMAIL,
        password:      PASSWORD,
        displayName:   RESTAURANT.name,
        emailVerified: true,
      });
      uid = user.uid;
      console.log(`Usuario creado: ${uid}`);
    }

    // 2. Documento en `users`
    await db.collection('users').doc(uid).set({
      email:    EMAIL,
      name:     RESTAURANT.name,
      role:     'restaurant',
      photoUrl: null,
    }, { merge: true });
    console.log('✓ users doc');

    // 3. Documento en `restaurants` (mismo uid)
    await db.collection('restaurants').doc(uid).set({
      userId:             uid,
      ...RESTAURANT,
      createdAt:          now,
    }, { merge: true });
    console.log('✓ restaurants doc');

    // 4. 10 platillos en subcollection `menu`
    const menuRef = db.collection('restaurants').doc(uid).collection('menu');
    const batch   = db.batch();
    for (const item of MENU) {
      batch.set(menuRef.doc(), {
        ...item,
        isAvailable: true,
        createdAt:   now,
      });
    }
    await batch.commit();
    console.log(`✓ ${MENU.length} platillos publicados`);

    console.log('\n══════════════════════════════════════');
    console.log('  Restaurante listo en Los Mochis');
    console.log('══════════════════════════════════════');
    console.log(`  Email:      ${EMAIL}`);
    console.log(`  Contraseña: ${PASSWORD}`);
    console.log(`  UID:        ${uid}`);
    console.log('══════════════════════════════════════\n');

    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
})();
