import { describe, expect, it } from 'vitest'
import {
  changeTaskStatus,
  createTask,
  deleteTask,
  isTaskOverdue,
  listTasks,
  updateTask,
} from '../app/services/tasks'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type TaskRow = Database['public']['Tables']['tasks']['Row']
type TagRow = Database['public']['Tables']['tags']['Row']
type TaskTagRow = Database['public']['Tables']['task_tags']['Row']

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
    created_at: '2026-01-01T00:00:00.000Z',
    created_by: ACTOR,
    completed_at: null,
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
    ).rejects.toThrow('Task title is required')

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

    expect(result.tags.map((t) => t.name)).toEqual(['Barn', 'Gate'])
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
})

describe('changeTaskStatus', () => {
  it('moves not_started to done, sets completed_at, and logs the transition', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1', status: 'not_started' })],
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

  it('reopening (done to in_progress) clears completed_at back to null', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [
        task({
          id: 'task-1',
          status: 'done',
          completed_at: '2026-01-02T00:00:00.000Z',
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

  it('throws Task not found when the task belongs to a different farm, writing no log entry', async () => {
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
    ).rejects.toThrow('Task not found')

    expect(fake.getTable('activity_log')).toHaveLength(0)
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

  it('writes no activity_log entries', async () => {
    const fake = new FakeSupabaseClient({
      tasks: [task({ id: 'task-1' })],
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
      notes: null,
      tagNames: ['Fence'],
    })

    expect(fake.getTable('activity_log')).toHaveLength(0)
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
        tagNames: [],
      }),
    ).rejects.toThrow('Task title is required')
  })

  it('throws Task not found for a wrong-farm task id', async () => {
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
        tagNames: [],
      }),
    ).rejects.toThrow('Task not found')
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
      tagNames: ['Gate', 'Barn'],
    })

    expect(result.tags.map((t) => t.name)).toEqual(['Barn', 'Gate'])

    const taskTagRows = fake
      .getTable('task_tags')
      .filter((r) => (r as { task_id: string }).task_id === 'task-1')
    expect(taskTagRows).toHaveLength(2)
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

  it('throws Task not found for a missing or wrong-farm task, writing no log entry', async () => {
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
    ).rejects.toThrow('Task not found')

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
