import type { Database } from '~/types/database.types'
import {
  listTimeEntriesForTasks,
  type TrackedSpan,
} from '~/services/time-entries'

/**
 * Every time entry (all members') on the chore the user's timer is running
 * on — what the running-timer dock bar totals for its "total" line. Called
 * once, from the default layout.
 *
 * Reloads when the running entry changes and on every route change, so a
 * session edited or deleted on the chore page shows up once the user
 * navigates away (the bar is hidden on that page anyway). Client-only and
 * supplementary: a failed load just hides the line.
 */
export function useRunningTaskTotal() {
  const supabase = useSupabaseClient<Database>()
  const route = useRoute()
  const { runningEntry } = useRunningTimer()

  const spans = shallowRef<TrackedSpan[] | null>(null)

  let requestSeq = 0
  async function load() {
    if (import.meta.server) return
    const seq = ++requestSeq
    const taskId = runningEntry.value?.task_id
    if (!taskId) {
      spans.value = null
      return
    }
    try {
      const byTask = await listTimeEntriesForTasks(supabase, [taskId])
      if (seq !== requestSeq) return
      spans.value = byTask.get(taskId) ?? []
    } catch {
      if (seq === requestSeq) spans.value = null
    }
  }

  watch(() => `${runningEntry.value?.id ?? ''}|${route.path}`, load, {
    immediate: true,
  })

  return { spans }
}
