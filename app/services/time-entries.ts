import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import { changeTaskStatus, type TaskStatus } from './tasks'

export interface TimeEntrySummary {
  id: string
  task_id: string
  user_id: string
  started_at: string
  ended_at: string | null
  created_at: string
}

const ENTRY_COLUMNS = 'id, task_id, user_id, started_at, ended_at, created_at'

type Client = SupabaseClient<Database>

/**
 * All time entries for one task, oldest session first. `id` is a secondary
 * sort key for the same determinism reason as the tool/shopping lists —
 * `started_at` defaults to transaction-time `now()`, so two entries created
 * in one transaction would otherwise have undefined order.
 */
export async function listTimeEntries(
  supabase: Client,
  taskId: string,
): Promise<TimeEntrySummary[]> {
  const { data, error } = await supabase
    .from('task_time_entries')
    .select(ENTRY_COLUMNS)
    .eq('task_id', taskId)
    .order('started_at')
    .order('id')
  if (error) throw new Error(error.message)
  return data
}

/**
 * The user's currently running entry (ended_at IS NULL), across all tasks
 * in all their farms — the one-running-timer-per-user rule means there is
 * at most one. Null when no timer is running.
 */
export async function getRunningEntry(
  supabase: Client,
  userId: string,
): Promise<TimeEntrySummary | null> {
  const { data, error } = await supabase
    .from('task_time_entries')
    .select(ENTRY_COLUMNS)
    .eq('user_id', userId)
    .is('ended_at', null)
  if (error) throw new Error(error.message)
  return data[0] ?? null
}

/**
 * Start a timer on a task for the acting user. Three sequential,
 * non-transactional steps (the same pattern as createTask's insert+log):
 *
 * 1. Auto-stop the user's currently running entry, if any — one running
 *    timer per user, the Toggl model. The DB's partial unique index is the
 *    backstop if two clients race this.
 * 2. Insert the new running entry (ended_at null).
 * 3. If the task is not_started, flip it to in_progress via
 *    changeTaskStatus (which writes the normal task_status_changed activity
 *    log entry). One-way link only: stopping never touches status, and a
 *    task already in_progress or done is left alone.
 *
 * Timer start/stop is deliberately NOT an activity_log event — the log is
 * major-events-only per SPEC, and the entries table is its own record.
 */
export async function startTimer(
  supabase: Client,
  opts: { farmId: string; taskId: string; actorUserId: string },
): Promise<TimeEntrySummary> {
  await stopRunningEntryIfAny(supabase, opts.actorUserId)

  const { data, error } = await supabase
    .from('task_time_entries')
    .insert({
      task_id: opts.taskId,
      user_id: opts.actorUserId,
      started_at: new Date().toISOString(),
      ended_at: null,
    })
    .select(ENTRY_COLUMNS)
    .single()
  if (error) throw new Error(error.message)

  const status = await getTaskStatus(supabase, opts)
  if (status === 'not_started') {
    await changeTaskStatus(supabase, {
      farmId: opts.farmId,
      taskId: opts.taskId,
      status: 'in_progress',
      actorUserId: opts.actorUserId,
    })
  }

  return data
}

/**
 * Stop a running entry. The `.is('ended_at', null)` guard makes a
 * double-stop (two tabs, a stale button) a "not found" error rather than
 * silently rewriting a closed entry's end time.
 */
export async function stopTimer(
  supabase: Client,
  entryId: string,
): Promise<TimeEntrySummary> {
  const { data, error } = await supabase
    .from('task_time_entries')
    .update({ ended_at: new Date().toISOString() })
    .eq('id', entryId)
    .is('ended_at', null)
    .select(ENTRY_COLUMNS)
  if (error) throw new Error(error.message)
  const entry = data[0]
  if (!entry) throw new Error('Timer is not running')
  return entry
}

/**
 * Rewrite a closed entry's start/end times. The `.not('ended_at', 'is',
 * null)` guard makes editing a still-running entry (a stale UI whose entry
 * list predates a start elsewhere) a "not found" error rather than silently
 * closing it — the same rationale as stopTimer's double-stop guard. The
 * DB's `ended_at > started_at` check constraint backstops an inverted
 * range; the UI validates it first for a friendlier message.
 */
export async function updateTimeEntry(
  supabase: Client,
  opts: { entryId: string; startedAt: string; endedAt: string },
): Promise<TimeEntrySummary> {
  const { data, error } = await supabase
    .from('task_time_entries')
    .update({ started_at: opts.startedAt, ended_at: opts.endedAt })
    .eq('id', opts.entryId)
    .not('ended_at', 'is', null)
    .select(ENTRY_COLUMNS)
  if (error) throw new Error(error.message)
  const entry = data[0]
  if (!entry) throw new Error('Time entry not found')
  return entry
}

/**
 * Delete a closed entry. The same `.not('ended_at', 'is', null)` guard as
 * updateTimeEntry: the running entry must be paused before it can be
 * deleted — the UI enforces that, this backstops it.
 */
export async function deleteTimeEntry(
  supabase: Client,
  entryId: string,
): Promise<void> {
  const { data, error } = await supabase
    .from('task_time_entries')
    .delete()
    .eq('id', entryId)
    .not('ended_at', 'is', null)
    .select(ENTRY_COLUMNS)
  if (error) throw new Error(error.message)
  if (!data[0]) throw new Error('Time entry not found')
}

async function stopRunningEntryIfAny(
  supabase: Client,
  userId: string,
): Promise<void> {
  const { error } = await supabase
    .from('task_time_entries')
    .update({ ended_at: new Date().toISOString() })
    .eq('user_id', userId)
    .is('ended_at', null)
  if (error) throw new Error(error.message)
}

async function getTaskStatus(
  supabase: Client,
  opts: { farmId: string; taskId: string },
): Promise<TaskStatus> {
  const { data, error } = await supabase
    .from('tasks')
    .select('id, status')
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) throw new Error('Chore not found')
  return task.status
}

/**
 * Total tracked milliseconds across a task's entries. A running entry
 * (ended_at null) counts up to `now`, so callers re-invoking this on a
 * ticker get a live total. Entries with unparseable timestamps contribute
 * nothing rather than poisoning the sum with NaN.
 */
export function totalTrackedMs(
  entries: Pick<TimeEntrySummary, 'started_at' | 'ended_at'>[],
  now: Date = new Date(),
): number {
  let total = 0
  for (const entry of entries) {
    const start = Date.parse(entry.started_at)
    const end =
      entry.ended_at === null ? now.getTime() : Date.parse(entry.ended_at)
    if (Number.isNaN(start) || Number.isNaN(end)) continue
    total += Math.max(0, end - start)
  }
  return total
}
