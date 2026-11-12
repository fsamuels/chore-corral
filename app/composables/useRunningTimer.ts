import type { Database } from '~/types/database.types'
import {
  getRunningEntry,
  stopTimer,
  type TimeEntrySummary,
} from '~/services/time-entries'
import { getTaskTitle } from '~/services/tasks'
import { createLatestGate, reconcileRunningEntry } from '~/utils/running-timer'

/**
 * The acting user's running timer, if any, plus the title of the task it's
 * on — app-wide shared state (`useState`) behind the running-timer dock bar
 * (`RunningTimerBar.vue`), the home page's card play/stop buttons, and
 * `useTaskTimer`. One shared entry means starting or stopping a timer
 * anywhere updates every consumer at once — the dock bar appears the moment
 * a home-card play button is tapped, and a task page's "running on another
 * task" caption clears the moment the bar's stop button is used.
 *
 * There's no realtime push, so this is kept fresh by polling: the default
 * layout refreshes it on every route change ("started/stopped a timer on one
 * page, navigated to another"), and `useRunningTimerSync` re-checks every
 * 30s while the tab is visible and the moment it regains focus — so a timer
 * started, stopped or switched on another device (phone vs. laptop) shows up
 * here too. Every mutation path (`stop` here, `useTaskTimer`'s start/stop,
 * the home page's toggle) refreshes it directly.
 */
export function useRunningTimer() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()

  const runningEntry = useState<TimeEntrySummary | null>(
    'running-timer-entry',
    () => null,
  )
  const taskTitle = useState<string | null>('running-timer-title', () => null)
  const stopping = useState<boolean>('running-timer-stopping', () => false)
  // Bumped by every refresh and by `stop`. A fetch only applies if it's
  // still the latest when it lands — otherwise a slow poll that started
  // before a start/stop could land after it and resurrect stale state.
  const refreshSeq = useState<number>('running-timer-refresh-seq', () => 0)
  const gate = createLatestGate(refreshSeq)

  /**
   * Fetch the running entry (and its task title) without touching shared
   * state. Lets a caller that's also fetching other data (`useTaskTimer`)
   * assign everything in one synchronous block, so dependent computeds
   * never see a tick where only one side has updated.
   */
  async function fetchRunningEntry(): Promise<{
    entry: TimeEntrySummary | null
    title: string | null
  }> {
    const actorUserId = getActorUserId(user.value)
    if (!actorUserId) return { entry: null, title: null }
    try {
      const entry = await getRunningEntry(supabase, actorUserId)
      const title = entry ? await getTaskTitle(supabase, entry.task_id) : null
      return { entry, title }
    } catch {
      // Global chrome, not a page's primary content — a failed fetch just
      // means no dock bar until the next refresh rather than a page error.
      return { entry: null, title: null }
    }
  }

  /**
   * Take a token before fetching the running entry yourself (as
   * `useTaskTimer` does, alongside its own data), and hand it back to
   * `applyFetched` with the result. Every writer of the shared entry goes
   * through this pair, so only the latest fetch wins.
   */
  function beginFetch(): number {
    return gate.begin()
  }

  /**
   * Apply a fetched running entry if `token` is still the latest. Same
   * session as before keeps the existing object, so the periodic poll
   * doesn't re-trigger watchers on the entry; a changed title (renamed
   * elsewhere) still updates. Returns whether it applied.
   */
  function applyFetched(
    token: number,
    entry: TimeEntrySummary | null,
    title: string | null,
  ): boolean {
    if (!gate.isLatest(token)) return false
    runningEntry.value = reconcileRunningEntry(runningEntry.value, entry)
    taskTitle.value = title
    return true
  }

  async function refresh(): Promise<void> {
    const token = beginFetch()
    const { entry, title } = await fetchRunningEntry()
    applyFetched(token, entry, title)
  }

  /**
   * Stop the running timer from the dock bar. A failure resyncs instead of
   * surfacing an error: the realistic failure ("Timer is not running" after
   * a double-tap or a stop from another tab) means the bar is stale, and
   * refreshing hides it.
   */
  async function stop(): Promise<void> {
    const entry = runningEntry.value
    if (!entry || stopping.value) return
    stopping.value = true
    // Invalidate any poll already in flight — it may have read the entry
    // as still running.
    gate.invalidate()
    try {
      await stopTimer(supabase, entry.id)
      gate.invalidate()
      runningEntry.value = null
      taskTitle.value = null
    } catch {
      await refresh()
    } finally {
      stopping.value = false
    }
  }

  return {
    runningEntry,
    taskTitle,
    stopping,
    refresh,
    fetchRunningEntry,
    beginFetch,
    applyFetched,
    stop,
  }
}
