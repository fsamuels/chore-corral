import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

type Client = SupabaseClient<Database>

export interface ReminderSummary {
  id: string
  task_id: string
  remind_at: string
  sent_at: string | null
  created_at: string
}

const REMINDER_COLUMNS = 'id, task_id, remind_at, sent_at, created_at'

/**
 * Validate a reminder time app-side: must parse to a real instant, and must
 * be in the future — there's no DB constraint for either (the migration
 * leaves `remind_at` a plain timestamptz), so this is the only guard, with a
 * readable message instead of whatever a downstream failure would say.
 */
export function assertValidReminderTime(iso: string): void {
  const time = new Date(iso).getTime()
  if (Number.isNaN(time)) {
    throw new Error('Enter a valid reminder date and time.')
  }
  if (time <= Date.now()) {
    throw new Error('Reminder time must be in the future.')
  }
}

/** A chore's reminders, soonest-first. */
export async function listReminders(
  supabase: Client,
  taskId: string,
): Promise<ReminderSummary[]> {
  const { data, error } = await supabase
    .from('task_reminders')
    .select(REMINDER_COLUMNS)
    .eq('task_id', taskId)
    .order('remind_at')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Schedule a reminder for a chore. `createdBy` is attribution only (the
 * column is nullable — see the migration) and, like `savePushSubscription`'s
 * `userId`, is passed in by the caller rather than resolved here, matching
 * this codebase's actor-id convention.
 */
export async function addReminder(
  supabase: Client,
  taskId: string,
  remindAtIso: string,
  createdBy: string,
): Promise<ReminderSummary> {
  assertValidReminderTime(remindAtIso)
  const { data, error } = await supabase
    .from('task_reminders')
    .insert({
      task_id: taskId,
      remind_at: remindAtIso,
      created_by: createdBy,
      sent_at: null,
    })
    .select(REMINDER_COLUMNS)
    .single()
  if (error) throw new Error(error.message)
  return data
}

/** Cancel a scheduled (or already-sent) reminder. */
export async function removeReminder(
  supabase: Client,
  reminderId: string,
): Promise<void> {
  const { error } = await supabase
    .from('task_reminders')
    .delete()
    .eq('id', reminderId)
  if (error) throw new Error(error.message)
}
