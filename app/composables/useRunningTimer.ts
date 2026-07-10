import type { Database } from '~/types/database.types'
import { getRunningEntry, type TimeEntrySummary } from '~/services/time-entries'
import { getTaskTitle } from '~/services/tasks'

/**
 * The acting user's running timer, if any, plus the title of the task it's
 * on — for the global floating timer button (`FloatingTimerButton.vue`),
 * which needs this on every page, not just a task's own detail page.
 *
 * There's no realtime push here, so this refetches on every route change
 * (covers "started/stopped a timer on one page, navigated to another") and
 * leaves the moment-to-moment elapsed-time display to the caller.
 */
export function useRunningTimer() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const route = useRoute()

  const runningEntry = ref<TimeEntrySummary | null>(null)
  const taskTitle = ref<string | null>(null)

  async function refresh(): Promise<void> {
    const actorUserId = getActorUserId(user.value)
    if (!actorUserId) {
      runningEntry.value = null
      taskTitle.value = null
      return
    }
    try {
      const entry = await getRunningEntry(supabase, actorUserId)
      runningEntry.value = entry
      taskTitle.value = entry
        ? await getTaskTitle(supabase, entry.task_id)
        : null
    } catch {
      // Floating chrome, not a page's primary content — a failed fetch just
      // means no button this navigation rather than a page-level error.
      runningEntry.value = null
      taskTitle.value = null
    }
  }

  watch(() => route.path, refresh, { immediate: true })

  return { runningEntry, taskTitle, refresh }
}
