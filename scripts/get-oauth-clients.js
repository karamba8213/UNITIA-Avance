// Descarga el google-services.json de CADA app por separado e imprime el raw JSON
const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const sa = require('../firebase-admin.json');

const OUT = path.join(__dirname, '..', 'unitia_app', 'android', 'app', 'google-services.json');

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

  const allClients = [];

  for (const app of APPS) {
    const r = await axios.get(
      `https://firebase.googleapis.com/v1beta1/projects/${sa.project_id}/androidApps/${app.id}/config`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const raw = Buffer.from(r.data.configFileContents, 'base64').toString('utf8');
    const parsed = JSON.parse(raw);
    const entry = parsed.client?.[0];
    const oauthClients = entry?.oauth_client || [];

    console.log(`\n=== ${app.pkg} ===`);
    oauthClients.forEach(o => {
      console.log(`  type ${o.client_type}: ${o.client_id}`);
      if (o.android_info) console.log(`    android_info: ${JSON.stringify(o.android_info)}`);
    });

    // Build correct entry for this flavor
    const correctEntry = {
      client_info: {
        mobilesdk_app_id: entry?.client_info?.mobilesdk_app_id,
        android_client_info: { package_name: app.pkg },
      },
      oauth_client: oauthClients,
      api_key: entry?.api_key,
      services: entry?.services,
    };
    allClients.push(correctEntry);
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
  console.log(`\n✅ google-services.json guardado con ${allClients.length} flavors.`);
})().catch(e => console.error(e.response?.data || e.message));
