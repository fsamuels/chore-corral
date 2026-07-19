import type { Database } from '~/types/database.types'
import { savePushSubscription, removePushSubscription } from '~/services/push'

const SW_PATH = '/sw.js'

/**
 * Chore-reminder push notifications for the signed-in user's current
 * device/browser. Client-only (guarded by `import.meta.client`, a
 * compile-time flag in Nuxt — this never touches `navigator`/`window`
 * server-side); local `ref` state rather than `useState` since there's a
 * single consumer (the nav drawer's "Chore reminders" item).
 *
 * `enabled` reflects an actual `PushManager` subscription, not just
 * Notification permission — permission can be "granted" while no
 * subscription exists (e.g. cleared browser storage), and the drawer item
 * should reflect the thing that actually determines whether pushes arrive.
 */
export function usePushNotifications() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const config = useRuntimeConfig()

  const permission = ref<NotificationPermission>('default')
  const subscription = ref<PushSubscription | null>(null)
  const mutating = ref(false)
  const mutationError = ref<string | null>(null)

  const supported = computed(() => {
    if (!import.meta.client) return false
    return (
      'Notification' in window &&
      'serviceWorker' in navigator &&
      'PushManager' in window
    )
  })

  const enabled = computed(() => subscription.value !== null)

  // iOS (16.4+) only exposes Notification/PushManager once the site is added
  // to the Home Screen — in a plain Safari tab `supported` above is false
  // with no way to tell "never will be" from "would be, once installed", so
  // this gives the UI something to hint with instead.
  const needsInstall = computed(
    () => import.meta.client && !supported.value && isIOS() && !isStandalone(),
  )

  async function refreshSubscription(): Promise<void> {
    if (!supported.value) {
      subscription.value = null
      return
    }
    permission.value = Notification.permission
    try {
      const registration =
        await navigator.serviceWorker.getRegistration(SW_PATH)
      subscription.value =
        (await registration?.pushManager.getSubscription()) ?? null
    } catch {
      subscription.value = null
    }
  }

  if (import.meta.client) {
    permission.value = supported.value ? Notification.permission : 'default'
    refreshSubscription()
  }

  /**
   * Register the service worker, prompt for permission (must be called from
   * a tap — browsers ignore/auto-deny a permission prompt not triggered by a
   * user gesture), subscribe, and persist the subscription. Returns whether
   * it ended up enabled.
   */
  async function enable(): Promise<boolean> {
    mutationError.value = null
    if (!supported.value) {
      mutationError.value = needsInstall.value
        ? 'Add Chore Corral to your Home Screen first, then turn on reminders from there.'
        : 'This browser does not support push notifications.'
      return false
    }
    const actorUserId = getActorUserId(user.value)
    if (!actorUserId) {
      mutationError.value = 'You must be signed in to enable reminders.'
      return false
    }
    const vapidKey = config.public.vapidPublicKey
    if (!vapidKey) {
      mutationError.value = 'Push notifications are not configured yet.'
      return false
    }
    mutating.value = true
    try {
      const registration = await navigator.serviceWorker.register(SW_PATH)
      const result = await Notification.requestPermission()
      permission.value = result
      if (result !== 'granted') {
        mutationError.value = 'Notification permission was not granted.'
        return false
      }
      const pushSubscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        // Cast needed because @types/node's global `Uint8Array` widens its
        // buffer generic to `ArrayBufferLike` (including SharedArrayBuffer),
        // which lib.dom's `PushSubscriptionOptionsInit` (expecting
        // `ArrayBufferView<ArrayBuffer>`) then rejects — a real browser
        // Uint8Array is always backed by a plain ArrayBuffer here.
        applicationServerKey: urlBase64ToUint8Array(vapidKey) as BufferSource,
      })
      const keys = pushSubscription.toJSON().keys
      if (!keys?.p256dh || !keys?.auth) {
        throw new Error('Subscription is missing its encryption keys.')
      }
      await savePushSubscription(supabase, {
        userId: actorUserId,
        endpoint: pushSubscription.endpoint,
        p256dh: keys.p256dh,
        auth: keys.auth,
      })
      subscription.value = pushSubscription
      return true
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to enable reminders'
      return false
    } finally {
      mutating.value = false
    }
  }

  /** Unsubscribe locally and forget the saved subscription server-side. */
  async function disable(): Promise<boolean> {
    mutationError.value = null
    const current = subscription.value
    if (!current) return true
    mutating.value = true
    try {
      const endpoint = current.endpoint
      await current.unsubscribe()
      await removePushSubscription(supabase, endpoint)
      subscription.value = null
      return true
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to disable reminders'
      return false
    } finally {
      mutating.value = false
    }
  }

  return {
    supported,
    needsInstall,
    permission,
    enabled,
    mutating,
    mutationError,
    enable,
    disable,
  }
}

function isIOS(): boolean {
  if (typeof navigator === 'undefined') return false
  return (
    /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    // iPadOS 13+ reports as "MacIntel" but, unlike an actual Mac, has touch.
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  )
}

function isStandalone(): boolean {
  if (typeof window === 'undefined') return false
  return (
    window.matchMedia?.('(display-mode: standalone)').matches === true ||
    (window.navigator as { standalone?: boolean }).standalone === true
  )
}
