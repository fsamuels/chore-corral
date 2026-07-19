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

// Notification action ids <-> snooze minutes. Shared by the push handler
// (which offers them) and notificationclick (which acts on them).
const SNOOZE_ACTION_MINUTES = { 'snooze-10': 10, 'snooze-60': 60 }

self.addEventListener('push', (event) => {
  // The Edge Function sends JSON `{ title, body, url, tag, reminderId }`
  // (see supabase/functions/send-reminders). Payload-less or malformed
  // pushes still get a generic notification rather than silently vanishing —
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
  const reminderId = payload.reminderId

  // Snooze action buttons: Android/desktop Chrome render these directly on
  // the notification; iOS web push does NOT support notification actions at
  // all (Safari ignores the `actions` option entirely), which is exactly why
  // TaskReminders.vue also offers in-app "Snooze 10 min" / "Snooze 1 hr"
  // buttons on already-sent reminders — that's the iOS path. Only offer the
  // buttons here when there's a reminderId to act on; a malformed/generic
  // push has nothing to snooze.
  const options = {
    body,
    tag,
    icon: ICON,
    badge: ICON,
    data: { url, reminderId },
  }
  if (reminderId) {
    options.actions = [
      { action: 'snooze-10', title: 'Snooze 10 min' },
      { action: 'snooze-60', title: 'Snooze 1 hr' },
    ]
  }

  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener('notificationclick', (event) => {
  const snoozeMinutes = SNOOZE_ACTION_MINUTES[event.action]
  if (snoozeMinutes) {
    const reminderId = event.notification.data?.reminderId
    const tag = event.notification.tag
    const fallbackUrl = event.notification.data?.url ?? '/'
    event.notification.close()
    event.waitUntil(snoozeReminder(reminderId, snoozeMinutes, tag, fallbackUrl))
    return
  }

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

// Snooze a reminder from its notification action button. The service worker
// has no Supabase session of its own (it can't read the page's auth cookies
// from a push event), so this POSTs to a Nuxt server route instead — a
// same-origin fetch, so the browser attaches the session cookies for us, and
// the route builds a user-session Supabase client from them and performs the
// update under RLS (see server/api/reminders/snooze.post.ts). On success,
// shows a small confirmation reusing the same tag (replacing the original
// notification) with no actions and no reminderId, so it can't itself be
// re-snoozed. On failure, shows a notification that says so and keeps the
// original url so tapping it still opens the chore.
async function snoozeReminder(reminderId, minutes, tag, fallbackUrl) {
  try {
    if (!reminderId) throw new Error('missing reminderId')
    const response = await fetch('/api/reminders/snooze', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reminderId, minutes }),
    })
    if (!response.ok)
      throw new Error(`snooze request failed: ${response.status}`)

    const body =
      minutes === 10 ? 'Snoozed for 10 minutes.' : 'Snoozed for 1 hour.'
    await self.registration.showNotification('Chore Corral', {
      body,
      tag,
      icon: ICON,
      badge: ICON,
      data: {},
    })
  } catch {
    await self.registration.showNotification('Chore Corral', {
      body: "Couldn't snooze — open the chore to try again.",
      tag,
      icon: ICON,
      badge: ICON,
      data: { url: fallbackUrl },
    })
  }
}
