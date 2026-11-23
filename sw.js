/* Proyección · service worker: permite abrir pantalla y Biblia sin internet */
var CACHE = 'proy-v2';
var BASE = ['./', './index.html', './manifest.json', './biblia-rv1909.json'];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) { return c.addAll(BASE); }).then(function () { return self.skipWaiting(); }));
});
self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (ks) {
    return Promise.all(ks.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});
self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  // Imágenes de fondo y logos: guardarlas para usarlas sin internet (los videos no)
  if (url.pathname.indexOf('/storage/v1/object/public/proy-medios/') >= 0 && !req.headers.has('range') && !/\.(mp4|webm)$/i.test(url.pathname)) {
    e.respondWith(caches.match(req).then(function (r) {
      return r || fetch(req).then(function (res) { if (res.ok) { var cp = res.clone(); caches.open(CACHE).then(function (c) { c.put(req, cp); }); } return res; });
    }));
    return;
  }
  // Nunca guardar datos de Supabase (siempre en vivo)
  if (url.hostname.indexOf('supabase.co') >= 0) return;
  // Biblia: primero caché
  if (url.pathname.indexOf('biblia-rv1909.json') >= 0) {
    e.respondWith(caches.match(req).then(function (r) {
      return r || fetch(req).then(function (res) { var cp = res.clone(); caches.open(CACHE).then(function (c) { c.put(req, cp); }); return res; });
    }));
    return;
  }
  // Página y librerías: primero red, si falla usa la copia guardada
  var same = url.origin === self.location.origin;
  var lib = /cdn\.tailwindcss\.com|unpkg\.com|cdn\.jsdelivr\.net|fonts\.googleapis\.com|fonts\.gstatic\.com/.test(url.hostname);
  if (same || lib) {
    e.respondWith(fetch(req).then(function (res) {
      if (res && (res.ok || res.type === 'opaque')) { var cp = res.clone(); caches.open(CACHE).then(function (c) { c.put(req, cp); }); }
      return res;
    }).catch(function () {
      return caches.match(req, { ignoreSearch: true }).then(function (r) { return r || caches.match('./index.html'); });
    }));
  }
});
