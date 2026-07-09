import { describe, expect, it } from 'vitest'
import {
  getRunningEntry,
  listTimeEntries,
  startTimer,
  stopTimer,
  totalTrackedMs,
} from '../app/services/time-entries'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type EntryRow = Database['public']['Tables']['task_time_entries']['Row']
type TaskRow = Database['public']['Tables']['tasks']['Row']

const FARM_A = 'farm-a'
const TASK_A = 'task-a'
const TASK_B = 'task-b'
const ACTOR = 'user-1'

function entry(overrides: Partial<EntryRow> = {}): EntryRow {
  return {
    id: 'entry-seed',
    task_id: TASK_A,
    user_id: ACTOR,
    started_at: '2026-01-01T08:00:00.000Z',
    ended_at: '2026-01-01T09:00:00.000Z',
    created_at: '2026-01-01T08:00:00.000Z',
    ...overrides,
  }
}

function task(overrides: Partial<TaskRow> = {}): TaskRow {
  return {
    id: TASK_A,
    farm_id: FARM_A,
    title: 'Fix the gate',
    category_id: null,
    priority: 'soon',
    status: 'not_started',
    due_date: null,
    notes: null,
    lat: null,
    lng: null,
    created_at: '2026-01-01T00:00:00.000Z',
    created_by: ACTOR,
    completed_at: null,
    estimated_minutes: null,
    ...overrides,
  }
}

// startTimer's status flip goes through changeTaskStatus, which also reads
// tags and writes the activity log — seed those tables empty so the fake
// has them.
function seedForStart(overrides: {
  tasks?: TaskRow[]
  task_time_entries?: EntryRow[]
}) {
  return new FakeSupabaseClient({
    tasks: overrides.tasks ?? [task()],
    task_time_entries: overrides.task_time_entries ?? [],
    task_tags: [],
    activity_log: [],
  })
}

describe('listTimeEntries', () => {
  it("returns only the given task's entries, oldest session first", async () => {
    const fake = new FakeSupabaseClient({
      task_time_entries: [
        entry({ id: 'entry-2', started_at: '2026-01-02T08:00:00.000Z' }),
        entry({ id: 'entry-1', started_at: '2026-01-01T08:00:00.000Z' }),
        entry({ id: 'entry-3', task_id: TASK_B }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTimeEntries(supabase, TASK_A)

    expect(result.map((e) => e.id)).toEqual(['entry-1', 'entry-2'])
  })

  it('propagates a select failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_time_entries: [] },
      { table: 'task_time_entries', op: 'select' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listTimeEntries(supabase, TASK_A)).rejects.toThrow()
  })
})

describe('getRunningEntry', () => {
  it("returns the user's running entry regardless of task", async () => {
    const fake = new FakeSupabaseClient({
      task_time_entries: [
        entry({ id: 'entry-1' }),
        entry({ id: 'entry-2', task_id: TASK_B, ended_at: null }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await getRunningEntry(supabase, ACTOR)

    expect(result?.id).toBe('entry-2')
  })

  it("returns null when nothing is running, ignoring other users' running entries", async () => {
    const fake = new FakeSupabaseClient({
      task_time_entries: [
        entry({ id: 'entry-1' }),
        entry({ id: 'entry-2', user_id: 'user-2', ended_at: null }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await getRunningEntry(supabase, ACTOR)

    expect(result).toBeNull()
  })
})

describe('startTimer', () => {
  it('inserts a running entry for the task and user', async () => {
    const fake = seedForStart({})
    const supabase = asSupabaseClient(fake)

    const result = await startTimer(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      actorUserId: ACTOR,
    })

    expect(result.task_id).toBe(TASK_A)
    expect(result.user_id).toBe(ACTOR)
    expect(result.ended_at).toBeNull()
    expect(fake.getTable('task_time_entries')).toHaveLength(1)
  })

  it("auto-stops the user's running entry on another task", async () => {
    const fake = seedForStart({
      task_time_entries: [
        entry({ id: 'entry-1', task_id: TASK_B, ended_at: null }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await startTimer(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      actorUserId: ACTOR,
    })

    const rows = fake.getTable('task_time_entries')
    expect(rows).toHaveLength(2)
    const previous = rows.find((r) => r.id === 'entry-1')
    expect(previous?.ended_at).not.toBeNull()
    const running = rows.filter((r) => r.ended_at === null)
    expect(running).toHaveLength(1)
    expect(running[0]?.task_id).toBe(TASK_A)
  })

  it("leaves another user's running entry alone", async () => {
    const fake = seedForStart({
      task_time_entries: [
        entry({ id: 'entry-1', user_id: 'user-2', ended_at: null }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await startTimer(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      actorUserId: ACTOR,
    })

    const other = fake
      .getTable('task_time_entries')
      .find((r) => r.id === 'entry-1')
    expect(other?.ended_at).toBeNull()
  })

  it('flips a not_started task to in_progress and logs the status change', async () => {
    const fake = seedForStart({ tasks: [task({ status: 'not_started' })] })
    const supabase = asSupabaseClient(fake)

    await startTimer(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      actorUserId: ACTOR,
    })

    expect(fake.getTable('tasks')[0]?.status).toBe('in_progress')
    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({ event_type: 'task_status_changed' })
  })

  it('does not touch the status of an in_progress or done task', async () => {
    for (const status of ['in_progress', 'done'] as const) {
      const fake = seedForStart({ tasks: [task({ status })] })
      const supabase = asSupabaseClient(fake)

      await startTimer(supabase, {
        farmId: FARM_A,
        taskId: TASK_A,
        actorUserId: ACTOR,
      })

      expect(fake.getTable('tasks')[0]?.status).toBe(status)
      expect(fake.getTable('activity_log')).toHaveLength(0)
    }
  })

  it('propagates an insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [task()], task_time_entries: [] },
      { table: 'task_time_entries', op: 'insert' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      startTimer(supabase, {
        farmId: FARM_A,
        taskId: TASK_A,
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow()
  })
})

describe('stopTimer', () => {
  it('sets ended_at on a running entry and returns it', async () => {
    const fake = new FakeSupabaseClient({
      task_time_entries: [entry({ id: 'entry-1', ended_at: null })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await stopTimer(supabase, 'entry-1')

    expect(result.ended_at).not.toBeNull()
    expect(fake.getTable('task_time_entries')[0]?.ended_at).not.toBeNull()
  })

  it('throws on a double-stop instead of rewriting the end time', async () => {
    const originalEnd = '2026-01-01T09:00:00.000Z'
    const fake = new FakeSupabaseClient({
      task_time_entries: [entry({ id: 'entry-1', ended_at: originalEnd })],
    })
    const supabase = asSupabaseClient(fake)

    await expect(stopTimer(supabase, 'entry-1')).rejects.toThrow(
      'Timer is not running',
    )
    expect(fake.getTable('task_time_entries')[0]?.ended_at).toBe(originalEnd)
  })

  it('throws when the entry does not exist', async () => {
    const fake = new FakeSupabaseClient({ task_time_entries: [] })
    const supabase = asSupabaseClient(fake)

    await expect(stopTimer(supabase, 'missing')).rejects.toThrow(
      'Timer is not running',
    )
  })
})

describe('totalTrackedMs', () => {
  it('sums closed entries', () => {
    const entries = [
      entry({
        started_at: '2026-01-01T08:00:00.000Z',
        ended_at: '2026-01-01T09:00:00.000Z',
      }),
      entry({
        started_at: '2026-01-02T08:00:00.000Z',
        ended_at: '2026-01-02T08:30:00.000Z',
      }),
    ]

    expect(totalTrackedMs(entries)).toBe(90 * 60 * 1000)
  })

  it('counts a running entry up to now', () => {
    const now = new Date('2026-01-01T08:10:00.000Z')
    const entries = [
      entry({ started_at: '2026-01-01T08:00:00.000Z', ended_at: null }),
    ]

    expect(totalTrackedMs(entries, now)).toBe(10 * 60 * 1000)
  })

  it('returns 0 for no entries and skips unparseable timestamps', () => {
    expect(totalTrackedMs([])).toBe(0)
    expect(
      totalTrackedMs([entry({ started_at: 'garbage', ended_at: null })]),
    ).toBe(0)
  })
})
