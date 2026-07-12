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
  location_id: string | null
  created_at: string
  completed_at: string | null
  completed_by: string | null
  completed_by_name: string | null
  estimated_minutes: number | null
  tags: TagSummary[]
  photo_count: number
}

const TASK_COLUMNS =
  'id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, created_at, completed_at, completed_by, completed_by_name, estimated_minutes'

// listTasks alone embeds the photo count (a `task_photos(count)` relation),
// since it's the only read path that needs it for the home-screen list;
// getTask/create/update return photo_count from the plain row mapping below
// instead of paying for the embed on every call.
const TASK_COLUMNS_WITH_PHOTO_COUNT = `${TASK_COLUMNS}, task_photos(count)`

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

export function toLocalDateString(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

/**
 * Parse a local-calendar-date string ("YYYY-MM-DD") into a local midnight
 * `Date` — the inverse of `toLocalDateString`. Using explicit Y/M/D
 * components (not `new Date(dateString)`, which parses as UTC midnight)
 * keeps date arithmetic in local calendar days.
 */
export function parseLocalDateString(dateString: string): Date {
  const parts = dateString.split('-').map(Number)
  const [y, m, d] = parts
  if (
    parts.length !== 3 ||
    y === undefined ||
    m === undefined ||
    d === undefined
  ) {
    throw new Error(`Invalid local date string: ${dateString}`)
  }
  return new Date(y, m - 1, d)
}

// Status rank for the home-screen list's tiebreak: in_progress sorts before
// not_started (done tasks never reach these sorts — the home page filters
// to outstanding tasks first).
const STATUS_RANK: Record<TaskStatus, number> = {
  in_progress: 1,
  not_started: 0,
  done: -1,
}

/**
 * `today + 7 days` as a local-calendar-date string, matching `due_date`'s
 * plain-date format so string comparison ("<=") works the same way
 * `isTaskOverdue` compares against "today".
 */
function todayPlusDaysString(today: string, days: number): string {
  const base = parseLocalDateString(today)
  const date = new Date(
    base.getFullYear(),
    base.getMonth(),
    base.getDate() + days,
  )
  return toLocalDateString(date)
}

/**
 * Home-screen partition of outstanding (non-done) tasks: "Up next" is due
 * within the next 7 days inclusive (overdue tasks included — their due_date
 * is necessarily <= today), "Backlog" is everything else (due further out,
 * or no due date at all).
 */
export function isUpNext(
  task: Pick<TaskSummary, 'due_date'>,
  today: string,
): boolean {
  if (!task.due_date) return false
  return task.due_date <= todayPlusDaysString(today, 7)
}

export function partitionHomeTasks(
  tasks: TaskSummary[],
  today: string,
): { upNext: TaskSummary[]; backlog: TaskSummary[] } {
  const upNext: TaskSummary[] = []
  const backlog: TaskSummary[] = []
  for (const task of tasks) {
    ;(isUpNext(task, today) ? upNext : backlog).push(task)
  }
  return { upNext, backlog }
}

/**
 * "Up next" order: soonest due date first, then urgent-first, then
 * in_progress-before-not_started, then oldest-created, then id — a stable
 * tiebreak chain so equal tasks always render in the same order.
 */
export function compareUpNext(
  a: Pick<
    TaskSummary,
    'due_date' | 'priority' | 'status' | 'created_at' | 'id'
  >,
  b: Pick<
    TaskSummary,
    'due_date' | 'priority' | 'status' | 'created_at' | 'id'
  >,
): number {
  const byDueDate = (a.due_date ?? '').localeCompare(b.due_date ?? '')
  if (byDueDate !== 0) return byDueDate
  const byPriority = PRIORITY_RANK[b.priority] - PRIORITY_RANK[a.priority]
  if (byPriority !== 0) return byPriority
  const byStatus = STATUS_RANK[b.status] - STATUS_RANK[a.status]
  if (byStatus !== 0) return byStatus
  const byCreated = a.created_at.localeCompare(b.created_at)
  if (byCreated !== 0) return byCreated
  return a.id.localeCompare(b.id)
}

/**
 * "Backlog" order: urgent-first, then soonest-due-first with no-due-date
 * tasks sorted last, then in_progress-before-not_started, then
 * oldest-created, then id.
 */
export function compareBacklog(
  a: Pick<
    TaskSummary,
    'due_date' | 'priority' | 'status' | 'created_at' | 'id'
  >,
  b: Pick<
    TaskSummary,
    'due_date' | 'priority' | 'status' | 'created_at' | 'id'
  >,
): number {
  const byPriority = PRIORITY_RANK[b.priority] - PRIORITY_RANK[a.priority]
  if (byPriority !== 0) return byPriority
  const byDueDate = compareNullsLast(a.due_date, b.due_date)
  if (byDueDate !== 0) return byDueDate
  const byStatus = STATUS_RANK[b.status] - STATUS_RANK[a.status]
  if (byStatus !== 0) return byStatus
  const byCreated = a.created_at.localeCompare(b.created_at)
  if (byCreated !== 0) return byCreated
  return a.id.localeCompare(b.id)
}

function compareNullsLast(a: string | null, b: string | null): number {
  if (a === null && b === null) return 0
  if (a === null) return 1
  if (b === null) return -1
  return a.localeCompare(b)
}

/**
 * Whether a backlog task is eligible for the "Show N more" tail collapse:
 * lowest priority and no due date, i.e. nothing about it demands attention.
 */
export function isCollapsibleBacklogTask(
  task: Pick<TaskSummary, 'priority' | 'due_date'>,
): boolean {
  return task.priority === 'whenever' && task.due_date === null
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

/**
 * A task has EITHER a defined location (`location_id`) OR a freeform pin
 * (`lat`/`lng`), never both — the app-layer complement to the DB check
 * constraint `tasks_location_xor_pin`. The UI already sends explicit nulls
 * for whichever isn't in use; this is the defensive backstop so a caller
 * can't set both and trip the constraint with an opaque Postgres error.
 */
export function assertLocationXorPin(
  locationId: string | null,
  lat: number | null,
  lng: number | null,
): void {
  if (locationId !== null && (lat !== null || lng !== null)) {
    throw new Error(
      'A task has either a defined location or a map pin, not both',
    )
  }
}

/**
 * A task is credited to EITHER a completing member (`completed_by`) OR a
 * free-text name (`completed_by_name`), never both — the app-layer complement
 * to the DB check constraint `tasks_completed_by_xor_name`. The UI only ever
 * sends one with the other nulled; this is the defensive backstop so a caller
 * can't set both and trip the constraint with an opaque Postgres error.
 */
export function assertCompletedByXorName(
  completedBy: string | null,
  completedByName: string | null,
): void {
  if (completedBy !== null && completedByName !== null) {
    throw new Error(
      'A task has either a completing member or a free-text name, not both',
    )
  }
}

// Postgres `integer` max — a larger estimate would clear the positivity
// check below but fail the insert/update with an opaque overflow error.
const MAX_ESTIMATED_MINUTES = 2_147_483_647

/**
 * Validate a task's estimated time: null means "no estimate" and always
 * passes; a set value must be a positive whole number of minutes within
 * Postgres integer range. `Number.isInteger` rejects NaN/Infinity along
 * with fractions, mirroring the DB CHECK constraint (`estimated_minutes >
 * 0` on an integer column) so bad input fails fast with a readable message
 * instead of a Postgres error.
 */
export function assertValidEstimatedMinutes(minutes: number | null): void {
  if (minutes === null) return
  if (
    !Number.isInteger(minutes) ||
    minutes <= 0 ||
    minutes > MAX_ESTIMATED_MINUTES
  ) {
    throw new Error('Estimated time must be a positive whole number of minutes')
  }
}

// `resolveTags` returns tags in first-seen input order, not alphabetical, so
// create/update sort before attaching to a TaskSummary — consistent with how
// `listTags`/`listTagsForTasks` already present tags sorted by name.
function sortTagsByName(tags: TagSummary[]): TagSummary[] {
  return [...tags].sort((a, b) => a.name.localeCompare(b.name))
}

// The `task_photos(count)` embed comes back as `[{ count: number }]` (or `[]`
// when the relation has no rows) rather than a plain number — this pulls it
// out for TaskSummary's flat `photo_count` field.
function extractPhotoCount(row: { task_photos?: { count: number }[] }): number {
  return row.task_photos?.[0]?.count ?? 0
}

/** All tasks for one farm (Done included, per SPEC), urgent-first. */
export async function listTasks(
  supabase: Client,
  farmId: string,
): Promise<TaskSummary[]> {
  const { data, error } = await supabase
    .from('tasks')
    .select(TASK_COLUMNS_WITH_PHOTO_COUNT)
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
    photo_count: extractPhotoCount(task),
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
    .select(TASK_COLUMNS_WITH_PHOTO_COUNT)
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) return null

  const tagsByTaskId = await listTagsForTasks(supabase, [task.id])
  return {
    ...task,
    tags: tagsByTaskId.get(task.id) ?? [],
    photo_count: extractPhotoCount(task),
  }
}

/**
 * A task's title by id alone, with no farm_id filter — used by the
 * floating running-timer button, which only has the task id from a time
 * entry and shouldn't have to know which of the user's farms it's in. RLS
 * (farm-membership check on `tasks`) is what actually scopes this, same as
 * every other query here. Null if the task doesn't exist or isn't visible.
 */
export async function getTaskTitle(
  supabase: Client,
  taskId: string,
): Promise<string | null> {
  const { data, error } = await supabase
    .from('tasks')
    .select('id, title')
    .eq('id', taskId)
  if (error) throw new Error(error.message)
  return data[0]?.title ?? null
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
  locationId?: string | null
  estimatedMinutes?: number | null
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
  assertLocationXorPin(
    input.locationId ?? null,
    input.lat ?? null,
    input.lng ?? null,
  )
  assertValidEstimatedMinutes(input.estimatedMinutes ?? null)

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
      location_id: input.locationId ?? null,
      estimated_minutes: input.estimatedMinutes ?? null,
      created_by: input.actorUserId,
      completed_at: null,
      completed_by: null,
      completed_by_name: null,
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

  // A just-created task has no task_photos rows yet, so 0 is exact, not a
  // placeholder — no need to query the embed for a fresh insert.
  return { ...data, tags: sortTagsByName(tags), photo_count: 0 }
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
  locationId: string | null
  estimatedMinutes: number | null
  completedBy: string | null
  completedByName: string | null
  actorUserId: string
  tagNames: string[]
}

/**
 * Edit a task's fields. Status is deliberately excluded — transitions go
 * through `changeTaskStatus` so `completed_at` and the activity log stay
 * consistent. Most field-level edits are not logged (SPEC: major events
 * only) — that includes tag changes, which replace the task's full tag set
 * via `setTaskTags` after the field update, with no activity_log write, and
 * estimated-time changes, which are descriptive planning context like notes
 * (see DECISIONS.md). The two exceptions are priority and due date: a change
 * to either logs a `task_priority_changed` / `task_due_date_changed` event
 * with the old/new pair, read-before-write to capture the prior value.
 */
export async function updateTask(
  supabase: Client,
  input: UpdateTaskInput,
): Promise<TaskSummary> {
  const title = input.title.trim()
  if (!title) throw new Error('Task title is required')
  assertValidLocation(input.lat, input.lng)
  assertLocationXorPin(input.locationId ?? null, input.lat, input.lng)
  assertValidEstimatedMinutes(input.estimatedMinutes)
  assertCompletedByXorName(input.completedBy, input.completedByName)

  const { data: current, error: readError } = await supabase
    .from('tasks')
    .select(TASK_COLUMNS_WITH_PHOTO_COUNT)
    .eq('id', input.taskId)
    .eq('farm_id', input.farmId)
  if (readError) throw new Error(readError.message)
  const before = current[0]
  if (!before) throw new Error('Task not found')
  // Field edits never touch task_photos — carry the pre-update count through
  // rather than re-querying the embed after the update below.
  const photoCount = extractPhotoCount(before)

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
      location_id: input.locationId ?? null,
      estimated_minutes: input.estimatedMinutes,
      completed_by: input.completedBy,
      completed_by_name: input.completedByName,
    })
    .eq('id', input.taskId)
    .eq('farm_id', input.farmId)
    .select(TASK_COLUMNS)
  if (error) throw new Error(error.message)
  const task = data[0]
  if (!task) throw new Error('Task not found')

  if (before.priority !== task.priority) {
    await logTaskEvent(supabase, 'task_priority_changed', task, input, {
      old_priority: before.priority,
      new_priority: task.priority,
    })
  }
  if (before.due_date !== task.due_date) {
    await logTaskEvent(supabase, 'task_due_date_changed', task, input, {
      old_due_date: before.due_date,
      new_due_date: task.due_date,
    })
  }

  const tags = await resolveTags(supabase, {
    farmId: input.farmId,
    names: input.tagNames,
  })
  await setTaskTags(supabase, {
    taskId: task.id,
    tagIds: tags.map((tag) => tag.id),
  })

  return { ...task, tags: sortTagsByName(tags), photo_count: photoCount }
}

/**
 * Transition a task's status, keeping `completed_at` and the completion
 * attribution consistent: on the move to done, `completed_at` is set and
 * `completed_by` credited to the actor; on the move out of done both clear
 * (SPEC: no record of prior completion survives a reopen). `completed_by_name`
 * (the free-text fallback) is always cleared on a status change — the actor
 * auto-fill wins. Logs `task_status_changed` with the old/new pair; a no-op
 * transition (same status) skips both the write and the log entry.
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
    .select(TASK_COLUMNS_WITH_PHOTO_COUNT)
    .eq('id', opts.taskId)
    .eq('farm_id', opts.farmId)
  if (readError) throw new Error(readError.message)
  const before = current[0]
  if (!before) throw new Error('Task not found')
  // Status changes don't touch task_photos — carry the count through as-is.
  const photoCount = extractPhotoCount(before)

  // Status changes don't touch tags, but the return type does carry them —
  // fetch once and reuse for both the no-op and updated-row branches below.
  const tags =
    (await listTagsForTasks(supabase, [opts.taskId])).get(opts.taskId) ?? []

  if (before.status === opts.status) {
    return { ...before, tags, photo_count: photoCount }
  }

  const { data, error } = await supabase
    .from('tasks')
    .update({
      status: opts.status,
      completed_at: opts.status === 'done' ? new Date().toISOString() : null,
      completed_by: opts.status === 'done' ? opts.actorUserId : null,
      completed_by_name: null,
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
  return { ...task, tags, photo_count: photoCount }
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
  eventType:
    | 'task_created'
    | 'task_status_changed'
    | 'task_priority_changed'
    | 'task_due_date_changed'
    | 'task_deleted',
  task: { id: string; title: string },
  opts: { farmId: string; actorUserId: string },
  extraDetail: Record<string, string | null> = {},
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
