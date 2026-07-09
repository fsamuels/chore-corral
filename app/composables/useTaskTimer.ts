import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import {
  getRunningEntry,
  listTimeEntries,
  startTimer,
  stopTimer,
  type TimeEntrySummary,
} from '~/services/time-entries'

/**
 * Time tracking for a single task. Keyed on a task id ref like
 * `useTaskTools`, with the same watch/refetch/staleness-guard shape.
 *
 * Alongside the task's own entries this also tracks the acting user's
 * running entry across *all* tasks (`runningEntry`) — the
 * one-running-timer-per-user rule means starting here silently stops a
 * timer elsewhere, and the UI should be able to say so beforehand.
 */
export function useTaskTimer(taskId: Ref<string | null | undefined>) {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, no time tracked.
  const entries = ref<TimeEntrySummary[] | null>(null)
  // The user's running entry on any task; null = nothing running.
  const runningEntry = ref<TimeEntrySummary | null>(null)
  const entriesError = ref<string | null>(null)
  const loading = ref(false)
  const mutating = ref(false)
  const mutationError = ref<string | null>(null)

  async function fetchEntries(): Promise<void> {
    const id = taskId.value
    if (!id) {
      entries.value = null
      runningEntry.value = null
      entriesError.value = null
      return
    }
    const actorUserId = getActorUserId(user.value)
    loading.value = true
    try {
      const [list, running] = await Promise.all([
        listTimeEntries(supabase, id),
        actorUserId ? getRunningEntry(supabase, actorUserId) : null,
      ])
      // Staleness guard, same as useTaskTools: a slower fetch for a task
      // that's no longer open must not overwrite the current task's state.
      if (taskId.value !== id) return
      entries.value = list
      runningEntry.value = running
      entriesError.value = null
    } catch (error) {
      if (taskId.value !== id) return
      entriesError.value =
        error instanceof Error ? error.message : 'Failed to load time entries'
    } finally {
      if (taskId.value === id) loading.value = false
    }
  }

  watch(taskId, () => fetchEntries(), { immediate: true })

  /**
   * Start the timer on this task. May flip the task to in_progress (the
   * caller should refetch the task afterwards) and auto-stop the user's
   * timer on another task — both handled service-side; this just refetches
   * so the local state reflects whatever actually happened.
   */
  async function start(): Promise<boolean> {
    mutationError.value = null
    const id = taskId.value
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!id || !farmId || !actorUserId) {
      mutationError.value = 'No active task'
      return false
    }
    mutating.value = true
    try {
      await startTimer(supabase, { farmId, taskId: id, actorUserId })
      await fetchEntries()
      return true
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to start timer'
      return false
    } finally {
      mutating.value = false
    }
  }

  /** Stop the user's running timer (wherever it is). */
  async function stop(): Promise<void> {
    mutationError.value = null
    const running = runningEntry.value
    if (!running) return
    mutating.value = true
    try {
      await stopTimer(supabase, running.id)
      await fetchEntries()
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to stop timer'
    } finally {
      mutating.value = false
    }
  }

  return {
    entries,
    runningEntry,
    entriesError,
    loading,
    mutating,
    mutationError,
    fetchEntries,
    start,
    stop,
  }
}
