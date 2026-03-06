/**
 * firebase-setup-google-signin.js
 *
 * Usando el Service Account:
 * 1. Habilita Google Sign-In en Firebase Authentication
 * 2. Agrega el SHA-1 del debug keystore a la app Android
 * 3. Descarga el google-services.json actualizado
 * 4. Lo reemplaza en unitia_app/android/app/google-services.json
 */

const admin   = require('firebase-admin');
const { GoogleAuth } = require('google-auth-library');
const axios   = require('axios');
const fs      = require('fs');
const path    = require('path');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, '..', 'firebase-admin.json');
const serviceAccount       = require(SERVICE_ACCOUNT_PATH);

const PROJECT_ID  = serviceAccount.project_id;
const ANDROID_APP_ID = '1:864683113445:android:34250c920636799c830d0c';
const DEBUG_SHA1     = 'AE:41:EA:AC:4E:BE:07:65:C7:EF:59:1D:22:53:B4:85:4E:2E:6D:D2';
const GOOGLE_SERVICES_PATH = path.join(__dirname, '..', 'unitia_app', 'android', 'app', 'google-services.json');

// ── Get access token via Service Account ────────────────────────────────────
async function getAccessToken(scopes) {
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes,
  });
  const client = await auth.getClient();
  const token  = await client.getAccessToken();
  return token.token;
}

// ── 1. Enable Google Sign-In provider ───────────────────────────────────────
async function enableGoogleSignIn() {
  console.log('\n[1/3] Habilitando Google Sign-In en Firebase Auth…');

  const token = await getAccessToken([
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/identitytoolkit',
  ]);

  const url = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/config`;

  try {
    // PATCH: enable Google provider
    await axios.patch(
      url,
      {
        signIn: {
          allowDuplicateEmails: false,
        },
      },
      {
        headers: { Authorization: `Bearer ${token}` },
        params:  { updateMask: 'signIn.allowDuplicateEmails' },
      }
    );

    // Enable Google as Identity Provider
    const idpUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/defaultSupportedIdpConfigs/google.com`;
    try {
      await axios.patch(
        idpUrl,
        { enabled: true, clientId: '', clientSecret: '' },
        {
          headers: { Authorization: `Bearer ${token}` },
          params:  { updateMask: 'enabled' },
        }
      );
      console.log('  ✓ Google Sign-In habilitado.');
    } catch (e) {
      if (e.response?.status === 404) {
        // Provider no existe aún, crearlo
        const createUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/defaultSupportedIdpConfigs`;
        await axios.post(
          createUrl,
          { name: `projects/${PROJECT_ID}/defaultSupportedIdpConfigs/google.com`, enabled: true },
          { headers: { Authorization: `Bearer ${token}` } }
        );
        console.log('  ✓ Google Sign-In creado y habilitado.');
      } else {
        console.log('  ⚠ Google Sign-In ya estaba habilitado o requiere configuración manual en consola.');
        console.log('    Detalle:', e.response?.data?.error?.message || e.message);
      }
    }
  } catch (e) {
    console.log('  ⚠ Error al configurar Auth:', e.response?.data?.error?.message || e.message);
  }
}

// ── 2. Add SHA-1 to Android app ──────────────────────────────────────────────
async function addSha1() {
  console.log('\n[2/3] Agregando SHA-1 del debug keystore a la app Android…');
  console.log(`  SHA-1: ${DEBUG_SHA1}`);

  const token = await getAccessToken([
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
  ]);

  const listUrl = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${ANDROID_APP_ID}/sha`;

  // Check if SHA-1 already registered
  try {
    const existing = await axios.get(listUrl, { headers: { Authorization: `Bearer ${token}` } });
    const certs = existing.data.certificates || [];
    const alreadyExists = certs.some(c => c.shaHash.replace(/:/g, '').toLowerCase() === DEBUG_SHA1.replace(/:/g, '').toLowerCase());

    if (alreadyExists) {
      console.log('  ✓ SHA-1 ya estaba registrado.');
      return;
    }
  } catch (_) {}

  try {
    await axios.post(
      listUrl,
      { shaHash: DEBUG_SHA1, certType: 'SHA_1' },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('  ✓ SHA-1 registrado correctamente.');
  } catch (e) {
    console.log('  ⚠ Error al registrar SHA-1:', e.response?.data?.error?.message || e.message);
  }
}

// ── 3. Download updated google-services.json ─────────────────────────────────
async function downloadGoogleServicesJson() {
  console.log('\n[3/3] Descargando google-services.json actualizado…');

  const token = await getAccessToken([
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
  ]);

  const url = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${ANDROID_APP_ID}/config`;

  try {
    const res = await axios.get(url, { headers: { Authorization: `Bearer ${token}` } });
    const configBase64 = res.data.configFileContents;
    const json = Buffer.from(configBase64, 'base64').toString('utf8');

    // Validate it now has a web client
    const parsed = JSON.parse(json);
    const clients = parsed?.client?.[0]?.oauth_client || [];
    const hasWebClient = clients.some(c => c.client_type === 3 || c.client_type === 1);
    const hasType2 = clients.some(c => c.client_type === 2);

    fs.writeFileSync(GOOGLE_SERVICES_PATH, json, 'utf8');
    console.log(`  ✓ Guardado en: ${GOOGLE_SERVICES_PATH}`);
    console.log(`  Clientes OAuth en el archivo:`);
    clients.forEach(c => console.log(`    - client_type: ${c.client_type} → ${c.client_id}`));

    if (hasType2) {
      console.log('  ✅ Web client (type 2) presente — Google Sign-In va a funcionar.');
    } else {
      console.log('  ⚠  Web client (type 2) NO está presente todavía.');
      console.log('     Puede que Google Sign-In aún no esté configurado con OAuth consent screen.');
      console.log('     Completar en: https://console.firebase.google.com/project/unitia-57f59/authentication/providers');
    }
  } catch (e) {
    console.log('  ✗ Error al descargar:', e.response?.data?.error?.message || e.message);
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  console.log(`\n🔧  Firebase Setup — Google Sign-In`);
  console.log(`    Proyecto: ${PROJECT_ID}`);
  console.log(`    App Android: ${ANDROID_APP_ID}`);

  try {
    await enableGoogleSignIn();
    await addSha1();
    await downloadGoogleServicesJson();

    console.log('\n✅  Setup completo.');
    console.log('\nPróximos pasos:');
    console.log('  cd unitia_app && flutter clean && flutter run');
  } catch (err) {
    console.error('\n❌  Error inesperado:', err.message);
  }

  process.exit(0);
})();
