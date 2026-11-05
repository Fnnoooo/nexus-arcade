// NEXUS -> SearXNG; query data is not intentionally logged or persisted.
const SERVER = 'https://nexus-searxng.onrender.com';
exports.handler = async (event) => {
  const headers = { 'Content-Type':'application/json; charset=utf-8', 'Cache-Control':'no-store, private', 'Referrer-Policy':'no-referrer', 'X-Content-Type-Options':'nosniff' };
  const send = (statusCode, data) => ({statusCode, headers, body:JSON.stringify(data)});
  if (event.httpMethod !== 'POST') return send(405,{error:'Use POST.'});
  let query;
  try { query=JSON.parse(event.body||'{}').q; } catch { return send(400,{error:'Invalid search request.'}); }
  if (typeof query!=='string'||!query.trim()||query.length>240) return send(400,{error:'Enter a search query of up to 240 characters.'});
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),23000);
  try {
    const response=await fetch(SERVER+'/search',{
      method:'POST',
      headers:{'Content-Type':'application/x-www-form-urlencoded','Accept':'application/json'},
      body:new URLSearchParams({q:query.trim(),format:'json',safesearch:'1'}),
      signal:controller.signal,
      redirect:'error'
    });
    if (!response.ok) return send(502,{error:'SearXNG returned HTTP '+response.status+'. Try again shortly.'});
    const data=await response.json();
    const results=(Array.isArray(data.results)?data.results:[]).slice(0,25).map(r=>({
      title:String(r.title||'').slice(0,240),
      url:String(r.url||'').slice(0,2000),
      content:String(r.content||'').slice(0,800)
    }));
    return send(200,{results});
  } catch(err) { return send(502,{error:'Search server is waking up or unavailable. Wait a moment and retry.'}); }
  finally {clearTimeout(timer);}
};
