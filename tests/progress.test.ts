import { describe, expect, it } from 'vitest'
import {
  addWeeks,
  buildActivityDayGroups,
  completedTasksInWeek,
  entryLocalDay,
  groupByCompletionDay,
  isCompletedInWeek,
  listCompletedTasks,
  listTaskActivity,
  trackedMsByDay,
  trackedMsByTask,
  trackedMsForTasks,
  weekDays,
  weekStartFor,
  type CompletedTaskSummary,
  type TaskActivity,
} from '../app/services/progress'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type TaskRow = Database['public']['Tables']['tasks']['Row']
type EntryRow = Database['public']['Tables']['task_time_entries']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'
const ACTOR = 'user-1'

function task(overrides: Partial<TaskRow> = {}): TaskRow {
  return {
    id: 'task-seed',
    farm_id: FARM_A,
    title: 'Fix the gate',
    category_id: 'cat-seed',
    priority: 'soon',
    status: 'done',
    due_date: null,
    notes: null,
    lat: null,
    lng: null,
    location_id: null,
    created_at: '2026-01-01T00:00:00.000Z',
    created_by: ACTOR,
    completed_at: '2026-01-05T12:00:00.000Z',
    estimated_minutes: null,
    ...overrides,
  }
}

function entry(overrides: Partial<EntryRow> = {}): EntryRow {
  return {
    id: 'entry-seed',
    task_id: 'task-a',
    user_id: ACTOR,
    started_at: '2026-01-01T08:00:00.000Z',
    ended_at: '2026-01-01T09:00:00.000Z',
    created_at: '2026-01-01T08:00:00.000Z',
    ...overrides,
  }
}

// Build a CompletedTaskSummary for the pure-function tests without going
// through the DB row shape.
function completed(
  overrides: Partial<CompletedTaskSummary> = {},
): CompletedTaskSummary {
  return {
    id: 'task-seed',
    title: 'Fix the gate',
    category_id: 'cat-seed',
    priority: 'soon',
    completed_at: '2026-01-05T12:00:00.000Z',
    completers: [],
    ...overrides,
  }
}

// A TaskActivity (a task with time-entry activity) for the buildActivityDayGroups
// tests, without going through the DB row shape.
function activity(overrides: Partial<TaskActivity> = {}): TaskActivity {
  return {
    id: 'task-a',
    title: 'Muck the barn',
    status: 'in_progress',
    category_id: 'cat-seed',
    priority: 'soon',
    entries: [],
    ...overrides,
  }
}

// Local midnight of y/m(1-based)/d as an ISO instant — mirrors what the DB
// returns for a completed_at, but built from local components so the boundary
// tests are timezone-independent.
function localIso(
  y: number,
  m: number,
  d: number,
  h = 0,
  min = 0,
  s = 0,
): string {
  return new Date(y, m - 1, d, h, min, s).toISOString()
}

describe('weekStartFor', () => {
  it('returns the Monday of a mid-week date', () => {
    // Wednesday, July 8, 2026 -> Monday, July 6, 2026.
    expect(weekStartFor(new Date(2026, 6, 8))).toBe('2026-07-06')
  })

  it('returns the same date when it is already a Monday', () => {
    expect(weekStartFor(new Date(2026, 6, 6))).toBe('2026-07-06')
  })

  it('maps a Sunday back to the previous Monday', () => {
    // Sunday, July 12, 2026 -> Monday, July 6, 2026.
    expect(weekStartFor(new Date(2026, 6, 12))).toBe('2026-07-06')
  })

  it('crosses a year boundary (Thursday Jan 1, 2026 -> Monday Dec 29, 2025)', () => {
    expect(weekStartFor(new Date(2026, 0, 1))).toBe('2025-12-29')
  })
})

describe('addWeeks', () => {
  it('moves forward across a month boundary', () => {
    expect(addWeeks('2026-07-27', 1)).toBe('2026-08-03')
  })

  it('moves backward', () => {
    expect(addWeeks('2026-07-06', -2)).toBe('2026-06-22')
  })

  it('moves forward across a year boundary', () => {
    expect(addWeeks('2025-12-29', 1)).toBe('2026-01-05')
  })

  it('is a no-op for zero weeks', () => {
    expect(addWeeks('2026-07-06', 0)).toBe('2026-07-06')
  })
})

describe('weekDays', () => {
  it('returns 7 consecutive local days Monday..Sunday', () => {
    expect(weekDays('2026-07-06')).toEqual([
      '2026-07-06',
      '2026-07-07',
      '2026-07-08',
      '2026-07-09',
      '2026-07-10',
      '2026-07-11',
      '2026-07-12',
    ])
  })
})

describe('isCompletedInWeek', () => {
  const weekStart = '2026-07-06'

  it('is true for a completion inside the week', () => {
    expect(
      isCompletedInWeek(
        { completed_at: localIso(2026, 7, 8, 14, 30) },
        weekStart,
      ),
    ).toBe(true)
  })

  it('is true exactly at the local midnight that starts the week', () => {
    expect(
      isCompletedInWeek({ completed_at: localIso(2026, 7, 6) }, weekStart),
    ).toBe(true)
  })

  it('is false exactly at the next Monday local midnight (half-open upper bound)', () => {
    expect(
      isCompletedInWeek({ completed_at: localIso(2026, 7, 13) }, weekStart),
    ).toBe(false)
  })

  it('is false just before the starting Monday midnight', () => {
    expect(
      isCompletedInWeek(
        { completed_at: localIso(2026, 7, 5, 23, 59, 59) },
        weekStart,
      ),
    ).toBe(false)
  })

  it('is false for a null completed_at', () => {
    expect(isCompletedInWeek({ completed_at: null }, weekStart)).toBe(false)
  })

  it('is false for an unparseable completed_at', () => {
    expect(isCompletedInWeek({ completed_at: 'not-a-date' }, weekStart)).toBe(
      false,
    )
  })
})

describe('completedTasksInWeek', () => {
  it('keeps only tasks completed within the week', () => {
    const tasks = [
      completed({ id: 'in', completed_at: localIso(2026, 7, 8) }),
      completed({ id: 'before', completed_at: localIso(2026, 7, 5) }),
      completed({ id: 'after', completed_at: localIso(2026, 7, 13) }),
    ]

    expect(completedTasksInWeek(tasks, '2026-07-06').map((t) => t.id)).toEqual([
      'in',
    ])
  })
})

describe('groupByCompletionDay', () => {
  it('groups by local day, newest day first, ascending within a day, id tiebreak', () => {
    const tasks = [
      completed({ id: 'mon-late', completed_at: localIso(2026, 7, 6, 18) }),
      completed({ id: 'wed', completed_at: localIso(2026, 7, 8, 9) }),
      completed({ id: 'mon-early', completed_at: localIso(2026, 7, 6, 8) }),
      // Same instant as mon-early -> id breaks the tie (mon-early < mon-tie).
      completed({ id: 'mon-tie', completed_at: localIso(2026, 7, 6, 8) }),
    ]

    const groups = groupByCompletionDay(tasks)

    expect(groups.map((g) => g.day)).toEqual(['2026-07-08', '2026-07-06'])
    expect(groups[0]?.tasks.map((t) => t.id)).toEqual(['wed'])
    expect(groups[1]?.tasks.map((t) => t.id)).toEqual([
      'mon-early',
      'mon-tie',
      'mon-late',
    ])
  })

  it('places a late-evening and an early-next-morning completion in different local-day groups', () => {
    const tasks = [
      completed({ id: 'evening', completed_at: localIso(2026, 7, 6, 23, 30) }),
      completed({ id: 'morning', completed_at: localIso(2026, 7, 7, 0, 30) }),
    ]

    const groups = groupByCompletionDay(tasks)

    expect(groups.map((g) => g.day)).toEqual(['2026-07-07', '2026-07-06'])
    expect(groups[0]?.tasks.map((t) => t.id)).toEqual(['morning'])
    expect(groups[1]?.tasks.map((t) => t.id)).toEqual(['evening'])
  })
})

describe('listCompletedTasks', () => {
  it("returns only the farm's done tasks, dropping null completed_at, newest first", async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({
          id: 'done-older',
          completed_at: '2026-07-06T10:00:00.000Z',
        }),
        task({
          id: 'done-newer',
          completed_at: '2026-07-08T10:00:00.000Z',
        }),
        // Done but somehow missing a completion timestamp -> dropped.
        task({ id: 'done-null', completed_at: null }),
        // Not done -> excluded by the status filter.
        task({ id: 'open', status: 'not_started', completed_at: null }),
        // Different farm -> excluded by the farm filter.
        task({
          id: 'other-farm',
          farm_id: FARM_B,
          completed_at: '2026-07-09T10:00:00.000Z',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listCompletedTasks(supabase, FARM_A)

    expect(result.map((t) => t.id)).toEqual(['done-newer', 'done-older'])
  })

  it('attaches each task’s completer set (members and free-text names)', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({ id: 'done-1', completed_at: '2026-07-08T10:00:00.000Z' }),
        task({ id: 'done-2', completed_at: '2026-07-06T10:00:00.000Z' }),
      ],
      task_completers: [
        { id: 'c1', task_id: 'done-1', user_id: ACTOR, completer_name: null },
        { id: 'c2', task_id: 'done-1', user_id: null, completer_name: 'Kaleb' },
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listCompletedTasks(supabase, FARM_A)

    const one = result.find((t) => t.id === 'done-1')!
    // Members sort before free-text names.
    expect(one.completers).toEqual([
      { user_id: ACTOR, completer_name: null },
      { user_id: null, completer_name: 'Kaleb' },
    ])
    const two = result.find((t) => t.id === 'done-2')!
    expect(two.completers).toEqual([])
  })

  it('propagates a select failure', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [] },
      { table: 'tasks', op: 'select', message: 'select boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listCompletedTasks(supabase, FARM_A)).rejects.toThrow(
      'select boom',
    )
  })
})

describe('trackedMsForTasks', () => {
  it('sums entries across the given tasks, ignoring entries of other tasks', async () => {
    const fake = new FakeSupabaseClient({
      task_time_entries: [
        entry({
          id: 'e1',
          task_id: 'task-a',
          started_at: '2026-01-01T08:00:00.000Z',
          ended_at: '2026-01-01T09:00:00.000Z',
        }),
        entry({
          id: 'e2',
          task_id: 'task-b',
          started_at: '2026-01-01T08:00:00.000Z',
          ended_at: '2026-01-01T08:30:00.000Z',
        }),
        entry({
          id: 'e3',
          task_id: 'task-other',
          started_at: '2026-01-01T08:00:00.000Z',
          ended_at: '2026-01-01T10:00:00.000Z',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await trackedMsForTasks(supabase, ['task-a', 'task-b'])

    expect(result).toBe(90 * 60 * 1000)
  })

  it('counts a running entry up to now', async () => {
    const now = new Date('2026-01-01T08:10:00.000Z')
    const fake = new FakeSupabaseClient({
      task_time_entries: [
        entry({
          id: 'e1',
          task_id: 'task-a',
          started_at: '2026-01-01T08:00:00.000Z',
          ended_at: null,
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await trackedMsForTasks(supabase, ['task-a'], now)

    expect(result).toBe(10 * 60 * 1000)
  })

  it('returns 0 for an empty task list without touching the client', async () => {
    // A client whose every select fails — proving no query is issued.
    const fake = new FakeSupabaseClient(
      { task_time_entries: [entry()] },
      { table: 'task_time_entries', op: 'select', message: 'should not run' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(trackedMsForTasks(supabase, [])).resolves.toBe(0)
  })
})

describe('trackedMsByTask', () => {
  it('sums entries per task, keying only tasks with entries', async () => {
    const fake = new FakeSupabaseClient({
      task_time_entries: [
        entry({
          id: 'e1',
          task_id: 'task-a',
          started_at: '2026-01-01T08:00:00.000Z',
          ended_at: '2026-01-01T09:00:00.000Z',
        }),
        entry({
          id: 'e2',
          task_id: 'task-a',
          started_at: '2026-01-01T10:00:00.000Z',
          ended_at: '2026-01-01T10:15:00.000Z',
        }),
        entry({
          id: 'e3',
          task_id: 'task-b',
          started_at: '2026-01-01T08:00:00.000Z',
          ended_at: '2026-01-01T08:30:00.000Z',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await trackedMsByTask(supabase, [
      'task-a',
      'task-b',
      'task-c',
    ])

    expect(result.get('task-a')).toBe(75 * 60 * 1000)
    expect(result.get('task-b')).toBe(30 * 60 * 1000)
    expect(result.has('task-c')).toBe(false)
  })

  it('returns an empty map for an empty task list without touching the client', async () => {
    const fake = new FakeSupabaseClient(
      { task_time_entries: [entry()] },
      { table: 'task_time_entries', op: 'select', message: 'should not run' },
    )
    const supabase = asSupabaseClient(fake)

    const result = await trackedMsByTask(supabase, [])
    expect(result.size).toBe(0)
  })
})

describe('entryLocalDay', () => {
  it('returns the local day of started_at', () => {
    expect(entryLocalDay(localIso(2026, 7, 8, 14, 30))).toBe('2026-07-08')
  })

  it('attributes a late-evening start to that day, not the next', () => {
    expect(entryLocalDay(localIso(2026, 7, 6, 23, 30))).toBe('2026-07-06')
    expect(entryLocalDay(localIso(2026, 7, 7, 0, 30))).toBe('2026-07-07')
  })

  it('returns null for an unparseable timestamp', () => {
    expect(entryLocalDay('not-a-date')).toBeNull()
  })
})

describe('trackedMsByDay', () => {
  it('sums durations by the local day each entry started', () => {
    const byDay = trackedMsByDay([
      // Two entries on 07-06 (30m + 15m), one on 07-08 (60m).
      {
        started_at: localIso(2026, 7, 6, 8),
        ended_at: localIso(2026, 7, 6, 8, 30),
      },
      {
        started_at: localIso(2026, 7, 6, 10),
        ended_at: localIso(2026, 7, 6, 10, 15),
      },
      {
        started_at: localIso(2026, 7, 8, 9),
        ended_at: localIso(2026, 7, 8, 10),
      },
    ])

    expect(byDay.get('2026-07-06')).toBe(45 * 60 * 1000)
    expect(byDay.get('2026-07-08')).toBe(60 * 60 * 1000)
  })

  it('attributes an entry that runs past midnight entirely to its start day', () => {
    const byDay = trackedMsByDay([
      // 11:30pm -> 1:00am (90m) counts wholly on the day it started.
      {
        started_at: localIso(2026, 7, 6, 23, 30),
        ended_at: localIso(2026, 7, 7, 1, 0),
      },
    ])

    expect(byDay.get('2026-07-06')).toBe(90 * 60 * 1000)
    expect(byDay.has('2026-07-07')).toBe(false)
  })

  it('counts a running entry up to now on its start day', () => {
    const now = new Date(2026, 6, 8, 8, 10)
    const byDay = trackedMsByDay(
      [{ started_at: localIso(2026, 7, 8, 8), ended_at: null }],
      now,
    )

    expect(byDay.get('2026-07-08')).toBe(10 * 60 * 1000)
  })

  it('drops entries with an unparseable start', () => {
    const byDay = trackedMsByDay([{ started_at: 'nope', ended_at: null }])
    expect(byDay.size).toBe(0)
  })
})

describe('buildActivityDayGroups', () => {
  const weekStart = '2026-07-06'

  it('renders a completed task as a completed row with its same-day tracked time and completer set', () => {
    const completedTask = completed({
      id: 'clean',
      completed_at: localIso(2026, 7, 8, 14),
      completers: [
        { user_id: ACTOR, completer_name: null },
        { user_id: null, completer_name: 'Kaleb' },
      ],
    })
    const act = activity({
      id: 'clean',
      status: 'done',
      entries: [
        {
          started_at: localIso(2026, 7, 8, 9),
          ended_at: localIso(2026, 7, 8, 10),
        },
      ],
    })

    const groups = buildActivityDayGroups(weekStart, [completedTask], [act])

    expect(groups).toHaveLength(1)
    const group = groups[0]!
    expect(group.day).toBe('2026-07-08')
    expect(group.completedCount).toBe(1)
    expect(group.trackedMs).toBe(60 * 60 * 1000)
    expect(group.rows).toHaveLength(1)
    expect(group.rows[0]!.completers).toEqual([
      { user_id: ACTOR, completer_name: null },
      { user_id: null, completer_name: 'Kaleb' },
    ])
    expect(group.rows[0]).toMatchObject({
      id: 'clean',
      kind: 'completed',
      trackedMs: 60 * 60 * 1000,
    })
  })

  it('surfaces a worked-on task that is not done as an in-progress row', () => {
    const act = activity({
      id: 'muck',
      status: 'in_progress',
      entries: [
        {
          started_at: localIso(2026, 7, 7, 8),
          ended_at: localIso(2026, 7, 7, 9),
        },
      ],
    })

    const groups = buildActivityDayGroups(weekStart, [], [act])

    expect(groups).toHaveLength(1)
    const group = groups[0]!
    expect(group.day).toBe('2026-07-07')
    expect(group.completedCount).toBe(0)
    expect(group.trackedMs).toBe(60 * 60 * 1000)
    expect(group.rows[0]).toMatchObject({
      id: 'muck',
      kind: 'in-progress',
      trackedMs: 60 * 60 * 1000,
      completers: [],
    })
  })

  it('shows a task worked one day but finished a later day under both, as done-later then completed', () => {
    // Worked Tuesday 07-07, completed Thursday 07-09.
    const completedTask = completed({
      id: 'fix',
      completed_at: localIso(2026, 7, 9, 16),
    })
    const act = activity({
      id: 'fix',
      status: 'done',
      entries: [
        {
          started_at: localIso(2026, 7, 7, 8),
          ended_at: localIso(2026, 7, 7, 9),
        },
      ],
    })

    const groups = buildActivityDayGroups(weekStart, [completedTask], [act])

    // Newest day first.
    expect(groups.map((g) => g.day)).toEqual(['2026-07-09', '2026-07-07'])

    const thursday = groups[0]!
    expect(thursday.completedCount).toBe(1)
    expect(thursday.trackedMs).toBe(0) // no entries on Thursday
    expect(thursday.rows[0]).toMatchObject({ id: 'fix', kind: 'completed' })

    const tuesday = groups[1]!
    expect(tuesday.completedCount).toBe(0)
    expect(tuesday.trackedMs).toBe(60 * 60 * 1000)
    expect(tuesday.rows[0]).toMatchObject({ id: 'fix', kind: 'done-later' })
  })

  it('de-dups a task worked and completed the same day to the completed row, still counting the day time', () => {
    const completedTask = completed({
      id: 'both',
      completed_at: localIso(2026, 7, 8, 15),
    })
    const act = activity({
      id: 'both',
      status: 'done',
      entries: [
        // 30m on the completion day + 30m the day before.
        {
          started_at: localIso(2026, 7, 8, 9),
          ended_at: localIso(2026, 7, 8, 9, 30),
        },
        {
          started_at: localIso(2026, 7, 7, 9),
          ended_at: localIso(2026, 7, 7, 9, 30),
        },
      ],
    })

    const groups = buildActivityDayGroups(weekStart, [completedTask], [act])
    expect(groups.map((g) => g.day)).toEqual(['2026-07-08', '2026-07-07'])

    const completionDay = groups[0]!
    // Only the completed row (no duplicate worked row), but the day's tracked
    // total still includes that day's 30m of work.
    expect(completionDay.rows).toHaveLength(1)
    expect(completionDay.rows[0]).toMatchObject({
      id: 'both',
      kind: 'completed',
      trackedMs: 30 * 60 * 1000,
    })
    expect(completionDay.trackedMs).toBe(30 * 60 * 1000)

    const priorDay = groups[1]!
    expect(priorDay.rows[0]).toMatchObject({ id: 'both', kind: 'done-later' })
    expect(priorDay.trackedMs).toBe(30 * 60 * 1000)
  })

  it('counts a running timer today as in-progress up to now', () => {
    const now = new Date(2026, 6, 8, 8, 10)
    const act = activity({
      id: 'live',
      status: 'in_progress',
      entries: [{ started_at: localIso(2026, 7, 8, 8), ended_at: null }],
    })

    const groups = buildActivityDayGroups(weekStart, [], [act], now)

    expect(groups[0]!.trackedMs).toBe(10 * 60 * 1000)
    expect(groups[0]!.rows[0]).toMatchObject({
      id: 'live',
      kind: 'in-progress',
      trackedMs: 10 * 60 * 1000,
    })
  })

  it('orders completed rows before worked rows within a day', () => {
    const completedTask = completed({
      id: 'done-a',
      completed_at: localIso(2026, 7, 8, 16),
    })
    const worked = activity({
      id: 'worked-b',
      status: 'in_progress',
      entries: [
        {
          started_at: localIso(2026, 7, 8, 8),
          ended_at: localIso(2026, 7, 8, 9),
        },
      ],
    })

    const groups = buildActivityDayGroups(weekStart, [completedTask], [worked])

    expect(groups[0]!.rows.map((r) => [r.id, r.kind])).toEqual([
      ['done-a', 'completed'],
      ['worked-b', 'in-progress'],
    ])
  })

  it('excludes entries whose start falls outside the week', () => {
    const act = activity({
      id: 'earlier',
      status: 'in_progress',
      entries: [
        // Sunday before the Monday week start -> not in this week.
        {
          started_at: localIso(2026, 7, 5, 10),
          ended_at: localIso(2026, 7, 5, 11),
        },
      ],
    })

    expect(buildActivityDayGroups(weekStart, [], [act])).toEqual([])
  })
})

describe('listTaskActivity', () => {
  it("returns the farm's tasks that have entries, with identity and entries, dropping entry-less tasks", async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({ id: 'has-entries', status: 'in_progress' }),
        task({ id: 'done-with-entries', status: 'done' }),
        task({ id: 'no-entries', status: 'not_started' }),
        task({ id: 'other-farm', farm_id: FARM_B, status: 'in_progress' }),
      ],
      task_time_entries: [
        entry({ id: 'e1', task_id: 'has-entries' }),
        entry({ id: 'e2', task_id: 'has-entries' }),
        entry({ id: 'e3', task_id: 'done-with-entries' }),
        // Belongs to a task in another farm -> excluded (not in FARM_A's ids).
        entry({ id: 'e4', task_id: 'other-farm' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTaskActivity(supabase, FARM_A)

    expect(result.map((a) => a.id)).toEqual([
      'done-with-entries',
      'has-entries',
    ])
    const withEntries = result.find((a) => a.id === 'has-entries')!
    expect(withEntries.entries).toHaveLength(2)
    expect(withEntries.status).toBe('in_progress')
    expect(withEntries.title).toBe('Fix the gate')
  })

  it('returns an empty array (without querying entries) when the farm has no tasks', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [] },
      { table: 'task_time_entries', op: 'select', message: 'should not run' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listTaskActivity(supabase, FARM_A)).resolves.toEqual([])
  })

  it('propagates a tasks select failure', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [task()] },
      { table: 'tasks', op: 'select', message: 'tasks boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listTaskActivity(supabase, FARM_A)).rejects.toThrow(
      'tasks boom',
    )
  })

  it('propagates a time-entries select failure', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [task({ id: 'has-entries' })], task_time_entries: [] },
      { table: 'task_time_entries', op: 'select', message: 'entries boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listTaskActivity(supabase, FARM_A)).rejects.toThrow(
      'entries boom',
    )
  })
})
