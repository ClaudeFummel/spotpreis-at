const CACHE = "spotpreis-v1";
const SHELL = ["./", "index.html", "manifest.webmanifest", "icons/icon-192.png", "icons/apple-touch-icon.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

// Network-first for everything (prices must never be stale); cache only as offline fallback.
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  const isPrices = new URL(e.request.url).pathname.endsWith("prices.json");
  e.respondWith(
    fetch(e.request, isPrices ? { cache: "no-store" } : undefined)
      .then(res => {
        if (res.ok) {
          const copy = res.clone();
          const key = isPrices ? "prices.json" : e.request;
          caches.open(CACHE).then(c => c.put(key, copy));
        }
        return res;
      })
      .catch(() => caches.match(isPrices ? "prices.json" : e.request))
  );
});
