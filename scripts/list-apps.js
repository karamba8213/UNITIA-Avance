const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const sa = require('../firebase-admin.json');

(async () => {
  const auth = new GoogleAuth({
    credentials: sa,
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase'],
  });
  const client = await auth.getClient();
  const token = (await client.getAccessToken()).token;

  const r = await axios.get(
    `https://firebase.googleapis.com/v1beta1/projects/${sa.project_id}/androidApps`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  console.log(JSON.stringify(r.data, null, 2));
})().catch(e => console.error(e.response?.data || e.message));
