// Verifica los SHA certs de cada app y luego descarga el config correcto
const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const sa = require('../firebase-admin.json');

const OUT = path.join(__dirname, '..', 'unitia_app', 'android', 'app', 'google-services.json');
const SHA1 = 'AE:41:EA:AC:4E:BE:07:65:C7:EF:59:1D:22:53:B4:85:4E:2E:6D:D2';

const APPS = [
  { id: '1:864683113445:android:ad8fc77270ae161f830d0c', pkg: 'com.unitia.app' },
  { id: '1:864683113445:android:410c989f69c11fbe830d0c', pkg: 'com.unitia.causa' },
  { id: '1:864683113445:android:504a03f6ceb2b35e830d0c', pkg: 'com.unitia.restaurant' },
];

(async () => {
  const auth = new GoogleAuth({
    credentials: sa,
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase'],
  });
  const client = await auth.getClient();
  const token = (await client.getAccessToken()).token;
  const headers = { Authorization: `Bearer ${token}` };

  // Step 1: delete + re-add SHA-1 on causa and restaurant to force new OAuth client
  for (const app of APPS.slice(1)) {
    const listUrl = `https://firebase.googleapis.com/v1beta1/projects/${sa.project_id}/androidApps/${app.id}/sha`;
    try {
      const existing = await axios.get(listUrl, { headers });
      const certs = existing.data.certificates || [];
      for (const cert of certs) {
        await axios.delete(
          `https://firebase.googleapis.com/v1beta1/${cert.name}`,
          { headers }
        );
        console.log(`  Deleted SHA from ${app.pkg}: ${cert.name}`);
      }
    } catch(e) {
      console.log(`  Error listing SHA for ${app.pkg}:`, e.response?.data?.error?.message || e.message);
    }

    // Re-add SHA-1
    try {
      await axios.post(listUrl, { shaHash: SHA1, certType: 'SHA_1' }, { headers });
      console.log(`  Re-added SHA-1 to ${app.pkg}`);
    } catch(e) {
      console.log(`  Error adding SHA to ${app.pkg}:`, e.response?.data?.error?.message || e.message);
    }
  }

  // Step 2: wait briefly for propagation
  await new Promise(r => setTimeout(r, 3000));

  // Step 3: Download configs
  console.log('\nDownloading updated configs...');
  const allClients = [];

  for (const app of APPS) {
    const r = await axios.get(
      `https://firebase.googleapis.com/v1beta1/projects/${sa.project_id}/androidApps/${app.id}/config`,
      { headers }
    );
    const raw = Buffer.from(r.data.configFileContents, 'base64').toString('utf8');
    const parsed = JSON.parse(raw);
    const entry = parsed.client?.[0];
    const oauthClients = entry?.oauth_client || [];
    const type1 = oauthClients.find(o => o.client_type === 1);

    console.log(`${app.pkg} → type1 pkg: ${type1?.android_info?.package_name || 'none'}`);

    // Build entry with CORRECT package name regardless of what API returned
    const correctedEntry = JSON.parse(JSON.stringify(entry));
    correctedEntry.client_info.android_client_info.package_name = app.pkg;

    allClients.push(correctedEntry);
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
  console.log(`\n✅ google-services.json guardado.`);

  // Verify
  const savedJson = JSON.parse(fs.readFileSync(OUT, 'utf8'));
  savedJson.client.forEach(c => {
    const pkg = c.client_info.android_client_info.package_name;
    const types = (c.oauth_client || []).map(o => `type${o.client_type}`).join(', ');
    console.log(`  ${pkg}: [${types}]`);
  });
})().catch(e => console.error(e.response?.data || e.message));
