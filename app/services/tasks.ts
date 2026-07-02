import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export type TaskPriority = Database['public']['Enums']['task_priority']
export type TaskStatus = Database['public']['Enums']['task_status']

// M5 works with everything on `tasks` except lat/lng, which arrive with the
// map work in M7.
export interface TaskSummary {
  id: string
  title: string
  category_id: string | null
  priority: TaskPriority
  status: TaskStatus
  due_date: string | null
  notes: string | null
  created_at: string
  completed_at: string | null
}

const TASK_COLUMNS =
  'id, title, category_id, priority, status, due_date, notes, created_at, completed_at'

type Client = SupabaseClient<Database>

// Postgres would give us urgent-first for free via `ORDER BY priority DESC`
// (the enum is declared in ascending-urgency order), but sorting client-side
// keeps the test fake free of enum-aware ordering and gives an explicit,
// unit-testable tiebreak: oldest task first within a priority tier.
const PRIORITY_RANK: Record<TaskPriority, number> = {
  urgent: 2,
  soon: 1,
  whenever: 0,
}

export function compareTasks(a: TaskSummary, b: TaskSummary): number {
  const byPriority = PRIORITY_RANK[b.priority] - PRIORITY_RANK[a.priority]
  if (byPriority !== 0) return byPriority
  const byCreated = a.created_at.localeCompare(b.created_at)
  if (byCreated !== 0) return byCreated
  return a.id.localeCompare(b.id)
}

/**
 * Whether a task should be flagged overdue: it has a due date strictly in
 * the past (due today is not overdue) and isn't Done. `due_date` is a plain
 * `date` column, so the comparison uses the local calendar date — a task due
 * "yesterday" flips to overdue at the user's local midnight, not UTC's.
 */
export function isTaskOverdue(
  task: Pick<TaskSummary, 'due_date' | 'status'>,
  now: Date = new Date(),
): boolean {
  if (!task.due_date || task.status === 'done') return false
  return task.due_date < toLocalDateString(now)
}

function toLocalDateString(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

/** All tasks for one farm (Done included, per SPEC), urgent-first. */
export async function listTasks(
  supabase: Client,
  farmId: string,
): Promise<TaskSummary[]> {
  const { data, error } = await supabase
    .from('tasks')
    .select(TASK_COLUMNS)
    .eq('farm_id', farmId)
  if (error) throw new Error(error.message)
  return data.sort(compareTasks)
}

export interface CreateTaskInput {
  farmId: string
  title: string
  categoryId: string | null
  priority: TaskPriority
  dueDate?: string | null
  notes?: string | null
  actorUserId: string
}

/**
 * Create a task (status defaults to not_started) and log a `task_created`
 * event. Like the categories service, the two inserts are sequential, not
 * transactional — a failed log insert leaves the task in place and throws.
 */
export async function createTask(
  supabase: Client,
  input: CreateTaskInput,
): Promise<TaskSummary> {
  const title = input.title.trim()
  if (!title) throw new Error('Task title is required')

  // status/completed_at match the DB defaults; passing them explicitly means
  // the minimal test fake doesn't have to know about column defaults.
  const { data, error } = await supabase
    .from('tasks')
    .insert({
      farm_id: input.farmId,
      title,
      category_id: input.categoryId,
      priority: input.priority,
      status: 'not_started',
      due_date: input.dueDate ?? null,
      notes: input.notes?.trim() || null,
      created_by: input.actorUserId,
      completed_at: null,
    })
    .select(TASK_COLUMNS)
    .single()
  if (error) throw new Error(error.message)

  await logTaskEvent(supabase, 'task_created', data, input)
  return data
}

export interface UpdateTaskInput {
  farmId: string
  taskId: string
  title: string
  categoryId: string | null
  priority: TaskPriority
  dueDate: string | null
  notes: string | null
}

/**
 * Edit a task's fields. Status is deliberately excluded — transitions go
 * through `changeTaskStatus` so `completed_at` and the activity log stay
 * consistent. Field-level edits are not logged (SPEC: major events only).
 */
export async function updateTask(
  supabase: Client,
  input: UpdateTaskInput,
): Promise<TaskSummary> {
  const title = input.title.trim()
  if (!title) throw new Error('Task title is required')

  const { data, error } = await supabase
    .from('tasks')
    .update({
      title,
      category_id: input.categoryId,
      priority: input.priority,
      due_date: input.dueDate,
      notes: input.notes?.trim() || null,
    })
    .eq('id', input.taskId)
    .eq('farm_id', input.farmId)
    .select(TASK_COLUMNS)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) throw new Error('Task not found')
  return task
}

/**
 * Transition a task's status, keeping `completed_at` consistent: set when
 * moving to done, cleared when moving out of done (SPEC: no record of prior
 * completion times survives a reopen). Logs `task_status_changed` with the
 * old/new pair; a no-op transition (same status) skips both the write and
 * the log entry.
 */
export async function changeTaskStatus(
  supabase: Client,
  opts: {
    farmId: string
    taskId: string
    status: TaskStatus
    actorUserId: string
  },
): Promise<TaskSummary> {
  const { data: current, error: readError } = await supabase
    .from('tasks')
    .select(TASK_COLUMNS)
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
  if (readError) throw new Error(readError.message)
  const before = current[0]
  if (!before) throw new Error('Task not found')
  if (before.status === opts.status) return before

  const { data, error } = await supabase
    .from('tasks')
    .update({
      status: opts.status,
      completed_at: opts.status === 'done' ? new Date().toISOString() : null,
    })
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
    .select(TASK_COLUMNS)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) throw new Error('Task not found')

  await logTaskEvent(supabase, 'task_status_changed', task, opts, {
    old_status: before.status,
    new_status: task.status,
  })
  return task
}

/**
 * Hard-delete a task (SPEC: no soft delete for tasks) and log a
 * `task_deleted` event — the log row, with its title snapshot, is the only
 * remaining trace.
 */
export async function deleteTask(
  supabase: Client,
  opts: { farmId: string; taskId: string; actorUserId: string },
): Promise<void> {
  const { data, error } = await supabase
    .from('tasks')
    .delete()
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
    .select('id, title')
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) throw new Error('Task not found')

  await logTaskEvent(supabase, 'task_deleted', task, opts)
}

// event_detail always snapshots task_title (per DATA_MODEL.md) so log
// entries stay readable after the task row is hard-deleted; task_id is a
// soft reference for the same reason.
async function logTaskEvent(
  supabase: Client,
  eventType: 'task_created' | 'task_status_changed' | 'task_deleted',
  task: { id: string; title: string },
  opts: { farmId: string; actorUserId: string },
  extraDetail: Record<string, string> = {},
): Promise<void> {
  const { error } = await supabase.from('activity_log').insert({
    farm_id: opts.farmId,
    task_id: task.id,
    event_type: eventType,
    event_detail: { task_title: task.title, ...extraDetail },
    actor_user_id: opts.actorUserId,
  })
  if (error) throw new Error(error.message)
}
