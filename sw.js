// Scribo – Service Worker: App funktioniert nach dem ersten Besuch auch offline.
// Seiten: zuerst Netz (Updates kommen sofort an), sonst gespeicherte Kopie. Skripte/Icons: aus dem Speicher, im Hintergrund erneuert.
// Wichtig: Cardo liegt auf derselben Adresse (cardo-app.github.io) → nur eigene Speicher „notizen-…“ anfassen.
const CACHE = "notizen-v13";
const PDFJS = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/";
const CORE = ["./", "index.html", "manifest.webmanifest", "icons/icon.svg", "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js", PDFJS + "pdf.min.js", PDFJS + "pdf.worker.min.js"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k.startsWith("notizen-") && k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET") return;
  if (url.hostname.endsWith("supabase.co")) return; // Konto, Notizen und Dateien nie hier zwischenspeichern
  if (req.mode === "navigate") {
    const net = fetch(req).then(r => { const copy = r.clone(); caches.open(CACHE).then(c => c.put("index.html", copy)); return r; });
    const slow = new Promise((_, rej) => setTimeout(() => rej(new Error("timeout")), 3000));
    e.respondWith(Promise.race([net, slow]).catch(() => caches.match("index.html", { cacheName: CACHE }).then(hit => hit || net)));
    return;
  }
  e.respondWith(caches.match(req, { cacheName: CACHE }).then(hit => {
    const net = fetch(req).then(r => { if (r.ok || r.type === "opaque") { const copy = r.clone(); caches.open(CACHE).then(c => c.put(req, copy)); } return r; }).catch(() => hit);
    return hit || net;
  }));
});
