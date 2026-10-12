import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import {
  toLocalDateString,
  parseLocalDateString,
  type TaskPriority,
  type TaskStatus,
} from './tasks'
import { listCompletersForTasks, type TaskCompleter } from './completers'
import { totalTrackedMs } from './time-entries'
import { chunk } from '../utils/chunk'

type Client = SupabaseClient<Database>

/**
 * The subset of a completed (status='done') task the Progress page renders —
 * no tags/photos, since the weekly list only needs identity, priority, and
 * completion attribution (the completer set, attached separately). `completed_at`
 * is typed `string | null` to match the underlying row; in practice a done task
 * always has one, and the read path (`listCompletedTasks`) drops the nulls.
 */
export interface CompletedTaskSummary {
  id: string
  title: string
  category_id: string | null
  priority: TaskPriority
  created_at: string
  completed_at: string | null
  completers: TaskCompleter[]
}

const COMPLETED_TASK_COLUMNS =
  'id, title, category_id, priority, created_at, completed_at'

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

/** A half-open `[from, to)` instant range, as ISO strings. */
export interface WeekQueryWindow {
  from: string
  to: string
}

/**
 * The instant range the Progress page queries for the week starting
 * `weekStart`: local midnight of that Monday through local midnight of the
 * next Monday, padded by one day on each side, as ISO strings for
 * `.gte(from)` / `.lt(to)` filters.
 *
 * The padding is there because the page also renders on the server, whose
 * timezone (UTC on Vercel) usually isn't the viewer's: a window computed there
 * would be shifted by up to ±14 hours. A day either side covers every UTC
 * offset, so the fetched rows always include the viewer's whole local week, and
 * the pure functions (`completedTasksInWeek`, `buildActivityDayGroups`) still
 * slice to the exact local week.
 */
export function weekQueryWindow(weekStart: string): WeekQueryWindow {
  const start = parseLocalDateString(weekStart)
  const from = new Date(
    start.getFullYear(),
    start.getMonth(),
    start.getDate() - 1,
  )
  const to = new Date(
    start.getFullYear(),
    start.getMonth(),
    start.getDate() + 8,
  )
  return { from: from.toISOString(), to: to.toISOString() }
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
 * A farm's tasks completed within `window` (see `weekQueryWindow`), newest
 * completion first. Filtering by `completed_at` in the query keeps the fetch
 * proportional to one week's completions instead of the farm's whole history,
 * which would eventually overflow the completers `.in()` URL and PostgREST's
 * max-rows cap. The window is padded, so callers still slice to the exact
 * local week with `completedTasksInWeek`. Rows with a null `completed_at` are
 * dropped: they can't be placed in any week. Each task's completer set is
 * attached via a second `.in()` query (`listCompletersForTasks`), the same
 * two-query shape as tags — the test fake supports no joins.
 */
export async function listCompletedTasks(
  supabase: Client,
  farmId: string,
  window: WeekQueryWindow,
): Promise<CompletedTaskSummary[]> {
  const { data, error } = await supabase
    .from('tasks')
    .select(COMPLETED_TASK_COLUMNS)
    .eq('farm_id', farmId)
    .eq('status', 'done')
    .gte('completed_at', window.from)
    .lt('completed_at', window.to)
  if (error) throw new Error(error.message)

  const done = data.filter((task) => task.completed_at !== null)
  const completersByTask = await listCompletersForTasks(
    supabase,
    done.map((task) => task.id),
  )
  return done
    .map((task) => ({
      ...task,
      completers: completersByTask.get(task.id) ?? [],
    }))
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

// ---------------------------------------------------------------------------
// Daily activity: per-day metrics + surfacing worked-on-but-not-completed tasks
// ---------------------------------------------------------------------------

/**
 * A single time-entry's contribution to the daily activity view, trimmed to
 * the columns the pure functions need. Matches the shape `totalTrackedMs`
 * accepts, so a running entry (null `ended_at`) still counts up to `now`.
 */
export interface ActivityEntry {
  started_at: string
  ended_at: string | null
}

/**
 * A farm task that has *any* time-entry activity, carrying just enough
 * identity to render an activity row plus its raw entries. Unlike
 * `CompletedTaskSummary` this covers tasks in *any* status — the whole point
 * is to surface tasks that were worked on but not (yet) completed. `status`
 * distinguishes a task finished on another day (`done`) from one still open.
 */
export interface TaskActivity {
  id: string
  title: string
  status: TaskStatus
  category_id: string | null
  priority: TaskPriority
  created_at: string
  completed_at: string | null
  entries: ActivityEntry[]
}

/**
 * How a task relates to a given day in the activity view:
 * - `completed`   — its `completed_at` lands on this local day (the normal
 *   Progress row; the completed row always wins if a task was both worked on
 *   and completed the same day).
 * - `done-later`  — it had activity this day but was completed on a *different*
 *   day (worked Tuesday, finished Thursday → a "done later" row under Tuesday).
 * - `in-progress` — it had activity this day and isn't done yet (still open, or
 *   a running timer today).
 */
export type ActivityKind = 'completed' | 'done-later' | 'in-progress'

/** One row under a day heading in the activity view. */
export interface ActivityDayRow {
  id: string
  title: string
  category_id: string | null
  priority: TaskPriority
  kind: ActivityKind
  // The timestamp driving the row's time label and intra-day ordering:
  // `completed_at` for a completed row, else the earliest same-day entry start.
  timestamp: string
  // Milliseconds tracked on *this task* on *this day* (entries whose
  // `started_at` is this local day) — 0 for a completed row whose work landed
  // on other days.
  trackedMs: number
  // Completion attribution, populated only for `completed` rows (mirrors
  // CompletedTaskSummary); empty on worked rows, which weren't finished today.
  completers: TaskCompleter[]
  // The task's own `created_at`/`completed_at` (independent of `timestamp`,
  // which is day-scoped) — for the page's "X days to complete" figure via
  // `formatDaysToComplete`. `completedAt` is null for a still-open task.
  createdAt: string
  completedAt: string | null
}

/**
 * A day's worth of activity: the completed tasks and worked-on tasks that
 * belong to it, plus the two per-day figures the heading shows.
 */
export interface ActivityDayGroup {
  day: string
  // Number of tasks completed on this day (the `completed` rows).
  completedCount: number
  // Total milliseconds tracked on this day across *all* entries starting this
  // day — the sum of every row's `trackedMs`, since each entry's task has
  // exactly one row on the entry's day.
  trackedMs: number
  rows: ActivityDayRow[]
}

/**
 * The local calendar day ("YYYY-MM-DD") a time entry is attributed to: the
 * local day of its `started_at`. We attribute a whole entry to the day it
 * *began* rather than clipping it across midnight — the simple, DST-safe rule
 * consistent with this codebase's local-calendar-day philosophy (an entry that
 * runs 11pm→1am counts entirely on the day it started). Returns null for an
 * unparseable timestamp (it belongs to no day). Never parses the string as UTC
 * — it goes through `Date.parse` then `toLocalDateString` so the boundary is
 * local midnight, matching `groupByCompletionDay`.
 */
export function entryLocalDay(startedAt: string): string | null {
  const started = Date.parse(startedAt)
  if (Number.isNaN(started)) return null
  return toLocalDateString(new Date(started))
}

/**
 * Tracked milliseconds grouped by the local calendar day each entry *started*
 * (see `entryLocalDay`). A running entry counts up to `now` via
 * `totalTrackedMs`. Entries with an unparseable `started_at` are dropped. Days
 * with no entries have no key (rather than an explicit 0).
 */
export function trackedMsByDay(
  entries: ActivityEntry[],
  now: Date = new Date(),
): Map<string, number> {
  const byDay = new Map<string, number>()
  for (const entry of entries) {
    const day = entryLocalDay(entry.started_at)
    if (day === null) continue
    byDay.set(day, (byDay.get(day) ?? 0) + totalTrackedMs([entry], now))
  }
  return byDay
}

// The completed rows a task contributes to a given day, ordered
// earliest-completion first with an id tiebreak — the same convention as
// groupByCompletionDay. Reused when assembling each day's rows.
function toCompletedRow(
  task: CompletedTaskSummary,
  trackedMs: number,
): ActivityDayRow {
  return {
    id: task.id,
    title: task.title,
    category_id: task.category_id,
    priority: task.priority,
    kind: 'completed',
    timestamp: task.completed_at!,
    trackedMs,
    completers: task.completers,
    createdAt: task.created_at,
    completedAt: task.completed_at,
  }
}

/**
 * Assemble the Progress page's per-day activity groups for one week, merging
 * two sources:
 *
 * 1. `weekCompletedTasks` — tasks whose `completed_at` falls in the week
 *    (already sliced by `completedTasksInWeek`). Each becomes a `completed`
 *    row under its completion day.
 * 2. `activities` — the farm's tasks that have time-entry activity. Any task
 *    that has an entry *starting* on a day (see `entryLocalDay`) but wasn't
 *    completed *that* day surfaces as a worked row (`done-later` if the task is
 *    done, `in-progress` otherwise) — so the day reads as "what happened
 *    today", not just "what was finished today".
 *
 * De-duplication: if a task was both worked on and completed on the same day,
 * only the `completed` row appears (it wins), but that day's entries still
 * count toward the completed row's `trackedMs` and the day total. Each entry's
 * task therefore has exactly one row on the entry's day, so a day's `trackedMs`
 * equals the sum of its rows' `trackedMs`.
 *
 * Groups are ordered newest day first. Within a day, completed rows come first
 * (earliest completion, id tiebreak), then worked rows (earliest same-day
 * activity, id tiebreak). Running entries count up to `now`.
 */
export function buildActivityDayGroups(
  weekStart: string,
  weekCompletedTasks: CompletedTaskSummary[],
  activities: TaskActivity[],
  now: Date = new Date(),
): ActivityDayGroup[] {
  const weekDaySet = new Set(weekDays(weekStart))
  const activityById = new Map(activities.map((a) => [a.id, a]))

  // day -> completed tasks finishing that day (within the week).
  const completedByDay = new Map<string, CompletedTaskSummary[]>()
  for (const task of weekCompletedTasks) {
    if (!task.completed_at) continue
    const completed = Date.parse(task.completed_at)
    if (Number.isNaN(completed)) continue
    const day = toLocalDateString(new Date(completed))
    if (!weekDaySet.has(day)) continue
    const group = completedByDay.get(day)
    if (group) group.push(task)
    else completedByDay.set(day, [task])
  }

  // day -> (taskId -> { earliest same-day entry start, tracked ms that day }).
  // Every task with an entry that day lands here, completed-that-day or not.
  const workedByDay = new Map<
    string,
    Map<string, { firstStart: string; trackedMs: number }>
  >()
  for (const activity of activities) {
    for (const entry of activity.entries) {
      const day = entryLocalDay(entry.started_at)
      if (day === null || !weekDaySet.has(day)) continue
      let dayMap = workedByDay.get(day)
      if (!dayMap) {
        dayMap = new Map()
        workedByDay.set(day, dayMap)
      }
      const ms = totalTrackedMs([entry], now)
      const existing = dayMap.get(activity.id)
      if (existing) {
        existing.trackedMs += ms
        if (Date.parse(entry.started_at) < Date.parse(existing.firstStart)) {
          existing.firstStart = entry.started_at
        }
      } else {
        dayMap.set(activity.id, { firstStart: entry.started_at, trackedMs: ms })
      }
    }
  }

  const days = new Set<string>([
    ...completedByDay.keys(),
    ...workedByDay.keys(),
  ])
  return [...days]
    .sort((a, b) => b.localeCompare(a))
    .map((day) => {
      const dayWorked = workedByDay.get(day)
      const completed = [...(completedByDay.get(day) ?? [])].sort(
        compareByCompletionAsc,
      )
      const completedIds = new Set(completed.map((task) => task.id))

      const completedRows = completed.map((task) =>
        toCompletedRow(task, dayWorked?.get(task.id)?.trackedMs ?? 0),
      )

      const workedRows: ActivityDayRow[] = []
      for (const [taskId, info] of dayWorked ?? []) {
        if (completedIds.has(taskId)) continue
        const activity = activityById.get(taskId)
        if (!activity) continue
        workedRows.push({
          id: activity.id,
          title: activity.title,
          category_id: activity.category_id,
          priority: activity.priority,
          kind: activity.status === 'done' ? 'done-later' : 'in-progress',
          timestamp: info.firstStart,
          trackedMs: info.trackedMs,
          completers: [],
          createdAt: activity.created_at,
          completedAt: activity.completed_at,
        })
      }
      workedRows.sort((a, b) => {
        const ta = Date.parse(a.timestamp)
        const tb = Date.parse(b.timestamp)
        if (ta !== tb) return ta - tb
        return a.id.localeCompare(b.id)
      })

      const trackedMs = [...(dayWorked?.values() ?? [])].reduce(
        (sum, info) => sum + info.trackedMs,
        0,
      )

      return {
        day,
        completedCount: completedRows.length,
        trackedMs,
        rows: [...completedRows, ...workedRows],
      }
    })
}

const ACTIVITY_TASK_COLUMNS =
  'id, title, status, category_id, priority, created_at, completed_at'

/**
 * The farm's tasks with time-entry activity in `window` (see
 * `weekQueryWindow`), each with its in-window entries — the second data source
 * (alongside `listCompletedTasks`) behind the Progress page's daily activity
 * view. This is what surfaces tasks that were worked on during the week but not
 * completed in it: an entry counts toward the day it *started* (see
 * `entryLocalDay`), so filtering entries by `started_at` picks up exactly the
 * entries `buildActivityDayGroups` can place in the week, whatever the task's
 * status or completion date.
 *
 * Entries first, then tasks, because `task_time_entries` carries no `farm_id`:
 * the entries query is bounded by the window (RLS already limits it to the
 * caller's farms), and the task lookup by the ids it returns, chunked (see
 * `chunk`) and filtered to `farmId`. Entries on other farms' tasks are
 * dropped. A completed task with no tracked time still renders from
 * `listCompletedTasks`. Ordered by id for a deterministic result.
 */
export async function listTaskActivity(
  supabase: Client,
  farmId: string,
  window: WeekQueryWindow,
): Promise<TaskActivity[]> {
  const { data: entries, error: entriesError } = await supabase
    .from('task_time_entries')
    .select('task_id, started_at, ended_at')
    .gte('started_at', window.from)
    .lt('started_at', window.to)
  if (entriesError) throw new Error(entriesError.message)
  if (entries.length === 0) return []

  const taskIds = [...new Set(entries.map((entry) => entry.task_id))]
  const taskPages = await Promise.all(
    chunk(taskIds).map(async (ids) => {
      const { data, error } = await supabase
        .from('tasks')
        .select(ACTIVITY_TASK_COLUMNS)
        .eq('farm_id', farmId)
        .in('id', ids)
      if (error) throw new Error(error.message)
      return data
    }),
  )
  const taskById = new Map(taskPages.flat().map((task) => [task.id, task]))

  const entriesByTask = new Map<string, ActivityEntry[]>()
  for (const entry of entries) {
    const list = entriesByTask.get(entry.task_id)
    if (list) list.push(entry)
    else entriesByTask.set(entry.task_id, [entry])
  }

  const result: TaskActivity[] = []
  for (const [taskId, taskEntries] of entriesByTask) {
    const task = taskById.get(taskId)
    if (!task) continue
    result.push({
      id: task.id,
      title: task.title,
      status: task.status,
      category_id: task.category_id,
      priority: task.priority,
      created_at: task.created_at,
      completed_at: task.completed_at,
      entries: taskEntries,
    })
  }
  return result.sort((a, b) => a.id.localeCompare(b.id))
}
