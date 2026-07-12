import type { Database } from '~/types/database.types'
import {
  listCompletedTasks,
  type CompletedTaskSummary,
} from '~/services/progress'

/**
 * A farm's completed tasks, for the read-only `/progress` page. Mirrors
 * `useTagSummaries`' shape (loading/error state, re-fetch on farm switch).
 * Unlike week selection (which lives in the page's `?week=` query and is
 * derived client-side via `completedTasksInWeek`/`groupByCompletionDay`),
 * this composable fetches the farm's *entire* completed-task history once —
 * switching weeks slices the already-fetched list instead of re-fetching.
 */
export function useWeeklyProgress() {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no completed tasks
  const completedTasks = ref<CompletedTaskSummary[] | null>(null)
  const completedTasksError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchCompletedTasks(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      completedTasks.value = null
      return
    }
    loading.value = true
    try {
      completedTasks.value = await listCompletedTasks(supabase, farmId)
      completedTasksError.value = null
    } catch (error) {
      completedTasksError.value =
        error instanceof Error
          ? error.message
          : 'Failed to load completed tasks'
    } finally {
      loading.value = false
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchCompletedTasks()
  })

  return {
    completedTasks,
    completedTasksError,
    loading,
    fetchCompletedTasks,
  }
}
