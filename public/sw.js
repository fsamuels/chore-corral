// Chore Corral service worker — push notifications only.
//
// Deliberately NOT an offline cache: this worker does no asset caching or
// fetch interception at all. Offline support is a separate roadmap item
// (see docs/ROADMAP.md); bundling it in here would mean shipping a
// cache-invalidation strategy before it's actually been designed. Until
// then this file exists solely to receive Web Push events and turn them
// into notifications while the app isn't in the foreground.
//
// Plain, unbuilt JS (no bundler step) — Nuxt serves this straight from
// public/, and the service worker spec requires a same-origin script served
// as-is, so it can't go through the app's Vite build.

const ICON = '/pwa-192x192.png'

self.addEventListener('install', () => {
  // Activate this version immediately instead of waiting for all open tabs
  // of the old worker to close — there's no cached content to conflict with.
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  // Take control of any already-open clients right away, same reasoning as
  // skipWaiting() above.
  event.waitUntil(self.clients.claim())
})

self.addEventListener('push', (event) => {
  // The Edge Function sends JSON `{ title, body, url, tag }` (see
  // supabase/functions/send-reminders). Payload-less or malformed pushes
  // still get a generic notification rather than silently vanishing —
  // Chrome penalizes a push that shows nothing.
  let payload = {}
  try {
    payload = event.data?.json() ?? {}
  } catch {
    payload = {}
  }

  const title = payload.title ?? 'Chore Corral'
  const body = payload.body ?? 'You have a chore reminder.'
  const url = payload.url ?? '/'
  const tag = payload.tag

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      tag,
      icon: ICON,
      badge: ICON,
      data: { url },
    }),
  )
})

self.addEventListener('notificationclick', (event) => {
  const url = event.notification.data?.url ?? '/'
  event.notification.close()

  event.waitUntil(
    (async () => {
      const clientsList = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      })
      // Reuse an already-open tab if one exists, navigating it to the
      // reminder's chore — better than piling up new tabs for every tap.
      for (const client of clientsList) {
        if ('focus' in client) {
          await client.focus()
          if ('navigate' in client) await client.navigate(url)
          return
        }
      }
      if (self.clients.openWindow) await self.clients.openWindow(url)
    })(),
  )
})
