/**
 * Keeps the shared running timer (`useRunningTimer`) in step with changes
 * made on another device — the phone starts, stops or switches a timer while
 * the laptop has the app open, and the laptop's dock bar should follow.
 * There's no realtime push, so this polls: every `SYNC_INTERVAL_MS` while
 * the tab is visible, and immediately when the tab becomes visible again or
 * the window regains focus (a laptop coming out of sleep shouldn't wait out
 * the interval showing a stale timer). Called once, from the default layout.
 *
 * Client-only and cheap: a hidden tab never polls, a poll is skipped while
 * another is still in flight or while the dock's stop is mid-request (its
 * own refresh settles the state), and `refresh` keeps the existing entry
 * object when nothing changed, so an idle poll re-renders nothing.
 */
export const SYNC_INTERVAL_MS = 30_000

export function useRunningTimerSync() {
  const user = useSupabaseUser()
  const { refresh, stopping } = useRunningTimer()

  let inFlight = false

  async function sync(): Promise<void> {
    if (inFlight || stopping.value) return
    if (!user.value || document.visibilityState !== 'visible') return
    inFlight = true
    try {
      await refresh()
    } finally {
      inFlight = false
    }
  }

  function onVisibilityChange(): void {
    if (document.visibilityState === 'visible') void sync()
  }

  let interval: ReturnType<typeof setInterval> | undefined
  onMounted(() => {
    interval = setInterval(() => void sync(), SYNC_INTERVAL_MS)
    document.addEventListener('visibilitychange', onVisibilityChange)
    window.addEventListener('focus', sync)
  })
  onUnmounted(() => {
    if (interval) clearInterval(interval)
    document.removeEventListener('visibilitychange', onVisibilityChange)
    window.removeEventListener('focus', sync)
  })
}
