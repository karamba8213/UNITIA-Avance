/**
 * Script para actualizar el campo `city` en los restaurantes de Firestore.
 * Uso: node scripts/update-restaurant-cities.js
 *
 * Edita el array `updates` con los IDs reales de tus restaurantes y su ciudad.
 * O usa el modo automático que extrae la ciudad del campo `address`.
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-admin.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Modo 1: asignación manual ─────────────────────────────
// Llena este array con los documentos que quieres actualizar
const manualUpdates = [
  // { id: 'RESTAURANT_DOC_ID', city: 'Ciudad de México' },
  // { id: 'OTRO_ID',           city: 'Guadalajara' },
];

// ── Modo 2: extraer ciudad del campo `address` ────────────
// Intenta parsear la ciudad del address existente.
// Asume formato "Calle, Colonia, Ciudad, Estado"
function extractCity(address) {
  if (!address) return null;
  const parts = address.split(',').map((p) => p.trim());
  // Heurística: toma el 3er elemento si existe, sino el 2do
  if (parts.length >= 3) return parts[2];
  if (parts.length >= 2) return parts[1];
  return null;
}

async function run() {
  const snap = await db.collection('restaurants').get();
  console.log(`Found ${snap.size} restaurants`);

  const batch = db.batch();
  let updated = 0;

  for (const doc of snap.docs) {
    const data = doc.data();

    // Manual override takes priority
    const manual = manualUpdates.find((u) => u.id === doc.id);
    if (manual) {
      batch.update(doc.ref, { city: manual.city });
      console.log(`[MANUAL] ${data.name} → ${manual.city}`);
      updated++;
      continue;
    }

    // Auto-extract from address
    if (!data.city && data.address) {
      const city = extractCity(data.address);
      if (city) {
        batch.update(doc.ref, { city });
        console.log(`[AUTO]   ${data.name} → ${city}`);
        updated++;
      } else {
        console.log(`[SKIP]   ${data.name} — no se pudo extraer ciudad de: "${data.address}"`);
      }
    } else if (data.city) {
      console.log(`[OK]     ${data.name} → ya tiene city: "${data.city}"`);
    } else {
      console.log(`[SKIP]   ${data.name} — sin address ni city`);
    }
  }

  if (updated > 0) {
    await batch.commit();
    console.log(`\nActualizados: ${updated} restaurantes`);
  } else {
    console.log('\nNada que actualizar.');
  }

  process.exit(0);
}

run().catch((e) => { console.error(e); process.exit(1); });
