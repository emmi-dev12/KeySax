self.addEventListener("install", e => {
  self.skipWaiting();
  e.waitUntil(caches.open("keysax-v10").then(c => c.addAll([
    "./", "./index.html", "./styles.css", "./app.js", "./manifest.json", "./icon.png", "./icon-512.png"
  ])));
});
self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== "keysax-v10").map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});
self.addEventListener("fetch", e => {
  e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)));
});
