import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import {
  resolveTags,
  setTaskTags,
  listTagsForTasks,
  type TagSummary,
} from './tags'

export type TaskPriority = Database['public']['Enums']['task_priority']
export type TaskStatus = Database['public']['Enums']['task_status']

export interface TaskSummary {
  id: string
  title: string
  category_id: string | null
  priority: TaskPriority
  status: TaskStatus
  due_date: string | null
  notes: string | null
  lat: number | null
  lng: number | null
  created_at: string
  completed_at: string | null
  tags: TagSummary[]
}

const TASK_COLUMNS =
  'id, title, category_id, priority, status, due_date, notes, lat, lng, created_at, completed_at'

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

export function compareTasks(
  a: Pick<TaskSummary, 'priority' | 'created_at' | 'id'>,
  b: Pick<TaskSummary, 'priority' | 'created_at' | 'id'>,
): number {
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

/**
 * Validate a task's location pin: both `lat`/`lng` must be set or both must
 * be null (a half-set pin is invalid), and each must be a finite number
 * within its valid range. `0` is a legitimate coordinate (Gulf of Guinea
 * notwithstanding), so this checks `=== null`, not falsiness.
 */
export function assertValidLocation(
  lat: number | null,
  lng: number | null,
): void {
  if ((lat === null) !== (lng === null)) {
    throw new Error('Location requires both lat and lng, or neither')
  }
  if (lat === null || lng === null) return
  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    throw new Error('Location lat must be a number between -90 and 90')
  }
  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    throw new Error('Location lng must be a number between -180 and 180')
  }
}

// `resolveTags` returns tags in first-seen input order, not alphabetical, so
// create/update sort before attaching to a TaskSummary — consistent with how
// `listTags`/`listTagsForTasks` already present tags sorted by name.
function sortTagsByName(tags: TagSummary[]): TagSummary[] {
  return [...tags].sort((a, b) => a.name.localeCompare(b.name))
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
  const sorted = data.sort(compareTasks)

  const tagsByTaskId = await listTagsForTasks(
    supabase,
    sorted.map((task) => task.id),
  )
  return sorted.map((task) => ({
    ...task,
    tags: tagsByTaskId.get(task.id) ?? [],
  }))
}

/**
 * A single task by id, scoped to farmId. Returns null rather than throwing
 * when the row doesn't exist (bad id, wrong farm, or already deleted) so
 * the view/edit pages can render a "not found" state instead of an error.
 */
export async function getTask(
  supabase: Client,
  opts: { farmId: string; taskId: string },
): Promise<TaskSummary | null> {
  const { data, error } = await supabase
    .from('tasks')
    .select(TASK_COLUMNS)
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) return null

  const tagsByTaskId = await listTagsForTasks(supabase, [task.id])
  return { ...task, tags: tagsByTaskId.get(task.id) ?? [] }
}

export interface CreateTaskInput {
  farmId: string
  title: string
  categoryId: string | null
  priority: TaskPriority
  dueDate?: string | null
  notes?: string | null
  lat?: number | null
  lng?: number | null
  actorUserId: string
  tagNames?: string[]
}

/**
 * Create a task (status defaults to not_started) and log a `task_created`
 * event. Like the categories service, the two inserts are sequential, not
 * transactional — a failed log insert leaves the task in place and throws.
 * Tag resolution/attachment happens after the insert+log, for the same
 * reason: sequential, non-transactional steps.
 */
export async function createTask(
  supabase: Client,
  input: CreateTaskInput,
): Promise<TaskSummary> {
  const title = input.title.trim()
  if (!title) throw new Error('Task title is required')
  assertValidLocation(input.lat ?? null, input.lng ?? null)

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
      lat: input.lat ?? null,
      lng: input.lng ?? null,
      created_by: input.actorUserId,
      completed_at: null,
    })
    .select(TASK_COLUMNS)
    .single()
  if (error) throw new Error(error.message)

  await logTaskEvent(supabase, 'task_created', data, input)

  const tags = await resolveTags(supabase, {
    farmId: input.farmId,
    names: input.tagNames ?? [],
  })
  await setTaskTags(supabase, {
    taskId: data.id,
    tagIds: tags.map((tag) => tag.id),
  })

  return { ...data, tags: sortTagsByName(tags) }
}

export interface UpdateTaskInput {
  farmId: string
  taskId: string
  title: string
  categoryId: string | null
  priority: TaskPriority
  dueDate: string | null
  notes: string | null
  lat: number | null
  lng: number | null
  tagNames: string[]
}

/**
 * Edit a task's fields. Status is deliberately excluded — transitions go
 * through `changeTaskStatus` so `completed_at` and the activity log stay
 * consistent. Field-level edits are not logged (SPEC: major events only) —
 * that includes tag changes, which replace the task's full tag set via
 * `setTaskTags` after the field update, with no activity_log write.
 */
export async function updateTask(
  supabase: Client,
  input: UpdateTaskInput,
): Promise<TaskSummary> {
  const title = input.title.trim()
  if (!title) throw new Error('Task title is required')
  assertValidLocation(input.lat, input.lng)

  const { data, error } = await supabase
    .from('tasks')
    .update({
      title,
      category_id: input.categoryId,
      priority: input.priority,
      due_date: input.dueDate,
      notes: input.notes?.trim() || null,
      lat: input.lat,
      lng: input.lng,
    })
    .eq('id', input.taskId)
    .eq('farm_id', input.farmId)
    .select(TASK_COLUMNS)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) throw new Error('Task not found')

  const tags = await resolveTags(supabase, {
    farmId: input.farmId,
    names: input.tagNames,
  })
  await setTaskTags(supabase, {
    taskId: task.id,
    tagIds: tags.map((tag) => tag.id),
  })

  return { ...task, tags: sortTagsByName(tags) }
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

  // Status changes don't touch tags, but the return type does carry them —
  // fetch once and reuse for both the no-op and updated-row branches below.
  const tags =
    (await listTagsForTasks(supabase, [opts.taskId])).get(opts.taskId) ?? []

  if (before.status === opts.status) return { ...before, tags }

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
  return { ...task, tags }
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
