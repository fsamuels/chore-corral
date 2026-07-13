import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import {
  toLocalDateString,
  parseLocalDateString,
  type TaskPriority,
} from './tasks'
import { totalTrackedMs } from './time-entries'

type Client = SupabaseClient<Database>

/**
 * The subset of a completed (status='done') task the Progress page renders —
 * no tags/photos, since the weekly list only needs identity, priority, and
 * completion attribution. `completed_at` is typed `string | null` to match the
 * underlying row; in practice a done task always has one, and the read path
 * (`listCompletedTasks`) drops the nulls.
 */
export interface CompletedTaskSummary {
  id: string
  title: string
  category_id: string | null
  priority: TaskPriority
  completed_at: string | null
  completed_by: string | null
  completed_by_name: string | null
}

const COMPLETED_TASK_COLUMNS =
  'id, title, category_id, priority, completed_at, completed_by, completed_by_name'

/**
 * The local-calendar-date string ("YYYY-MM-DD") of the Monday that starts the
 * week containing `date`. Weeks start Monday, computed in the user's local
 * timezone — the same local-calendar philosophy as `isTaskOverdue` /
 * `toLocalDateString`. Sunday belongs to the week that started the previous
 * Monday (six days back), not the one about to start.
 */
export function weekStartFor(date: Date): string {
  // getDay(): 0=Sunday..6=Saturday. Days since this week's Monday: Monday->0,
  // Tuesday->1, ... Sunday->6.
  const daysSinceMonday = (date.getDay() + 6) % 7
  const monday = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate() - daysSinceMonday,
  )
  return toLocalDateString(monday)
}

/**
 * Shift a "YYYY-MM-DD" Monday by `weeks` weeks (may be negative), returning the
 * resulting Monday. Arithmetic goes through `parseLocalDateString` + Date
 * component math (never `new Date(string)` UTC parsing or millisecond-based day
 * math) so it stays correct across DST transitions.
 */
export function addWeeks(weekStart: string, weeks: number): string {
  const base = parseLocalDateString(weekStart)
  const shifted = new Date(
    base.getFullYear(),
    base.getMonth(),
    base.getDate() + weeks * 7,
  )
  return toLocalDateString(shifted)
}

/**
 * The seven local date strings Monday..Sunday of the week starting `weekStart`.
 * Used for the page's date-range header and for grouping completions by day.
 */
export function weekDays(weekStart: string): string[] {
  const base = parseLocalDateString(weekStart)
  return Array.from({ length: 7 }, (_, i) =>
    toLocalDateString(
      new Date(base.getFullYear(), base.getMonth(), base.getDate() + i),
    ),
  )
}

/**
 * Whether a task's completion falls inside the week starting `weekStart`:
 * `completed_at` (a real timestamp, parsed with `Date.parse`) must be within
 * [local midnight of weekStart, local midnight of weekStart + 7 days). A null
 * or unparseable `completed_at` is never in any week.
 */
export function isCompletedInWeek(
  task: Pick<CompletedTaskSummary, 'completed_at'>,
  weekStart: string,
): boolean {
  if (!task.completed_at) return false
  const completed = Date.parse(task.completed_at)
  if (Number.isNaN(completed)) return false
  const start = parseLocalDateString(weekStart).getTime()
  const end = parseLocalDateString(addWeeks(weekStart, 1)).getTime()
  return completed >= start && completed < end
}

/** The tasks from `tasks` whose completion falls in the given week. */
export function completedTasksInWeek(
  tasks: CompletedTaskSummary[],
  weekStart: string,
): CompletedTaskSummary[] {
  return tasks.filter((task) => isCompletedInWeek(task, weekStart))
}

export interface DayGroup {
  day: string
  tasks: CompletedTaskSummary[]
}

// Chronological order within a day: earliest completion first, with id as a
// deterministic tiebreak for completions sharing a timestamp — the same
// stable-tiebreak convention as compareTasks/listTimeEntries.
function compareByCompletionAsc(
  a: CompletedTaskSummary,
  b: CompletedTaskSummary,
): number {
  const ta = a.completed_at ? Date.parse(a.completed_at) : 0
  const tb = b.completed_at ? Date.parse(b.completed_at) : 0
  if (ta !== tb) return ta - tb
  return a.id.localeCompare(b.id)
}

/**
 * Group completed tasks by the local calendar day of their `completed_at`.
 * Groups are ordered newest day first; within a day tasks run earliest-first
 * (id tiebreak). Grouping by the *local* day means a completion late one
 * evening and another just after local midnight land in different groups, even
 * if only minutes apart. Tasks with a null/unparseable `completed_at` are
 * dropped (they belong to no day).
 */
export function groupByCompletionDay(
  tasks: CompletedTaskSummary[],
): DayGroup[] {
  const byDay = new Map<string, CompletedTaskSummary[]>()
  for (const task of tasks) {
    if (!task.completed_at) continue
    const completed = Date.parse(task.completed_at)
    if (Number.isNaN(completed)) continue
    const day = toLocalDateString(new Date(completed))
    const group = byDay.get(day)
    if (group) group.push(task)
    else byDay.set(day, [task])
  }
  return [...byDay.keys()]
    .sort((a, b) => b.localeCompare(a))
    .map((day) => ({
      day,
      tasks: [...byDay.get(day)!].sort(compareByCompletionAsc),
    }))
}

// Newest completion first, id tiebreak — the order listCompletedTasks returns.
function compareByCompletionDesc(
  a: CompletedTaskSummary,
  b: CompletedTaskSummary,
): number {
  const ta = a.completed_at ? Date.parse(a.completed_at) : 0
  const tb = b.completed_at ? Date.parse(b.completed_at) : 0
  if (ta !== tb) return tb - ta
  return a.id.localeCompare(b.id)
}

/**
 * All of a farm's completed tasks, newest completion first. Because the test
 * fake only supports eq/is/in (no gte/lt), week filtering can't happen in the
 * query — this fetches every done task server-filtered by farm and status and
 * leaves week selection to the pure functions above (`completedTasksInWeek`).
 * That's fine at this app's scale (a single farm's done tasks). Rows with a
 * null `completed_at` are dropped: they can't be placed in any week.
 */
export async function listCompletedTasks(
  supabase: Client,
  farmId: string,
): Promise<CompletedTaskSummary[]> {
  const { data, error } = await supabase
    .from('tasks')
    .select(COMPLETED_TASK_COLUMNS)
    .eq('farm_id', farmId)
    .eq('status', 'done')
  if (error) throw new Error(error.message)
  return data
    .filter((task) => task.completed_at !== null)
    .sort(compareByCompletionDesc)
}

/**
 * Tracked milliseconds per task, for a set of tasks — backs both the
 * Progress page's per-row "time tracked" figure and its week-total pill (via
 * `trackedMsForTasks`). Returns an empty map immediately for an empty
 * `taskIds` (no query), so callers needn't special-case an empty week. A
 * running entry counts up to `now` via `totalTrackedMs`. A task with no
 * entries has no key in the returned map (rather than an explicit 0).
 */
export async function trackedMsByTask(
  supabase: Client,
  taskIds: string[],
  now: Date = new Date(),
): Promise<Map<string, number>> {
  if (taskIds.length === 0) return new Map()
  const { data, error } = await supabase
    .from('task_time_entries')
    .select('task_id, started_at, ended_at')
    .in('task_id', taskIds)
  if (error) throw new Error(error.message)

  const entriesByTask = new Map<
    string,
    { started_at: string; ended_at: string | null }[]
  >()
  for (const entry of data) {
    const list = entriesByTask.get(entry.task_id)
    if (list) list.push(entry)
    else entriesByTask.set(entry.task_id, [entry])
  }

  const result = new Map<string, number>()
  for (const [taskId, entries] of entriesByTask) {
    result.set(taskId, totalTrackedMs(entries, now))
  }
  return result
}

/**
 * Total tracked milliseconds across a set of tasks — the sum the Progress
 * page shows for a week's completed tasks. A thin sum over `trackedMsByTask`.
 */
export async function trackedMsForTasks(
  supabase: Client,
  taskIds: string[],
  now: Date = new Date(),
): Promise<number> {
  const byTask = await trackedMsByTask(supabase, taskIds, now)
  return [...byTask.values()].reduce((sum, ms) => sum + ms, 0)
}
