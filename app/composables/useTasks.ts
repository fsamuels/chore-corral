import type { Database } from '~/types/database.types'
import {
  changeTaskStatus,
  compareTasks,
  createTask,
  deleteTask,
  listTasks,
  updateTask,
  type CreateTaskInput,
  type TaskStatus,
  type TaskSummary,
  type UpdateTaskInput,
} from '~/services/tasks'

/**
 * Tasks for the active farm (from `useFarms`). Mirrors `useCategories`'
 * shape: plain per-composable state, re-fetched whenever the active farm
 * changes.
 */
export function useTasks() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no tasks
  const tasks = ref<TaskSummary[] | null>(null)
  const tasksError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchTasks(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      tasks.value = null
      return
    }
    loading.value = true
    try {
      tasks.value = await listTasks(supabase, farmId)
      tasksError.value = null
    } catch (error) {
      tasksError.value =
        error instanceof Error ? error.message : 'Failed to load tasks'
    } finally {
      loading.value = false
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchTasks()
  })

  async function create(
    input: Omit<CreateTaskInput, 'farmId' | 'actorUserId'>,
  ): Promise<void> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) {
      throw new Error('No active farm or signed-in user')
    }
    const created = await createTask(supabase, {
      ...input,
      farmId,
      actorUserId,
    })
    const next = [...(tasks.value ?? []), created]
    next.sort(compareTasks)
    tasks.value = next
  }

  async function update(input: Omit<UpdateTaskInput, 'farmId'>): Promise<void> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) {
      throw new Error('No active farm or signed-in user')
    }
    const updated = await updateTask(supabase, { ...input, farmId })
    const next = (tasks.value ?? []).map((task) =>
      task.id === updated.id ? updated : task,
    )
    next.sort(compareTasks)
    tasks.value = next
  }

  async function setStatus(taskId: string, status: TaskStatus): Promise<void> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) {
      throw new Error('No active farm or signed-in user')
    }
    const updated = await changeTaskStatus(supabase, {
      farmId,
      taskId,
      status,
      actorUserId,
    })
    tasks.value =
      tasks.value?.map((task) => (task.id === updated.id ? updated : task)) ??
      null
  }

  async function remove(taskId: string): Promise<void> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) {
      throw new Error('No active farm or signed-in user')
    }
    await deleteTask(supabase, { farmId, taskId, actorUserId })
    tasks.value = tasks.value?.filter((task) => task.id !== taskId) ?? null
  }

  return {
    tasks,
    tasksError,
    loading,
    fetchTasks,
    create,
    update,
    setStatus,
    remove,
  }
}
