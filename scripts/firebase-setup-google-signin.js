/**
 * firebase-setup-google-signin.js
 *
 * 1. Habilita Google Sign-In en Firebase Authentication
 * 2. Agrega el SHA-1 del debug keystore a los 3 flavor apps
 * 3. Descarga los configs de cada app y reconstruye google-services.json
 */

const { GoogleAuth } = require('google-auth-library');
const axios   = require('axios');
const fs      = require('fs');
const path    = require('path');

const SERVICE_ACCOUNT_PATH = path.join(__dirname, '..', 'firebase-admin.json');
const serviceAccount       = require(SERVICE_ACCOUNT_PATH);

const PROJECT_ID = serviceAccount.project_id;
const DEBUG_SHA1 = 'AE:41:EA:AC:4E:BE:07:65:C7:EF:59:1D:22:53:B4:85:4E:2E:6D:D2';
const GOOGLE_SERVICES_PATH = path.join(__dirname, '..', 'unitia_app', 'android', 'app', 'google-services.json');

// Los 3 flavor apps (de google-services.json actual)
const FLAVOR_APPS = [
  { id: '1:864683113445:android:ad8fc77270ae161f830d0c', pkg: 'com.unitia.app' },
  { id: '1:864683113445:android:410c989f69c11fbe830d0c', pkg: 'com.unitia.causa' },
  { id: '1:864683113445:android:504a03f6ceb2b35e830d0c', pkg: 'com.unitia.restaurant' },
];

async function getAccessToken(scopes) {
  const auth = new GoogleAuth({ credentials: serviceAccount, scopes });
  const client = await auth.getClient();
  const token  = await client.getAccessToken();
  return token.token;
}

// ── 1. Enable Google Sign-In ─────────────────────────────────────────────────
async function enableGoogleSignIn() {
  console.log('\n[1/3] Habilitando Google Sign-In en Firebase Auth…');

  const token = await getAccessToken([
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/identitytoolkit',
  ]);

  const idpUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/defaultSupportedIdpConfigs/google.com`;

  try {
    await axios.patch(
      idpUrl,
      { enabled: true },
      { headers: { Authorization: `Bearer ${token}` }, params: { updateMask: 'enabled' } }
    );
    console.log('  ✓ Google Sign-In habilitado.');
  } catch (e) {
    if (e.response?.status === 404) {
      const createUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT_ID}/defaultSupportedIdpConfigs`;
      await axios.post(
        createUrl,
        { name: `projects/${PROJECT_ID}/defaultSupportedIdpConfigs/google.com`, enabled: true },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      console.log('  ✓ Google Sign-In creado y habilitado.');
    } else {
      console.log('  ⚠ ', e.response?.data?.error?.message || e.message);
    }
  }
}

// ── 2. Add SHA-1 to each flavor app ─────────────────────────────────────────
async function addSha1ToAll() {
  console.log('\n[2/3] Registrando SHA-1 en los 3 flavor apps…');

  const token = await getAccessToken([
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
  ]);

  for (const app of FLAVOR_APPS) {
    const listUrl = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${app.id}/sha`;
    try {
      const existing = await axios.get(listUrl, { headers: { Authorization: `Bearer ${token}` } });
      const certs = existing.data.certificates || [];
      const alreadyExists = certs.some(
        c => c.shaHash.replace(/:/g, '').toLowerCase() === DEBUG_SHA1.replace(/:/g, '').toLowerCase()
      );
      if (alreadyExists) {
        console.log(`  ✓ ${app.pkg} — SHA-1 ya registrado.`);
        continue;
      }
    } catch (_) {}

    try {
      await axios.post(
        listUrl,
        { shaHash: DEBUG_SHA1, certType: 'SHA_1' },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      console.log(`  ✓ ${app.pkg} — SHA-1 registrado.`);
    } catch (e) {
      console.log(`  ✗ ${app.pkg} — Error: ${e.response?.data?.error?.message || e.message}`);
    }
  }
}

// ── 3. Download & merge google-services.json ─────────────────────────────────
async function rebuildGoogleServicesJson() {
  console.log('\n[3/3] Descargando configs y reconstruyendo google-services.json…');

  const token = await getAccessToken([
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
  ]);

  // Read current file to keep project_info and non-flavor apps
  const current = JSON.parse(fs.readFileSync(GOOGLE_SERVICES_PATH, 'utf8'));
  const newClients = [];

  for (const app of FLAVOR_APPS) {
    const url = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${app.id}/config`;
    try {
      const res = await axios.get(url, { headers: { Authorization: `Bearer ${token}` } });
      const json = Buffer.from(res.data.configFileContents, 'base64').toString('utf8');
      const parsed = JSON.parse(json);
      const client = parsed.client?.[0];
      if (client) {
        newClients.push(client);
        const oauthTypes = (client.oauth_client || []).map(c => `type ${c.client_type}`).join(', ');
        console.log(`  ✓ ${app.pkg} — OAuth clients: [${oauthTypes}]`);
      }
    } catch (e) {
      console.log(`  ✗ ${app.pkg} — ${e.response?.data?.error?.message || e.message}`);
    }
  }

  if (newClients.length === 0) {
    console.log('  ✗ No se pudieron descargar los configs. Abortando.');
    return;
  }

  const merged = {
    project_info: current.project_info,
    client: newClients,
    configuration_version: '1',
  };

  fs.writeFileSync(GOOGLE_SERVICES_PATH, JSON.stringify(merged, null, 2), 'utf8');
  console.log(`\n  ✓ Guardado: ${GOOGLE_SERVICES_PATH}`);

  // Check if web client is present
  const hasType2 = newClients.some(c =>
    (c.oauth_client || []).some(o => o.client_type === 2 && !o.ios_info && !o.android_info)
  );
  if (hasType2) {
    console.log('  ✅ Web client (type 2) presente — Google Sign-In funcionará.');
  } else {
    console.log('  ⚠  Web client (type 2) no encontrado.');
    console.log('     Puede requerir configurar el OAuth Consent Screen en Google Cloud Console:');
    console.log('     https://console.cloud.google.com/apis/credentials?project=unitia-57f59');
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  console.log(`\n🔧  Firebase Setup — Google Sign-In`);
  console.log(`    Proyecto: ${PROJECT_ID}`);

  try {
    await enableGoogleSignIn();
    await addSha1ToAll();
    await rebuildGoogleServicesJson();
    console.log('\n✅  Setup completo.');
    console.log('\nPróximo paso:');
    console.log('  cd unitia_app && flutter clean && flutter run --flavor customer -t lib/main_customer.dart');
  } catch (err) {
    console.error('\n❌  Error inesperado:', err.message);
  }

  process.exit(0);
})();
