import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import {
  addReminder,
  listReminders,
  removeReminder,
  type ReminderSummary,
} from '~/services/reminders'

/**
 * Reminders for a single task. Like `useTaskShoppingList`/`useTaskTools`
 * (and unlike the per-farm composables), this is keyed on a *task*, so it
 * watches the passed task id ref and refetches whenever it changes —
 * including clearing to the "not fetched" state when the id goes null.
 */
export function useTaskReminders(taskId: Ref<string | null | undefined>) {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()

  // null = not fetched yet; [] = fetched, task has no reminders.
  const reminders = ref<ReminderSummary[] | null>(null)
  const remindersError = ref<string | null>(null)
  const loading = ref(false)

  const adding = ref(false)
  // Single surface for write-action failures (add/remove), shown inline by
  // the component near the add row.
  const mutationError = ref<string | null>(null)

  async function fetchReminders(): Promise<void> {
    const id = taskId.value
    if (!id) {
      reminders.value = null
      remindersError.value = null
      return
    }
    loading.value = true
    try {
      const list = await listReminders(supabase, id)
      // A slower fetch for a task that's no longer open must not overwrite
      // the current task's list (the watcher has already kicked off a fresh
      // fetch that owns the state now).
      if (taskId.value !== id) return
      reminders.value = list
      remindersError.value = null
    } catch (error) {
      if (taskId.value !== id) return
      remindersError.value =
        error instanceof Error ? error.message : 'Failed to load reminders'
    } finally {
      if (taskId.value === id) loading.value = false
    }
  }

  // Refetch whenever the open task changes (and on initial mount).
  watch(taskId, () => fetchReminders(), { immediate: true })

  async function add(remindAtIso: string): Promise<boolean> {
    mutationError.value = null
    const id = taskId.value
    const actorUserId = getActorUserId(user.value)
    if (!id || !actorUserId) {
      mutationError.value = 'No active chore'
      return false
    }
    adding.value = true
    try {
      const reminder = await addReminder(supabase, id, remindAtIso, actorUserId)
      // Same staleness guard as fetchReminders: don't append to another
      // task's list if the open task changed while the insert was in flight.
      if (taskId.value === id) {
        reminders.value = [...(reminders.value ?? []), reminder].sort((a, b) =>
          a.remind_at.localeCompare(b.remind_at),
        )
      }
      return true
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to add reminder'
      return false
    } finally {
      adding.value = false
    }
  }

  async function remove(reminder: ReminderSummary): Promise<void> {
    mutationError.value = null
    try {
      await removeReminder(supabase, reminder.id)
      reminders.value =
        reminders.value?.filter((r) => r.id !== reminder.id) ?? null
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to remove reminder'
    }
  }

  return {
    reminders,
    remindersError,
    loading,
    adding,
    mutationError,
    fetchReminders,
    add,
    remove,
  }
}
