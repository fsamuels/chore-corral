import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import {
  listCompletedTasks,
  weekQueryWindow,
  type CompletedTaskSummary,
} from '~/services/progress'

/**
 * A farm's tasks completed in one week, for the read-only `/progress` page.
 * Mirrors `useTagSummaries`' shape (loading/error state, re-fetch on farm
 * switch). `week` is the displayed week's Monday ("YYYY-MM-DD", from the page's
 * `?week=` query); only that week's completions are fetched (via the padded
 * `weekQueryWindow`), and switching weeks refetches. The page still slices to
 * the exact local week with `completedTasksInWeek`.
 */
export function useWeeklyProgress(week: Ref<string>) {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, no completions in the week
  const completedTasks = ref<CompletedTaskSummary[] | null>(null)
  const completedTasksError = ref<string | null>(null)
  const loading = ref(false)

  // Bumped per fetch so a slow response for a week the user has already
  // navigated away from can't overwrite the newer week's results.
  let latestRequest = 0

  async function fetchCompletedTasks(): Promise<void> {
    const farmId = activeFarmId.value
    const request = ++latestRequest
    if (!farmId) {
      completedTasks.value = null
      return
    }
    loading.value = true
    try {
      const tasks = await listCompletedTasks(
        supabase,
        farmId,
        weekQueryWindow(week.value),
      )
      if (request !== latestRequest) return
      completedTasks.value = tasks
      completedTasksError.value = null
    } catch (error) {
      if (request !== latestRequest) return
      completedTasksError.value =
        error instanceof Error
          ? error.message
          : 'Failed to load completed tasks'
    } finally {
      if (request === latestRequest) loading.value = false
    }
  }

  // Re-fetch when the user switches farms or weeks.
  watch([activeFarmId, week], () => {
    fetchCompletedTasks()
  })

  return {
    completedTasks,
    completedTasksError,
    loading,
    fetchCompletedTasks,
  }
}
