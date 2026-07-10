import { describe, expect, it } from 'vitest'
import {
  createCategory,
  deleteCategory,
  listCategories,
  updateCategory,
} from '../app/services/categories'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type CategoryRow = Database['public']['Tables']['categories']['Row']
type TaskRow = Database['public']['Tables']['tasks']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'
const ACTOR = 'user-1'

function category(overrides: Partial<CategoryRow> = {}): CategoryRow {
  return {
    id: 'cat-seed',
    farm_id: FARM_A,
    name: 'Fencing',
    deleted_at: null,
    created_at: '2026-01-01T00:00:00.000Z',
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

describe('deleteCategory', () => {
  it('blocks deletion when a not_started task references the category', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1' })],
      tasks: [
        task({ id: 'task-1', category_id: 'cat-1', status: 'not_started' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await deleteCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      actorUserId: ACTOR,
    })

    expect(result).toEqual({
      deleted: false,
      reason: 'active_tasks',
      activeTaskCount: 1,
    })
    expect(
      (fake.getTable('categories')[0] as CategoryRow).deleted_at,
    ).toBeNull()
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('blocks deletion when an in_progress task references the category', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1' })],
      tasks: [
        task({ id: 'task-1', category_id: 'cat-1', status: 'in_progress' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await deleteCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      actorUserId: ACTOR,
    })

    expect(result).toEqual({
      deleted: false,
      reason: 'active_tasks',
      activeTaskCount: 1,
    })
    expect(
      (fake.getTable('categories')[0] as CategoryRow).deleted_at,
    ).toBeNull()
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('allows deletion when only done tasks reference the category', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1' })],
      tasks: [task({ id: 'task-1', category_id: 'cat-1', status: 'done' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await deleteCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      actorUserId: ACTOR,
    })

    expect(result).toEqual({ deleted: true })
    const stored = fake.getTable('categories')[0] as CategoryRow
    expect(stored.deleted_at).not.toBeNull()

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      farm_id: FARM_A,
      task_id: null,
      event_type: 'category_deleted',
      event_detail: { category_id: 'cat-1', category_name: 'Fencing' },
      actor_user_id: ACTOR,
    })
  })

  it('allows deletion when no tasks reference the category', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1' })],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await deleteCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      actorUserId: ACTOR,
    })

    expect(result).toEqual({ deleted: true })
    expect(
      (fake.getTable('categories')[0] as CategoryRow).deleted_at,
    ).not.toBeNull()
    expect(fake.getTable('activity_log')).toHaveLength(1)
  })

  it('does not count active tasks in the same category belonging to a different farm', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1', farm_id: FARM_A })],
      tasks: [
        task({
          id: 'task-1',
          farm_id: FARM_B,
          category_id: 'cat-1',
          status: 'not_started',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await deleteCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      actorUserId: ACTOR,
    })

    expect(result).toEqual({ deleted: true })
  })

  it('throws when the category does not exist', async () => {
    const fake = new FakeSupabaseClient({ categories: [], tasks: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      deleteCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'missing',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('Category not found or already deleted')
  })

  it('throws when the category is already soft-deleted', async () => {
    const fake = new FakeSupabaseClient({
      categories: [
        category({ id: 'cat-1', deleted_at: '2026-01-01T00:00:00.000Z' }),
      ],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      deleteCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'cat-1',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('Category not found or already deleted')
  })

  it('throws when the active-task count query errors', async () => {
    const fake = new FakeSupabaseClient(
      { categories: [category({ id: 'cat-1' })], tasks: [] },
      { table: 'tasks', op: 'select', message: 'boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      deleteCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'cat-1',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('boom')
  })
})

describe('createCategory', () => {
  it('creates the category and logs a category_created event', async () => {
    const fake = new FakeSupabaseClient({ categories: [], tasks: [] })
    const supabase = asSupabaseClient(fake)

    const result = await createCategory(supabase, {
      farmId: FARM_A,
      name: 'Irrigation',
      actorUserId: ACTOR,
    })

    expect(result.name).toBe('Irrigation')
    expect(result.id).toBeTruthy()
    expect(result.created_at).toBeTruthy()

    const log = fake.getTable('activity_log')
    expect(log).toHaveLength(1)
    expect(log[0]).toMatchObject({
      farm_id: FARM_A,
      task_id: null,
      event_type: 'category_created',
      event_detail: { category_id: result.id, category_name: 'Irrigation' },
      actor_user_id: ACTOR,
    })
  })

  it('trims surrounding whitespace from the name before insert', async () => {
    const fake = new FakeSupabaseClient({ categories: [], tasks: [] })
    const supabase = asSupabaseClient(fake)

    const result = await createCategory(supabase, {
      farmId: FARM_A,
      name: '  Mowing  ',
      actorUserId: ACTOR,
    })

    expect(result.name).toBe('Mowing')
    expect((fake.getTable('categories')[0] as CategoryRow).name).toBe('Mowing')
  })

  it('throws and writes nothing for an empty or whitespace-only name', async () => {
    const fake = new FakeSupabaseClient({ categories: [], tasks: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      createCategory(supabase, {
        farmId: FARM_A,
        name: '   ',
        actorUserId: ACTOR,
      }),
    ).rejects.toThrow('Category name is required')

    expect(fake.getTable('categories')).toHaveLength(0)
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })
})

describe('updateCategory', () => {
  it('renames the category', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1', name: 'Fencing' })],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      name: 'Fence Repair',
    })

    expect(result.name).toBe('Fence Repair')
    expect((fake.getTable('categories')[0] as CategoryRow).name).toBe(
      'Fence Repair',
    )
    expect(fake.getTable('activity_log')).toHaveLength(0)
  })

  it('trims surrounding whitespace from the name before update', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1', name: 'Fencing' })],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateCategory(supabase, {
      farmId: FARM_A,
      categoryId: 'cat-1',
      name: '  Mowing  ',
    })

    expect(result.name).toBe('Mowing')
  })

  it('throws and writes nothing for an empty or whitespace-only name', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1', name: 'Fencing' })],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'cat-1',
        name: '   ',
      }),
    ).rejects.toThrow('Category name is required')

    expect((fake.getTable('categories')[0] as CategoryRow).name).toBe('Fencing')
  })

  it('throws when the category does not exist', async () => {
    const fake = new FakeSupabaseClient({ categories: [], tasks: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'missing',
        name: 'New Name',
      }),
    ).rejects.toThrow('Category not found or already deleted')
  })

  it('throws when the category is already soft-deleted', async () => {
    const fake = new FakeSupabaseClient({
      categories: [
        category({ id: 'cat-1', deleted_at: '2026-01-01T00:00:00.000Z' }),
      ],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'cat-1',
        name: 'New Name',
      }),
    ).rejects.toThrow('Category not found or already deleted')
  })

  it('does not rename a category belonging to a different farm', async () => {
    const fake = new FakeSupabaseClient({
      categories: [category({ id: 'cat-1', farm_id: FARM_B })],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      updateCategory(supabase, {
        farmId: FARM_A,
        categoryId: 'cat-1',
        name: 'New Name',
      }),
    ).rejects.toThrow('Category not found or already deleted')
  })
})

describe('listCategories', () => {
  it("returns only the given farm's non-deleted categories, sorted by name", async () => {
    const fake = new FakeSupabaseClient({
      categories: [
        category({ id: 'cat-1', farm_id: FARM_A, name: 'Mowing' }),
        category({ id: 'cat-2', farm_id: FARM_A, name: 'Fencing' }),
        category({
          id: 'cat-3',
          farm_id: FARM_A,
          name: 'Deleted',
          deleted_at: '2026-01-01T00:00:00.000Z',
        }),
        category({ id: 'cat-4', farm_id: FARM_B, name: 'Aardvark' }),
      ],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listCategories(supabase, FARM_A)

    expect(result.map((c) => c.name)).toEqual(['Fencing', 'Mowing'])
  })
})
