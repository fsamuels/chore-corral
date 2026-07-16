import type { Database } from '~/types/database.types'
import {
  getRunningEntry,
  stopTimer,
  type TimeEntrySummary,
} from '~/services/time-entries'
import { getTaskTitle } from '~/services/tasks'

/**
 * The acting user's running timer, if any, plus the title of the task it's
 * on — app-wide shared state (`useState`) behind the running-timer dock bar
 * (`RunningTimerBar.vue`), the home page's card play/stop buttons, and
 * `useTaskTimer`. One shared entry means starting or stopping a timer
 * anywhere updates every consumer at once — the dock bar appears the moment
 * a home-card play button is tapped, and a task page's "running on another
 * task" caption clears the moment the bar's stop button is used.
 *
 * There's no realtime push, so the default layout refreshes this on every
 * route change ("started/stopped a timer on one page, navigated to
 * another") and every mutation path (`stop` here, `useTaskTimer`'s
 * start/stop, the home page's toggle) refreshes it directly.
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

  async function refresh(): Promise<void> {
    const { entry, title } = await fetchRunningEntry()
    runningEntry.value = entry
    taskTitle.value = title
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
    try {
      await stopTimer(supabase, entry.id)
      runningEntry.value = null
      taskTitle.value = null
    } catch {
      await refresh()
    } finally {
      stopping.value = false
    }
  }

  return { runningEntry, taskTitle, stopping, refresh, fetchRunningEntry, stop }
}
