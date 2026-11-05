
// NEXUS HUB Search Engine
// Netlify Function -> SearXNG on Render

const SERVER = (
  process.env.SEARXNG_URL ||
  'https://nexus-searxng.onrender.com'
).replace(/\/+$/, '');

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store, private',
    'Referrer-Policy': 'no-referrer',
    'X-Content-Type-Options': 'nosniff'
  };

  const send = (statusCode, data) => ({
    statusCode,
    headers,
    body: JSON.stringify(data)
  });

  // Accept POST requests only
  if (event.httpMethod !== 'POST') {
    return send(405, {
      error: 'Use POST.'
    });
  }

  // Read search query
  let query;

  try {
    const body = JSON.parse(event.body || '{}');
    query = body.q;
  } catch (error) {
    return send(400, {
      error: 'Invalid search request.'
    });
  }

  // Validate search query
  if (
    typeof query !== 'string' ||
    !query.trim() ||
    query.length > 240
  ) {
    return send(400, {
      error: 'Enter a search query of up to 240 characters.'
    });
  }

  // Timeout protection
  const controller = new AbortController();

  const timer = setTimeout(() => {
    controller.abort();
  }, 23000);

  try {
    // Send request to SearXNG
    const response = await fetch(`${SERVER}/search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json'
      },
      body: new URLSearchParams({
        q: query.trim(),
        format: 'json',
        safesearch: '1'
      }),
      signal: controller.signal,
      redirect: 'error'
    });

    // Handle SearXNG errors
    if (!response.ok) {
      return send(502, {
        error: `SearXNG returned HTTP ${response.status}. Try again shortly.`
      });
    }

    // Parse results
    const data = await response.json();

    const results = (
      Array.isArray(data.results) ? data.results : []
    )
      .slice(0, 25)
      .map((result) => ({
        title: String(result.title || '').slice(0, 240),
        url: String(result.url || '').slice(0, 2000),
        content: String(result.content || '').slice(0, 800)
      }));

    // Return results to NEXUS HUB
    return send(200, {
      results
    });

  } catch (error) {
    return send(502, {
      error: 'Search server is waking up or unavailable. Wait a moment and retry.'
    });

  } finally {
    clearTimeout(timer);
  }
};
