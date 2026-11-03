import type { Database } from '~/types/database.types'
import { getTaskBriefs, type TaskBrief } from '~/services/tasks'
import {
  listRecentTimeEntriesForUser,
  recentTaskIdsFromEntries,
  startTimer,
} from '~/services/time-entries'
import { pickPreviousTask } from '~/utils/recent-tasks'

// Enough recent entries to find a previous chore even after several
// sessions in a row on the current one.
const RECENT_ENTRY_LIMIT = 30

/**
 * The chore the running-timer dock's switch button offers: the one the user
 * timed most recently before the running one (see `pickPreviousTask`), plus
 * `switchTo`, which starts its timer (auto-stopping the running one, as
 * `startTimer` always does). Called once, from the default layout.
 *
 * Reloads whenever the running entry changes, so after a switch the button
 * offers the chore just switched away from: one tap to go back and forth.
 * Supplementary chrome, so a failed load just hides the button.
 */
export function usePreviousTimedTask() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { runningEntry, refresh } = useRunningTimer()
  const { showToast } = useToast()

  const previousTask = ref<TaskBrief | null>(null)
  const switching = ref(false)

  let requestSeq = 0
  async function load() {
    if (import.meta.server) return
    const seq = ++requestSeq
    const running = runningEntry.value
    const actorUserId = getActorUserId(user.value)
    if (!running || !actorUserId) {
      previousTask.value = null
      return
    }
    try {
      const entries = await listRecentTimeEntriesForUser(
        supabase,
        actorUserId,
        { limit: RECENT_ENTRY_LIMIT },
      )
      const ids = recentTaskIdsFromEntries(entries).filter(
        (id) => id !== running.task_id,
      )
      const briefs = await getTaskBriefs(supabase, ids)
      if (seq !== requestSeq) return
      previousTask.value = pickPreviousTask(ids, running.task_id, briefs)
    } catch {
      if (seq === requestSeq) previousTask.value = null
    }
  }

  watch(() => runningEntry.value?.id ?? null, load, { immediate: true })

  async function switchTo(): Promise<void> {
    const target = previousTask.value
    const actorUserId = getActorUserId(user.value)
    if (!target || !actorUserId || switching.value) return
    switching.value = true
    try {
      await startTimer(supabase, {
        farmId: target.farm_id,
        taskId: target.id,
        actorUserId,
      })
      showToast(`Timer switched to “${target.title}”`)
    } catch (error) {
      showToast(
        error instanceof Error ? error.message : 'Failed to switch timer',
        { tone: 'error' },
      )
    } finally {
      await refresh()
      switching.value = false
    }
  }

  return { previousTask, switching, switchTo }
}
