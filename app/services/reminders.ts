import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import { isValidSnoozeMinutes, snoozeTargetIso } from '../utils/reminder-snooze'

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

/**
 * Snooze an already-sent reminder: push `remind_at` out by `minutes` and
 * clear `sent_at` back to null, so the same row re-fires through the
 * every-minute send-reminders pipeline as if it were freshly scheduled. This
 * is the client-side (in-app "Snooze 10 min" / "Snooze 1 hr" buttons) twin
 * of server/api/reminders/snooze.post.ts, which the service worker's
 * notification action buttons call instead — that route exists only because
 * the worker has no Supabase session, not because the logic differs; both
 * paths write the exact same columns and are equally subject to RLS.
 *
 * Follows `updateTaskPhotoCaption`'s pattern rather than chaining `.single()`
 * after `.update()`: the fake (and PostgREST in practice, per this
 * codebase's other services) doesn't support that combination, so this
 * takes `.select()`'s array and reads the first element instead.
 */
export async function snoozeReminder(
  supabase: Client,
  reminderId: string,
  minutes: unknown,
): Promise<ReminderSummary> {
  if (!isValidSnoozeMinutes(minutes)) {
    throw new Error('Snooze must be 10 minutes or 1 hour.')
  }
  const { data, error } = await supabase
    .from('task_reminders')
    .update({ remind_at: snoozeTargetIso(minutes), sent_at: null })
    .eq('id', reminderId)
    .select(REMINDER_COLUMNS)
  if (error) throw new Error(error.message)
  const reminder = data[0]
  if (!reminder) throw new Error('Reminder not found')
  return reminder
}
