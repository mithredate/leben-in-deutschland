// Cache-first service worker: after the first visit the app is fully usable
// offline (questions, images, everything). Bump VERSION on any deploy to
// invalidate old caches.
const VERSION = 'lid-v7';

const CORE = [
  './',
  './index.html',
  './css/style.css',
  './js/app.js',
  './js/store.js',
  './js/srs.js',
  './data/questions.json',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

const IMAGES = [
  './img/q130.jpg', './img/q176.jpg', './img/q181.jpg', './img/q187.jpg',
  './img/q209.jpg', './img/q21.jpg', './img/q216.jpg', './img/q226.jpg',
  './img/q235.jpg', './img/q55.jpg', './img/q70.jpg',
  './img/qBB-1.jpg', './img/qBB-8.jpg', './img/qBE-1.jpg', './img/qBE-8.jpg',
  './img/qBW-1.jpg', './img/qBW-8.jpg', './img/qBY-1.jpg', './img/qBY-8.jpg',
  './img/qHB-1.jpg', './img/qHB-8.jpg', './img/qHE-1.jpg', './img/qHE-8.jpg',
  './img/qHH-1.jpg', './img/qHH-8.jpg', './img/qMV-1.jpg', './img/qMV-8.jpg',
  './img/qNI-1.jpg', './img/qNI-8.jpg', './img/qNW-1.jpg', './img/qNW-8.jpg',
  './img/qRP-1.jpg', './img/qRP-8.jpg', './img/qSH-1.jpg', './img/qSH-8.jpg',
  './img/qSL-1.jpg', './img/qSL-8.jpg', './img/qSN-1.jpg', './img/qSN-8.jpg',
  './img/qST-1.jpg', './img/qST-8.jpg', './img/qTH-1.jpg', './img/qTH-8.jpg',
];

self.addEventListener('install', (e) => {
  e.waitUntil((async () => {
    const cache = await caches.open(VERSION);
    await cache.addAll(CORE);
    // images may fail individually on flaky connections — don't block install
    await Promise.allSettled(IMAGES.map((u) => cache.add(u)));
    self.skipWaiting();
  })());
});

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key !== VERSION) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith((async () => {
    const cached = await caches.match(e.request, { ignoreSearch: true });
    if (cached) return cached;
    try {
      const res = await fetch(e.request);
      if (res.ok && new URL(e.request.url).origin === location.origin) {
        const cache = await caches.open(VERSION);
        cache.put(e.request, res.clone());
      }
      return res;
    } catch {
      return caches.match('./index.html');
    }
  })());
});
