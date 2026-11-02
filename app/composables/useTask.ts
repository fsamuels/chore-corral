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

  // Latest-request-wins guard: two fetches can overlap (a `?farm=` switch
  // fires this watch while the page's initial load is also fetching, and
  // every inline save refetches), and their replies can arrive out of order.
  // Only the most recently started one may write state.
  let latestRequest = 0

  async function fetchTask(): Promise<void> {
    const request = ++latestRequest
    const farmId = activeFarmId.value
    if (!farmId) {
      task.value = undefined
      loading.value = false
      return
    }
    loading.value = true
    try {
      const result = await getTask(supabase, { farmId, taskId: taskId.value })
      if (request !== latestRequest) return
      task.value = result
      taskError.value = null
    } catch (error) {
      if (request !== latestRequest) return
      taskError.value =
        error instanceof Error ? error.message : 'Failed to load task'
    } finally {
      if (request === latestRequest) loading.value = false
    }
  }

  // Not `immediate` — mirrors `useTasks`' convention of an explicit initial
  // `await fetchTask()` in the page (so it can run after `await
  // fetchFarms()` resolves the active farm) with this watch only covering
  // later changes: switching farms, or navigating between two task ids
  // without a full page reload.
  //
  // Moving from one chore to another doesn't reuse the page in practice:
  // Nuxt's default page key is the route path with params filled in
  // (`/tasks/<id>`), so `/tasks/A` → `/tasks/B` mounts a fresh page with a
  // fresh `task`. The taskId half of this watch only matters for a caller
  // that changes the id without remounting.
  watch([taskId, activeFarmId], () => fetchTask())

  return { task, taskError, loading, fetchTask }
}
