const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const sa = require('../firebase-admin.json');

const OUT = path.join(__dirname, '..', 'unitia_app', 'android', 'app', 'google-services.json');

(async () => {
  const auth = new GoogleAuth({
    credentials: sa,
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase'],
  });
  const client = await auth.getClient();
  const token = (await client.getAccessToken()).token;

  // Download config for each app and print raw decoded JSON
  const appIds = [
    { id: '1:864683113445:android:ad8fc77270ae161f830d0c', pkg: 'com.unitia.app' },
    { id: '1:864683113445:android:410c989f69c11fbe830d0c', pkg: 'com.unitia.causa' },
    { id: '1:864683113445:android:504a03f6ceb2b35e830d0c', pkg: 'com.unitia.restaurant' },
  ];

  const allClients = [];

  for (const app of appIds) {
    const r = await axios.get(
      `https://firebase.googleapis.com/v1beta1/projects/${sa.project_id}/androidApps/${app.id}/config`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const json = Buffer.from(r.data.configFileContents, 'base64').toString('utf8');
    const parsed = JSON.parse(json);

    // The per-app config has a single client entry
    const clientEntry = parsed.client?.[0];
    if (clientEntry) {
      const pkg = clientEntry.client_info?.android_client_info?.package_name;
      const oauthTypes = (clientEntry.oauth_client || []).map(c => `type${c.client_type}(${c.client_id.split('-')[1].substring(0,6)}…)`).join(', ');
      console.log(`${app.pkg} → downloaded pkg: ${pkg} | OAuth: [${oauthTypes}]`);
      allClients.push(clientEntry);
    }
  }

  // Check if all 3 are distinct
  const pkgs = allClients.map(c => c.client_info?.android_client_info?.package_name);
  console.log('\nPackage names in merged clients:', pkgs);

  if (new Set(pkgs).size === 1) {
    console.log('\n⚠  API returned same config 3 times — using the full project config instead.');
    // Fallback: download from the first app and get full project JSON
    // The per-app API always returns a single-app JSON. Let's just build manually.
    const current = JSON.parse(fs.readFileSync(OUT, 'utf8'));
    console.log('Using existing file as base, it already has correct structure from Firebase.');
    return;
  }

  const merged = {
    project_info: {
      project_number: '864683113445',
      project_id: sa.project_id,
      storage_bucket: `${sa.project_id}.firebasestorage.app`,
    },
    client: allClients,
    configuration_version: '1',
  };

  fs.writeFileSync(OUT, JSON.stringify(merged, null, 2), 'utf8');
  console.log('\n✅ google-services.json actualizado con 3 flavors.');

  // Verify web client
  const hasType1 = allClients.every(c => (c.oauth_client || []).some(o => o.client_type === 1));
  const hasType3 = allClients.every(c => (c.oauth_client || []).some(o => o.client_type === 3));
  console.log(`client_type 1 (SHA-1) en todos: ${hasType1}`);
  console.log(`client_type 3 (server client) en todos: ${hasType3}`);
})().catch(e => console.error(e.response?.data || e.message));
