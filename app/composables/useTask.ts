import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import { getTask, type TaskSummary } from '~/services/tasks'

/**
 * A single task for the view/edit pages, keyed on a task id ref (mirrors
 * `useTaskPhotos`'s per-entity-ref shape) rather than folded into the
 * per-farm `tasks` list in `useTasks` — a direct load of `/tasks/:id` (a
 * bookmark, a refresh, a shared link) shouldn't have to fetch every task
 * for the farm just to find one.
 *
 * `task` is three-state, unlike the two-state (null = not fetched)
 * convention in `useTasks`/`useCategories`: `undefined` = not fetched yet,
 * `null` = fetched and confirmed not found, `TaskSummary` = found. Those
 * other composables never need a "confirmed empty" state for a single
 * item, so their plain `null` doesn't carry this ambiguity.
 */
export function useTask(taskId: Ref<string>) {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  const task = ref<TaskSummary | null | undefined>(undefined)
  const taskError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchTask(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      task.value = undefined
      return
    }
    loading.value = true
    try {
      task.value = await getTask(supabase, { farmId, taskId: taskId.value })
      taskError.value = null
    } catch (error) {
      taskError.value =
        error instanceof Error ? error.message : 'Failed to load task'
    } finally {
      loading.value = false
    }
  }

  // Not `immediate` — mirrors `useTasks`' convention of an explicit initial
  // `await fetchTask()` in the page (so it can run after `await
  // fetchFarms()` resolves the active farm) with this watch only covering
  // later changes: switching farms, or navigating between two task ids
  // without a full page reload.
  watch([taskId, activeFarmId], () => fetchTask())

  return { task, taskError, loading, fetchTask }
}
