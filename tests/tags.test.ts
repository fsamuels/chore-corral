import { describe, expect, it } from 'vitest'
import {
  listTags,
  listTagsForTasks,
  listTagsWithCounts,
  resolveTags,
  setTaskTags,
} from '../app/services/tags'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type TagRow = Database['public']['Tables']['tags']['Row']
type TaskTagRow = Database['public']['Tables']['task_tags']['Row']
type TaskRow = Database['public']['Tables']['tasks']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'

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
    category_id: null,
    priority: 'soon',
    status: 'not_started',
    due_date: null,
    notes: null,
    lat: null,
    lng: null,
    location_id: null,
    created_at: '2026-01-01T00:00:00.000Z',
    created_by: 'user-1',
    completed_at: null,
    estimated_minutes: null,
    ...overrides,
  }
}

const ZERO_COUNTS = { not_started: 0, in_progress: 0, done: 0 }

describe('listTags', () => {
  it("returns only the given farm's tags, sorted by name", async () => {
    const fake = new FakeSupabaseClient({
      tags: [
        tag({ id: 'tag-1', farm_id: FARM_A, name: 'Mowing' }),
        tag({ id: 'tag-2', farm_id: FARM_A, name: 'Fence' }),
        tag({ id: 'tag-3', farm_id: FARM_B, name: 'Aardvark' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTags(supabase, FARM_A)

    expect(result.map((t) => t.name)).toEqual(['Fence', 'Mowing'])
  })
})

describe('resolveTags', () => {
  it('creates new tags that do not exist yet, normalized to lowercase', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence', 'Gate'],
    })

    expect(result.map((t) => t.name)).toEqual(['fence', 'gate'])
    expect(fake.getTable('tags')).toHaveLength(2)
  })

  it('collapses internal whitespace when normalizing a new tag name', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence   Repair'],
    })

    expect(result.map((t) => t.name)).toEqual(['fence repair'])
  })

  it('treats differently-cased, differently-spaced input as the same tag', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence   Repair', 'fence repair', '  FENCE REPAIR  '],
    })

    expect(result).toHaveLength(1)
    expect(result[0]!.name).toBe('fence repair')
    expect(fake.getTable('tags')).toHaveLength(1)
  })

  it('reuses an existing tag when the candidate normalizes to its stored name', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', farm_id: FARM_A, name: 'fence repair' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence   Repair'],
    })

    expect(result).toEqual([
      { id: 'tag-1', name: 'fence repair', created_at: tag().created_at },
    ])
    expect(fake.getTable('tags')).toHaveLength(1)
  })

  it('reuses an existing tag by exact name match instead of creating a duplicate', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', farm_id: FARM_A, name: 'Fence' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence'],
    })

    expect(result).toEqual([
      { id: 'tag-1', name: 'Fence', created_at: tag().created_at },
    ])
    expect(fake.getTable('tags')).toHaveLength(1)
  })

  it('reuses an existing tag case-insensitively without creating a duplicate', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', farm_id: FARM_A, name: 'fence' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence'],
    })

    expect(result).toEqual([
      { id: 'tag-1', name: 'fence', created_at: tag().created_at },
    ])
    expect(fake.getTable('tags')).toHaveLength(1)
  })

  it('dedupes repeated names within one call', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence', 'fence', 'FENCE'],
    })

    expect(result).toHaveLength(1)
    expect(fake.getTable('tags')).toHaveLength(1)
  })

  it('trims whitespace and drops empty-string entries', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['  Fence  ', '   ', ''],
    })

    expect(result.map((t) => t.name)).toEqual(['fence'])
  })

  it('returns [] for empty input without any DB calls', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, { farmId: FARM_A, names: [] })

    expect(result).toEqual([])
    expect(fake.getTable('tags')).toHaveLength(0)
  })

  it('does not reuse a same-named tag from a different farm', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', farm_id: FARM_B, name: 'Fence' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await resolveTags(supabase, {
      farmId: FARM_A,
      names: ['Fence'],
    })

    expect(result).toHaveLength(1)
    expect(result[0]!.id).not.toBe('tag-1')
    const farmATags = fake
      .getTable('tags')
      .filter((row) => (row as unknown as TagRow).farm_id === FARM_A)
    expect(farmATags).toHaveLength(1)
  })
})

describe('setTaskTags', () => {
  it('replaces the full set of tags for a task', async () => {
    const fake = new FakeSupabaseClient({
      task_tags: [
        taskTag({ task_id: 'task-1', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-1', tag_id: 'tag-2' }),
        taskTag({ task_id: 'task-2', tag_id: 'tag-1' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskTags(supabase, { taskId: 'task-1', tagIds: ['tag-3'] })

    const rows = fake.getTable('task_tags') as unknown as TaskTagRow[]
    const forTask1 = rows.filter((r) => r.task_id === 'task-1')
    expect(forTask1.map((r) => r.tag_id)).toEqual(['tag-3'])
    // Other tasks' associations are untouched.
    expect(
      rows.some((r) => r.task_id === 'task-2' && r.tag_id === 'tag-1'),
    ).toBe(true)
  })

  it('clears all tags when given an empty array, without attempting an insert', async () => {
    const fake = new FakeSupabaseClient({
      task_tags: [
        taskTag({ task_id: 'task-1', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-1', tag_id: 'tag-2' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskTags(supabase, { taskId: 'task-1', tagIds: [] })

    const rows = fake.getTable('task_tags') as unknown as TaskTagRow[]
    expect(rows.filter((r) => r.task_id === 'task-1')).toHaveLength(0)
  })
})

describe('listTagsForTasks', () => {
  it('returns per-task grouping for multiple tasks sharing some tags', async () => {
    const fake = new FakeSupabaseClient({
      tags: [
        tag({ id: 'tag-1', name: 'Fence' }),
        tag({ id: 'tag-2', name: 'Gate' }),
        tag({ id: 'tag-3', name: 'Barn' }),
      ],
      task_tags: [
        taskTag({ task_id: 'task-1', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-1', tag_id: 'tag-2' }),
        taskTag({ task_id: 'task-2', tag_id: 'tag-1' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsForTasks(supabase, ['task-1', 'task-2'])

    expect(result.get('task-1')?.map((t) => t.name)).toEqual(['Fence', 'Gate'])
    expect(result.get('task-2')?.map((t) => t.name)).toEqual(['Fence'])
  })

  it('a task with no tags is absent from the map', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', name: 'Fence' })],
      task_tags: [taskTag({ task_id: 'task-1', tag_id: 'tag-1' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsForTasks(supabase, ['task-1', 'task-2'])

    expect(result.get('task-2')).toBeUndefined()
    expect(result.has('task-2')).toBe(false)
  })

  it('returns an empty map immediately for an empty input array', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', name: 'Fence' })],
      task_tags: [taskTag({ task_id: 'task-1', tag_id: 'tag-1' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsForTasks(supabase, [])

    expect(result.size).toBe(0)
  })
})

describe('listTagsWithCounts', () => {
  it('returns an empty array when the farm has no tags', async () => {
    const fake = new FakeSupabaseClient({ tags: [] })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsWithCounts(supabase, FARM_A)

    expect(result).toEqual([])
  })

  it('gives a tag with no tasks tagged a count of zero', async () => {
    const fake = new FakeSupabaseClient({
      tags: [tag({ id: 'tag-1', farm_id: FARM_A, name: 'Fence' })],
      task_tags: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsWithCounts(supabase, FARM_A)

    expect(result).toEqual([
      {
        id: 'tag-1',
        name: 'Fence',
        created_at: tag().created_at,
        taskCount: 0,
        statusCounts: ZERO_COUNTS,
      },
    ])
  })

  it('counts tasks per tag independently, broken down by status, sorted by name', async () => {
    const fake = new FakeSupabaseClient({
      tags: [
        tag({ id: 'tag-1', farm_id: FARM_A, name: 'Mowing' }),
        tag({ id: 'tag-2', farm_id: FARM_A, name: 'Fence' }),
      ],
      tasks: [
        task({ id: 'task-1', status: 'not_started' }),
        task({ id: 'task-2', status: 'done' }),
        task({ id: 'task-3', status: 'in_progress' }),
      ],
      task_tags: [
        taskTag({ task_id: 'task-1', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-2', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-3', tag_id: 'tag-2' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsWithCounts(supabase, FARM_A)

    expect(result).toEqual([
      {
        id: 'tag-2',
        name: 'Fence',
        created_at: tag().created_at,
        taskCount: 1,
        statusCounts: { not_started: 0, in_progress: 1, done: 0 },
      },
      {
        id: 'tag-1',
        name: 'Mowing',
        created_at: tag().created_at,
        taskCount: 2,
        statusCounts: { not_started: 1, in_progress: 0, done: 1 },
      },
    ])
  })

  it("does not count another farm's task_tags rows", async () => {
    const fake = new FakeSupabaseClient({
      tags: [
        tag({ id: 'tag-1', farm_id: FARM_A, name: 'Fence' }),
        tag({ id: 'tag-2', farm_id: FARM_B, name: 'Gate' }),
      ],
      tasks: [
        task({ id: 'task-1', farm_id: FARM_A, status: 'not_started' }),
        task({ id: 'task-2', farm_id: FARM_B, status: 'not_started' }),
      ],
      task_tags: [
        taskTag({ task_id: 'task-1', tag_id: 'tag-1' }),
        taskTag({ task_id: 'task-2', tag_id: 'tag-2' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listTagsWithCounts(supabase, FARM_A)

    expect(result).toEqual([
      {
        id: 'tag-1',
        name: 'Fence',
        created_at: tag().created_at,
        taskCount: 1,
        statusCounts: { not_started: 1, in_progress: 0, done: 0 },
      },
    ])
  })
})
