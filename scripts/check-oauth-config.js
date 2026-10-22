const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const sa = require('../firebase-admin.json');

(async () => {
  const auth = new GoogleAuth({
    credentials: sa,
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/identitytoolkit',
      'https://www.googleapis.com/auth/firebase',
    ],
  });
  const client = await auth.getClient();
  const token = (await client.getAccessToken()).token;

  // Check Google IDP config
  try {
    const r = await axios.get(
      `https://identitytoolkit.googleapis.com/admin/v2/projects/${sa.project_id}/defaultSupportedIdpConfigs/google.com`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('Google IDP Config:', JSON.stringify(r.data, null, 2));
  } catch (e) {
    console.log('IDP error:', e.response?.data?.error?.message || e.message);
  }

  // Try to get web client from project config
  try {
    const r2 = await axios.get(
      `https://identitytoolkit.googleapis.com/admin/v2/projects/${sa.project_id}/config`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('\nProject Auth Config:', JSON.stringify(r2.data, null, 2));
  } catch (e) {
    console.log('Config error:', e.response?.data?.error?.message || e.message);
  }
})().catch(e => console.error(e.message));
