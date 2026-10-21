export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const googleRes = await fetch(
      'https://www.google.com/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      }
    );

    const googleData = await googleRes.text();
    res.setHeader('Content-Type', 'application/json');
    return res.status(googleRes.status).send(googleData);
  } catch (err) {
    return res.status(502).json({ error: err.message });
  }
}
