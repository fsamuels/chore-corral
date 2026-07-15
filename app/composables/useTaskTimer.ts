import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import {
  deleteTimeEntry,
  listTimeEntries,
  startTimer,
  stopTimer,
  updateTimeEntry,
  type TimeEntrySummary,
} from '~/services/time-entries'

/**
 * Time tracking for a single task. Keyed on a task id ref like
 * `useTaskTools`, with the same watch/refetch/staleness-guard shape.
 *
 * Alongside the task's own entries this also tracks the acting user's
 * running entry across *all* tasks (`runningEntry`) — the
 * one-running-timer-per-user rule means starting here silently stops a
 * timer elsewhere, and the UI should be able to say so beforehand. That
 * running entry is `useRunningTimer`'s shared state, so start/stop here
 * updates the global dock bar immediately, and a stop from the dock bar
 * updates this composable's consumers immediately.
 */
export function useTaskTimer(taskId: Ref<string | null | undefined>) {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { activeFarmId } = useFarms()
  const { runningEntry, taskTitle, fetchRunningEntry } = useRunningTimer()

  // null = not fetched yet; [] = fetched, no time tracked.
  const entries = ref<TimeEntrySummary[] | null>(null)
  const entriesError = ref<string | null>(null)
  const loading = ref(false)
  const mutating = ref(false)
  const mutationError = ref<string | null>(null)

  async function fetchEntries(): Promise<void> {
    const id = taskId.value
    if (!id) {
      entries.value = null
      entriesError.value = null
      return
    }
    loading.value = true
    try {
      const [list, running] = await Promise.all([
        listTimeEntries(supabase, id),
        fetchRunningEntry(),
      ])
      // The shared running entry is task-independent, so it's applied
      // regardless of staleness — but always alongside `entries` in this
      // same synchronous block, so `runningHere`/`showTotal` never see a
      // tick where one updated and the other hasn't (that gap was flashing
      // both counters briefly when starting a timer).
      runningEntry.value = running.entry
      taskTitle.value = running.title
      // Staleness guard, same as useTaskTools: a slower fetch for a task
      // that's no longer open must not overwrite the current task's state.
      if (taskId.value !== id) return
      entries.value = list
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

  /** Rewrite a closed entry's start/end times. */
  async function updateEntry(
    entryId: string,
    startedAt: string,
    endedAt: string,
  ): Promise<boolean> {
    mutationError.value = null
    mutating.value = true
    try {
      await updateTimeEntry(supabase, { entryId, startedAt, endedAt })
      await fetchEntries()
      return true
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to update time entry'
      return false
    } finally {
      mutating.value = false
    }
  }

  /** Delete a closed entry (the running entry must be paused first). */
  async function removeEntry(entryId: string): Promise<boolean> {
    mutationError.value = null
    mutating.value = true
    try {
      await deleteTimeEntry(supabase, entryId)
      await fetchEntries()
      return true
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to delete time entry'
      return false
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
    updateEntry,
    removeEntry,
  }
}
