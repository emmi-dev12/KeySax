self.addEventListener("install", e => {
  self.skipWaiting();
  e.waitUntil(caches.open("keysax-v15").then(c => c.addAll([
    "./", "./index.html", "./styles.css", "./app.js", "./manifest.json", "./icon.png", "./icon-512.png"
  ])));
});
self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== "keysax-v15").map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});
self.addEventListener("fetch", e => {
  e.respondWith(
    fetch(e.request).then(r => {
      if (r.ok && e.request.method === "GET" && new URL(e.request.url).origin === self.location.origin) {
        const copy = r.clone();
        caches.open("keysax-v15").then(c => c.put(e.request, copy));
      }
      return r;
    }).catch(() => caches.match(e.request).then(r => r || caches.match("./")))
  );
});
