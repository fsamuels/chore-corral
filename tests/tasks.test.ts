import { describe, expect, it } from 'vitest'
import {
  assertValidCompletedAt,
  assertValidEstimatedMinutes,
  changeTaskStatus,
  compareTasksDoneLast,
  createTask,
  deleteTask,
  getTask,
  getTaskTitle,
  isTaskOverdue,
  listTasks,
  updateTask,
} from '../app/services/tasks'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type TaskRow = Database['public']['Tables']['tasks']['Row']
type TagRow = Database['public']['Tables']['tags']['Row']
type TaskTagRow = Database['public']['Tables']['task_tags']['Row']
type TaskCompleterRow = Database['public']['Tables']['task_completers']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'
const ACTOR = 'user-1'

function tag(overrides: Partial<TagRow> = {}): TagRow {
  return {
    id: 'tag-seed',
    farm_id: FARM_A,
    name: 'Fence',
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

function taskTag(overrides: Partial<TaskTagRow> = {}): TaskTagRow {
  return {
    task_id: 'task-seed',
    tag_id: 'tag-seed',
    ...overrides,
  }
}

function task(overrides: Partial<TaskRow> = {}): TaskRow {
  return {
    id: 'task-seed',
    farm_id: FARM_A,
    title: 'Fix the gate',
    category_id: 'cat-seed',
    priority: 'soon',
    status: 'not_started',
    due_date: null,
    notes: null,
    lat: null,
    lng: null,
    location_id: null,
    created_at: '2026-01-01T00:00:00.000Z',
    created_by: ACTOR,
    completed_at: null,
    estimated_minutes: null,
    ...overrides,
  }
}

function completer(
  overrides: Partial<TaskCompleterRow> = {},
): TaskCompleterRow {
  return {
    id: 'completer-seed',
    task_id: 'task-1',
    user_id: ACTOR,
    completer_name: null,
    ...overrides,
  }
}

describe('createTask', () => {
  it('inserts a row and returns a TaskSummary, logging a task_created event', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    const result = await createTask(supabase, {
      farmId: FARM_A,
      title: '  Fix the gate  ',
      categoryId: 'cat-1',
      priority: 'urgent',
      actorUserId: ACTOR,
    })

    expect(result.title).toBe('Fix the gate')
    expect(result.status).toBe('not_started')
    expect(result.completed_at).toBeNull()
    expect(result.id).toBeTruthy()

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      farm_id: FARM_A,
      task_id: result.id,
      event_type: 'task_created',
      event_detail: { task_title: 'Fix the gate' },
      actor_user_id: ACTOR,
    })
  })

  it('trims notes and turns empty-string notes into null', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    const withNotes = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      notes: '  needs a new hinge  ',
      actorUserId: ACTOR,
    })
    expect(withNotes.notes).toBe('needs a new hinge')

    const emptyNotes = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Mow the field',
      categoryId: null,
      priority: 'soon',
      notes: '   ',
      actorUserId: ACTOR,
    })
    expect(emptyNotes.notes).toBeNull()
  })

  it('throws on an empty or whitespace-only title, writing no task or log row', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: '   ',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('Chore title is required')

    expect(fake.getTable('tasks')).toHaveLength(0)
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('propagates an injected insert failure on tasks', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [], activity_log: [] },
      { table: 'tasks', op: 'insert', message: 'insert boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('insert boom')
  })

  it('throws when the activity_log insert fails, but the task row still exists', async () => {
    const fake = new FakeSupabaseClient(
      { tasks: [], activity_log: [] },
      { table: 'activity_log', op: 'insert', message: 'log boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('log boom')

    expect(fake.getTable('tasks')).toHaveLength(1)
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('creates/attaches tags from tagNames and returns them sorted by name', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [],
      activity_log: [],
      tags: [tag({ id: 'tag-1', name: 'Gate' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      actorUserId: ACTOR,
      tagNames: ['Barn', 'Gate'],
    })

    expect(result.tags.map((t) => t.name)).toEqual(['barn', 'Gate'])
    // "Gate" reused the existing tag rather than creating a duplicate.
    expect(fake.getTable('tags')).toHaveLength(2)

    const taskTagRows = fake
      .getTable('task_tags')
      .filter((r) => (r as { task_id: string }).task_id === result.id)
    expect(taskTagRows).toHaveLength(2)
  })

  it('returns tags: [] when tagNames is omitted', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    const result = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      actorUserId: ACTOR,
    })

    expect(result.tags).toEqual([])
  })

  it('persists lat/lng when provided, and defaults both to null when omitted', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    const withLocation = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      actorUserId: ACTOR,
      lat: 40.7128,
      lng: -74.006,
    })
    expect(withLocation.lat).toBe(40.7128)
    expect(withLocation.lng).toBe(-74.006)

    const withoutLocation = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Mow the field',
      categoryId: null,
      priority: 'soon',
      actorUserId: ACTOR,
    })
    expect(withoutLocation.lat).toBeNull()
    expect(withoutLocation.lng).toBeNull()
  })

  it('persists estimatedMinutes when provided, and defaults to null when omitted', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    const withEstimate = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      actorUserId: ACTOR,
      estimatedMinutes: 90,
    })
    expect(withEstimate.estimated_minutes).toBe(90)

    const withoutEstimate = await createTask(supabase, {
      farmId: FARM_A,
      title: 'Mow the field',
      categoryId: null,
      priority: 'soon',
      actorUserId: ACTOR,
    })
    expect(withoutEstimate.estimated_minutes).toBeNull()
  })

  it('rejects zero, negative, and fractional estimates, writing no task row', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    for (const estimatedMinutes of [0, -30, 1.5]) {
      await expect(
        createTask(supabase, {
          farmId: FARM_A,
          title: 'Fix the gate',
          categoryId: null,
          priority: 'soon',
          actorUserId: ACTOR,
          estimatedMinutes,
        }),
      ).rejects.toThrow(
        'Estimated time must be a positive whole number of minutes',
      )
    }

    expect(fake.getTable('tasks')).toHaveLength(0)
  })

  it('rejects a half-set pin (lat without lng, or lng without lat)', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat: 40.7128,
        lng: null,
      }),
    ).rejects.toThrow('Location requires both lat and lng, or neither')

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat: null,
        lng: -74.006,
      }),
    ).rejects.toThrow('Location requires both lat and lng, or neither')

    expect(fake.getTable('tasks')).toHaveLength(0)
  })

  it('rejects out-of-range lat/lng and accepts boundary values, including (0, 0)', async () => {
    const fake = new FakeSupabaseClient({ tasks: [], activity_log: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat: 90.1,
        lng: 0,
      }),
    ).rejects.toThrow('Location lat must be a number between -90 and 90')

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat: -90.1,
        lng: 0,
      }),
    ).rejects.toThrow('Location lat must be a number between -90 and 90')

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat: 0,
        lng: 180.1,
      }),
    ).rejects.toThrow('Location lng must be a number between -180 and 180')

    await expect(
      createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat: 0,
        lng: -180.1,
      }),
    ).rejects.toThrow('Location lng must be a number between -180 and 180')

    // Boundary values are all valid, and (0, 0) is not mistaken for "unset"
    // even though 0 is falsy.
    for (const [lat, lng] of [
      [90, 0],
      [-90, 0],
      [0, 180],
      [0, -180],
      [0, 0],
    ] as const) {
      const result = await createTask(supabase, {
        farmId: FARM_A,
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        actorUserId: ACTOR,
        lat,
        lng,
      })
      expect(result.lat).toBe(lat)
      expect(result.lng).toBe(lng)
    }
  })
})

describe('changeTaskStatus', () => {
  it('moves not_started to done, sets completed_at, and auto-credits the actor as the sole completer', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({
          id: 'task-1',
          status: 'not_started',
          lat: 40.7128,
          lng: -74.006,
        }),
      ],
      task_completers: [],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'done',
      actorUserId: ACTOR,
    })

    expect(result.status).toBe('done')
    expect(result.completed_at).toEqual(expect.any(String))
    expect(result.completed_at).not.toBeNull()
    // Completion credits the acting member as the only completer.
    expect(result.completers).toEqual([
      { user_id: ACTOR, completer_name: null },
    ])
    const rows = fake
      .getTable('task_completers')
      .filter((r) => (r as TaskCompleterRow).task_id === 'task-1')
    expect(rows).toHaveLength(1)
    // Status transitions don't touch location — lat/lng pass through unchanged.
    expect(result.lat).toBe(40.7128)
    expect(result.lng).toBe(-74.006)

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      farm_id: FARM_A,
      task_id: 'task-1',
      event_type: 'task_status_changed',
      event_detail: {
        task_title: 'Fix the gate',
        old_status: 'not_started',
        new_status: 'done',
      },
      actor_user_id: ACTOR,
    })
  })

  it('does not add the actor when the task already has completers (auto-credit only when empty)', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'in_progress' })],
      task_completers: [
        completer({
          id: 'c1',
          task_id: 'task-1',
          completer_name: 'Kaleb',
          user_id: null,
        }),
        completer({
          id: 'c2',
          task_id: 'task-1',
          completer_name: 'Gerald',
          user_id: null,
        }),
      ],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'done',
      actorUserId: ACTOR,
    })

    // The hand-set completers win; the actor is not bolted on.
    expect(result.completers.map((c) => c.completer_name).sort()).toEqual([
      'Gerald',
      'Kaleb',
    ])
    expect(result.completers.some((c) => c.user_id === ACTOR)).toBe(false)
  })

  it('reopening (done to in_progress) clears completed_at and deletes all completers', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({
          id: 'task-1',
          status: 'done',
          completed_at: '2026-01-02T00:00:00.000Z',
        }),
      ],
      task_completers: [
        completer({ id: 'c1', task_id: 'task-1', user_id: ACTOR }),
        completer({
          id: 'c2',
          task_id: 'task-1',
          user_id: null,
          completer_name: 'Kaleb',
        }),
      ],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'in_progress',
      actorUserId: ACTOR,
    })

    expect(result.status).toBe('in_progress')
    expect(result.completed_at).toBeNull()
    // Leaving done clears the whole completer set.
    expect(result.completers).toEqual([])
    expect(
      fake
        .getTable('task_completers')
        .filter((r) => (r as TaskCompleterRow).task_id === 'task-1'),
    ).toHaveLength(0)

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_type: 'task_status_changed',
      event_detail: {
        task_title: 'Fix the gate',
        old_status: 'done',
        new_status: 'in_progress',
      },
    })
  })

  it('not_started to in_progress leaves completed_at null and logs the transition', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'not_started' })],
      task_completers: [],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'in_progress',
      actorUserId: ACTOR,
    })

    expect(result.status).toBe('in_progress')
    expect(result.completed_at).toBeNull()

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_detail: {
        old_status: 'not_started',
        new_status: 'in_progress',
      },
    })
  })

  it('is a no-op when the requested status matches the current status', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'in_progress' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'in_progress',
      actorUserId: ACTOR,
    })

    expect(result.status).toBe('in_progress')
    expect((fake.getTable('tasks')[0] as TaskRow).status).toBe('in_progress')
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('throws Chore not found when the chore belongs to a different farm, writing no log entry', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', farm_id: FARM_B, status: 'not_started' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      changeTaskStatus(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        status: 'done',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('Chore not found')

    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('records an optional note in the status-changed event_detail when provided', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'in_progress' })],
      task_completers: [],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'done',
      actorUserId: ACTOR,
      note: '  went smoothly  ',
    })

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_type: 'task_status_changed',
      event_detail: {
        old_status: 'in_progress',
        new_status: 'done',
        note: 'went smoothly',
      },
    })
  })

  it('omits the note key when the note is blank/whitespace/absent', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({ id: 'task-1', status: 'in_progress' }),
        task({ id: 'task-2', status: 'in_progress' }),
      ],
      task_completers: [],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'done',
      actorUserId: ACTOR,
      note: '   ',
    })
    await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-2',
      status: 'done',
      actorUserId: ACTOR,
    })

    const log = fake.getTable('activity_log') as {
      event_detail: Record<string, unknown>
    }[]
    expect(log).toHaveLength(2)
    expect('note' in log[0].event_detail).toBe(false)
    expect('note' in log[1].event_detail).toBe(false)
  })

  it('records a note on a non-done transition too (generic data-layer support)', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'not_started' })],
      task_completers: [],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await changeTaskStatus(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      status: 'in_progress',
      actorUserId: ACTOR,
      note: 'starting now',
    })

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_type: 'task_status_changed',
      event_detail: {
        old_status: 'not_started',
        new_status: 'in_progress',
        note: 'starting now',
      },
    })
  })
})

describe('updateTask', () => {
  it('updates title, category, priority, due date, and notes', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: '  New title  ',
      categoryId: 'cat-2',
      priority: 'urgent',
      dueDate: '2026-02-01',
      notes: '  updated notes  ',
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })

    expect(result).toMatchObject({
      title: 'New title',
      category_id: 'cat-2',
      priority: 'urgent',
      due_date: '2026-02-01',
      notes: 'updated notes',
    })
  })

  it('writes no activity_log entries when priority and due date are unchanged', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', priority: 'soon', due_date: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'New title',
      categoryId: null,
      priority: 'soon',
      dueDate: null,
      notes: 'new notes',
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: ['Fence'],
    })

    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('logs a task_priority_changed event when priority changes', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', priority: 'soon' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: 'cat-seed',
      priority: 'urgent',
      dueDate: null,
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_type: 'task_priority_changed',
      event_detail: {
        task_title: 'Fix the gate',
        old_priority: 'soon',
        new_priority: 'urgent',
      },
      actor_user_id: ACTOR,
    })
  })

  it('logs a task_due_date_changed event when a due date is set from null', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', due_date: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: 'cat-seed',
      priority: 'soon',
      dueDate: '2026-03-01',
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_type: 'task_due_date_changed',
      event_detail: {
        task_title: 'Fix the gate',
        old_due_date: null,
        new_due_date: '2026-03-01',
      },
      actor_user_id: ACTOR,
    })
  })

  it('logs a task_due_date_changed event when a due date is cleared to null', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', due_date: '2026-03-01' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: 'cat-seed',
      priority: 'soon',
      dueDate: null,
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      event_type: 'task_due_date_changed',
      event_detail: {
        task_title: 'Fix the gate',
        old_due_date: '2026-03-01',
        new_due_date: null,
      },
    })
  })

  it('logs two events when both priority and due date change', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', priority: 'soon', due_date: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: 'cat-seed',
      priority: 'urgent',
      dueDate: '2026-03-01',
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(2)
    expect(log.map((r) => (r as { event_type: string }).event_type)).toEqual([
      'task_priority_changed',
      'task_due_date_changed',
    ])
  })

  it('throws on an empty title', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateTask(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        title: '   ',
        categoryId: null,
        priority: 'soon',
        dueDate: null,
        notes: null,
        lat: null,
        lng: null,
        estimatedMinutes: null,
        completedAt: null,
        actorUserId: ACTOR,
        tagNames: [],
      }),
    ).rejects.toThrow('Chore title is required')
  })

  it('throws Chore not found for a wrong-farm task id', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', farm_id: FARM_B })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateTask(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        title: 'New title',
        categoryId: null,
        priority: 'soon',
        dueDate: null,
        notes: null,
        lat: null,
        lng: null,
        estimatedMinutes: null,
        completedAt: null,
        actorUserId: ACTOR,
        tagNames: [],
      }),
    ).rejects.toThrow('Chore not found')
  })

  it("replaces a task's tags, adding, removing, and changing the set", async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1' })],
      activity_log: [],
      tags: [
        tag({ id: 'tag-1', name: 'Fence' }),
        tag({ id: 'tag-2', name: 'Gate' }),
      ],
      task_tags: [taskTag({ task_id: 'task-1', tag_id: 'tag-1' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      dueDate: null,
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: ['Gate', 'Barn'],
    })

    expect(result.tags.map((t) => t.name)).toEqual(['barn', 'Gate'])

    const taskTagRows = fake
      .getTable('task_tags')
      .filter((r) => (r as { task_id: string }).task_id === 'task-1')
    expect(taskTagRows).toHaveLength(2)
  })

  it('sets a location on a task that had none, moves it, and clears it', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', lat: null, lng: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const withLocation = await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      dueDate: null,
      notes: null,
      lat: 40.7128,
      lng: -74.006,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })
    expect(withLocation.lat).toBe(40.7128)
    expect(withLocation.lng).toBe(-74.006)

    const moved = await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      dueDate: null,
      notes: null,
      lat: 51.5074,
      lng: -0.1278,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })
    expect(moved.lat).toBe(51.5074)
    expect(moved.lng).toBe(-0.1278)

    const cleared = await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      dueDate: null,
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: null,
      actorUserId: ACTOR,
      tagNames: [],
    })
    expect(cleared.lat).toBeNull()
    expect(cleared.lng).toBeNull()
  })

  it('sets, changes, and clears the estimated time, logging nothing', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', estimated_minutes: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const base = {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: 'cat-seed' as string | null,
      priority: 'soon' as const,
      dueDate: null,
      notes: null,
      lat: null,
      lng: null,
      completedAt: null as string | null,
      actorUserId: ACTOR,
      tagNames: [],
    }

    const set = await updateTask(supabase, { ...base, estimatedMinutes: 45 })
    expect(set.estimated_minutes).toBe(45)

    const changed = await updateTask(supabase, {
      ...base,
      estimatedMinutes: 120,
    })
    expect(changed.estimated_minutes).toBe(120)

    const cleared = await updateTask(supabase, {
      ...base,
      estimatedMinutes: null,
    })
    expect(cleared.estimated_minutes).toBeNull()

    // Estimate edits are not activity-logged (SPEC: major events only, with
    // priority and due date as the sole field-edit exceptions).
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('rejects an invalid estimate, leaving the task unchanged', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', estimated_minutes: 30 })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateTask(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        dueDate: null,
        notes: null,
        lat: null,
        lng: null,
        estimatedMinutes: 0,
        completedAt: null,
        actorUserId: ACTOR,
        tagNames: [],
      }),
    ).rejects.toThrow(
      'Estimated time must be a positive whole number of minutes',
    )

    expect((fake.getTable('tasks')[0] as TaskRow).estimated_minutes).toBe(30)
  })

  it('rejects a half-set pin', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateTask(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        dueDate: null,
        notes: null,
        lat: 40.7128,
        lng: null,
        estimatedMinutes: null,
        completedAt: null,
        actorUserId: ACTOR,
        tagNames: [],
      }),
    ).rejects.toThrow('Location requires both lat and lng, or neither')
  })

  it('edits completed_at independently of status, logging nothing', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'done', completed_at: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      title: 'Fix the gate',
      categoryId: null,
      priority: 'soon',
      dueDate: null,
      notes: null,
      lat: null,
      lng: null,
      estimatedMinutes: null,
      completedAt: '2026-07-09T14:30:00.000Z',
      actorUserId: ACTOR,
      tagNames: [],
    })

    expect(result.completed_at).toBe('2026-07-09T14:30:00.000Z')
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('rejects an invalid completed_at, leaving the task unchanged', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'done', completed_at: null })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateTask(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        title: 'Fix the gate',
        categoryId: null,
        priority: 'soon',
        dueDate: null,
        notes: null,
        lat: null,
        lng: null,
        estimatedMinutes: null,
        completedAt: 'not a date',
        actorUserId: ACTOR,
        tagNames: [],
      }),
    ).rejects.toThrow('Completed date/time is invalid')

    expect((fake.getTable('tasks')[0] as TaskRow).completed_at).toBeNull()
  })
})

describe('deleteTask', () => {
  it('removes the task row and logs a task_deleted event', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', title: 'Fix the gate' })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await deleteTask(supabase, {
      farmId: FARM_A,
      taskId: 'task-1',
      actorUserId: ACTOR,
    })

    expect(fake.getTable('tasks')).toHaveLength(0)

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      farm_id: FARM_A,
      task_id: 'task-1',
      event_type: 'task_deleted',
      event_detail: { task_title: 'Fix the gate' },
      actor_user_id: ACTOR,
    })
  })

  it('throws Chore not found for a missing or wrong-farm task, writing no log entry', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', farm_id: FARM_B })],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      deleteTask(supabase, {
        farmId: FARM_A,
        taskId: 'task-1',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('Chore not found')

    expect(fake.getTable('tasks')).toHaveLength(1)
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })
})

describe('listTasks', () => {
  it("returns only the requested farm's tasks", async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({ id: 'task-1', farm_id: FARM_A }),
        task({ id: 'task-2', farm_id: FARM_B }),
      ],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTasks(supabase, FARM_A)

    expect(result.map((t) => t.id)).toEqual(['task-1'])
  })

  it('carries lat/lng through unchanged', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({ id: 'task-1', lat: 40.7128, lng: -74.006 }),
        task({
          id: 'task-2',
          lat: null,
          lng: null,
          created_at: '2026-01-02T00:00:00.000Z',
        }),
      ],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTasks(supabase, FARM_A)

    const task1 = result.find((t) => t.id === 'task-1')
    const task2 = result.find((t) => t.id === 'task-2')
    expect(task1).toMatchObject({ lat: 40.7128, lng: -74.006 })
    expect(task2).toMatchObject({ lat: null, lng: null })
  })

  it('orders urgent before soon before whenever, and oldest-first within a priority tier', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({
          id: 'task-whenever',
          priority: 'whenever',
          created_at: '2026-01-01T00:00:00.000Z',
        }),
        task({
          id: 'task-urgent-newer',
          priority: 'urgent',
          created_at: '2026-01-03T00:00:00.000Z',
        }),
        task({
          id: 'task-soon',
          priority: 'soon',
          created_at: '2026-01-02T00:00:00.000Z',
        }),
        task({
          id: 'task-urgent-older',
          priority: 'urgent',
          created_at: '2026-01-01T00:00:00.000Z',
        }),
      ],
      activity_log: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTasks(supabase, FARM_A)

    expect(result.map((t) => t.id)).toEqual([
      'task-urgent-older',
      'task-urgent-newer',
      'task-soon',
      'task-whenever',
    ])
  })

  it("attaches each task's tags, and [] for a task with no tags", async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({ id: 'task-1' }),
        task({ id: 'task-2', created_at: '2026-01-02T00:00:00.000Z' }),
      ],
      activity_log: [],
      tags: [
        tag({ id: 'tag-1', name: 'Gate' }),
        tag({ id: 'tag-2', name: 'Barn' }),
      ],
      task_tags: [
        taskTag({ task_id: 'task-1', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-1', tag_id: 'tag-2' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTasks(supabase, FARM_A)

    const task1 = result.find((t) => t.id === 'task-1')
    const task2 = result.find((t) => t.id === 'task-2')
    expect(task1?.tags.map((t) => t.name)).toEqual(['Barn', 'Gate'])
    expect(task2?.tags).toEqual([])
  })
})

describe('getTask', () => {
  it('returns the matching task, with tags attached', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1' })],
      tags: [tag({ id: 'tag-1', name: 'Gate' })],
      task_tags: [taskTag({ task_id: 'task-1', tag_id: 'tag-1' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await getTask(supabase, { farmId: FARM_A, taskId: 'task-1' })

    expect(result?.id).toBe('task-1')
    expect(result?.tags.map((t) => t.name)).toEqual(['Gate'])
  })

  it('returns null for a non-existent id rather than throwing', async () => {
    const fake = new FakeSupabaseClient({ tasks: [task({ id: 'task-1' })] })
    const supabase = asSupabaseClient(fake)

    const result = await getTask(supabase, {
      farmId: FARM_A,
      taskId: 'no-such-task',
    })

    expect(result).toBeNull()
  })

  it('returns null when the task exists but belongs to a different farm', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', farm_id: FARM_A })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await getTask(supabase, { farmId: FARM_B, taskId: 'task-1' })

    expect(result).toBeNull()
  })
})

describe('getTaskTitle', () => {
  it('returns the title for a task by id, with no farm_id filter needed', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', title: 'Fix the gate', farm_id: FARM_B })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await getTaskTitle(supabase, 'task-1')

    expect(result).toBe('Fix the gate')
  })

  it('returns null for a non-existent id rather than throwing', async () => {
    const fake = new FakeSupabaseClient({ tasks: [task({ id: 'task-1' })] })
    const supabase = asSupabaseClient(fake)

    const result = await getTaskTitle(supabase, 'no-such-task')

    expect(result).toBeNull()
  })
})

describe('assertValidEstimatedMinutes', () => {
  it('accepts null (no estimate) and positive integers up to the Postgres integer max', () => {
    expect(() => assertValidEstimatedMinutes(null)).not.toThrow()
    expect(() => assertValidEstimatedMinutes(1)).not.toThrow()
    expect(() => assertValidEstimatedMinutes(90)).not.toThrow()
    expect(() => assertValidEstimatedMinutes(2147483647)).not.toThrow()
  })

  it('rejects zero, negatives, fractions, non-finite values, and Postgres integer overflow', () => {
    for (const minutes of [0, -1, 1.5, NaN, Infinity, 2147483648]) {
      expect(() => assertValidEstimatedMinutes(minutes)).toThrow(
        'Estimated time must be a positive whole number of minutes',
      )
    }
  })
})

describe('assertValidCompletedAt', () => {
  it('accepts null and a valid ISO timestamp', () => {
    expect(() => assertValidCompletedAt(null)).not.toThrow()
    expect(() =>
      assertValidCompletedAt('2026-07-09T14:30:00.000Z'),
    ).not.toThrow()
  })

  it('rejects an unparseable timestamp', () => {
    expect(() => assertValidCompletedAt('not a date')).toThrow(
      'Completed date/time is invalid',
    )
  })
})

describe('isTaskOverdue', () => {
  const now = new Date(2026, 5, 15) // local June 15, 2026

  it('is true for a strictly-past due date when not_started', () => {
    expect(
      isTaskOverdue({ due_date: '2026-06-14', status: 'not_started' }, now),
    ).toBe(true)
  })

  it('is true for a strictly-past due date when in_progress', () => {
    expect(
      isTaskOverdue({ due_date: '2026-06-14', status: 'in_progress' }, now),
    ).toBe(true)
  })

  it("is false when the due date equals now's local date", () => {
    expect(
      isTaskOverdue({ due_date: '2026-06-15', status: 'not_started' }, now),
    ).toBe(false)
  })

  it('is false for a past due date when status is done', () => {
    expect(isTaskOverdue({ due_date: '2026-06-14', status: 'done' }, now)).toBe(
      false,
    )
  })

  it('is false when due_date is null', () => {
    expect(isTaskOverdue({ due_date: null, status: 'not_started' }, now)).toBe(
      false,
    )
  })
})

describe('compareTasksDoneLast', () => {
  it('sinks done tasks below not-done tasks regardless of priority', () => {
    const done = {
      id: 'a',
      priority: 'urgent' as const,
      created_at: '2026-01-01',
      status: 'done' as const,
    }
    const notDone = {
      id: 'b',
      priority: 'whenever' as const,
      created_at: '2026-01-01',
      status: 'not_started' as const,
    }
    expect(compareTasksDoneLast(done, notDone)).toBeGreaterThan(0)
    expect(compareTasksDoneLast(notDone, done)).toBeLessThan(0)
  })

  it('falls back to compareTasks priority ordering within the not-done group', () => {
    const urgent = {
      id: 'a',
      priority: 'urgent' as const,
      created_at: '2026-01-01',
      status: 'not_started' as const,
    }
    const soon = {
      id: 'b',
      priority: 'soon' as const,
      created_at: '2026-01-01',
      status: 'not_started' as const,
    }
    expect(compareTasksDoneLast(urgent, soon)).toBeLessThan(0)
  })

  it('falls back to compareTasks priority ordering within the done group', () => {
    const urgentDone = {
      id: 'a',
      priority: 'urgent' as const,
      created_at: '2026-01-01',
      status: 'done' as const,
    }
    const soonDone = {
      id: 'b',
      priority: 'soon' as const,
      created_at: '2026-01-01',
      status: 'done' as const,
    }
    expect(compareTasksDoneLast(urgentDone, soonDone)).toBeLessThan(0)
  })
})
