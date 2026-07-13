import { describe, expect, it } from 'vitest'
import {
  addWeeks,
  completedTasksInWeek,
  groupByCompletionDay,
  isCompletedInWeek,
  listCompletedTasks,
  trackedMsByTask,
  trackedMsForTasks,
  weekDays,
  weekStartFor,
  type CompletedTaskSummary,
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
    completed_by: ACTOR,
    completed_by_name: null,
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
    completed_by: ACTOR,
    completed_by_name: null,
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
