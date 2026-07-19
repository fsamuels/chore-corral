/**
 * Convert a VAPID public key from its URL-safe base64 form (what
 * `NUXT_PUBLIC_VAPID_PUBLIC_KEY` and `web-push generate-vapid-keys` both
 * produce) into the raw byte array `PushManager.subscribe`'s
 * `applicationServerKey` option requires. Standard Web Push boilerplate,
 * pulled out as a pure function so it's unit-testable without a real
 * PushManager.
 */
export function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')

  const rawData = atob(base64)
  const outputArray = new Uint8Array(rawData.length)
  for (let i = 0; i < rawData.length; i++) {
    outputArray[i] = rawData.charCodeAt(i)
  }
  return outputArray
}
