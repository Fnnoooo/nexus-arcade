NEXUS Search connected to https://nexus-searxng.onrender.com

1. Install Node.js LTS from https://nodejs.org/
2. Unzip this archive to a folder on your computer.
3. Open PowerShell inside the NEXUS_SEARCH_CONNECTED_PROJECT folder (the one containing netlify.toml).
4. Run: npx netlify-cli login
5. Run: npx netlify-cli link
   Select "Link this directory to an existing project" and pick YOUR EXISTING NEXUS Netlify site.
6. Run: npx netlify-cli deploy --no-build
   This creates a DRAFT URL. Test it first! Do not use --prod yet.
7. Visit the draft URL, search "hello" on NEXUS Home.
8. Once tested, run: npx netlify-cli deploy --no-build --prod

The server URL is configured inside netlify/functions/nexus-search.js; no env vars needed.
Netlify Functions cannot be deployed by uploading index.html alone.
Free Render instances can sleep; the first search may time out while waking up. Retry after a minute.

Privacy: The app does not intentionally log queries or add search navigation history. Your browser's network panel, Netlify/Render, upstream engines, and internet providers may still see or retain request information. External result links navigate normally.
