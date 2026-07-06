import { describe, expect, it } from 'vitest'
import {
  addShoppingItem,
  listShoppingItems,
  removeShoppingItem,
  renameShoppingItem,
  setShoppingItemChecked,
} from '../app/services/shopping'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type ItemRow = Database['public']['Tables']['task_shopping_items']['Row']

const TASK_A = 'task-a'

function item(overrides: Partial<ItemRow> = {}): ItemRow {
  return {
    id: 'item-seed',
    task_id: TASK_A,
    name: 'fence posts',
    checked: false,
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

describe('listShoppingItems', () => {
  it('returns an empty list for a task with no items', async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [item({ id: 'item-1', task_id: 'task-b' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listShoppingItems(supabase, TASK_A)

    expect(result).toEqual([])
  })

  it("returns only the given task's items, in insertion order", async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [
        item({ id: 'item-2', created_at: '2026-01-02T00:00:00.000Z' }),
        item({ id: 'item-1', created_at: '2026-01-01T00:00:00.000Z' }),
        item({ id: 'item-3', task_id: 'task-b' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listShoppingItems(supabase, TASK_A)

    expect(result.map((i) => i.id)).toEqual(['item-1', 'item-2'])
  })

  it('breaks created_at ties by id, so bulk-inserted rows have a stable order', async () => {
    const sharedTimestamp = '2026-01-01T00:00:00.000Z'
    const fake = new FakeSupabaseClient({
      task_shopping_items: [
        item({ id: 'item-b', created_at: sharedTimestamp }),
        item({ id: 'item-a', created_at: sharedTimestamp }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listShoppingItems(supabase, TASK_A)

    expect(result.map((i) => i.id)).toEqual(['item-a', 'item-b'])
  })

  it('propagates a select failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_shopping_items: [] },
      { table: 'task_shopping_items', op: 'select' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listShoppingItems(supabase, TASK_A)).rejects.toThrow()
  })
})

describe('addShoppingItem', () => {
  it('inserts an unchecked row and returns it with a trimmed name', async () => {
    const fake = new FakeSupabaseClient({ task_shopping_items: [] })
    const supabase = asSupabaseClient(fake)

    const result = await addShoppingItem(supabase, {
      taskId: TASK_A,
      name: '  gate hinges  ',
    })

    expect(result.name).toBe('gate hinges')
    expect(result.checked).toBe(false)
    expect(fake.getTable('task_shopping_items')).toHaveLength(1)
    expect(fake.getTable('task_shopping_items')[0]).toMatchObject({
      task_id: TASK_A,
      name: 'gate hinges',
      checked: false,
    })
  })

  it('rejects an empty or whitespace-only name without inserting', async () => {
    const fake = new FakeSupabaseClient({ task_shopping_items: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      addShoppingItem(supabase, { taskId: TASK_A, name: '' }),
    ).rejects.toThrow('Item name is required')
    await expect(
      addShoppingItem(supabase, { taskId: TASK_A, name: '   ' }),
    ).rejects.toThrow('Item name is required')

    expect(fake.getTable('task_shopping_items')).toHaveLength(0)
  })

  it('allows duplicate item names on the same task', async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [item({ id: 'item-1', name: 'bolts' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await addShoppingItem(supabase, {
      taskId: TASK_A,
      name: 'bolts',
    })

    expect(result.name).toBe('bolts')
    expect(fake.getTable('task_shopping_items')).toHaveLength(2)
  })

  it('propagates an insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_shopping_items: [] },
      { table: 'task_shopping_items', op: 'insert' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      addShoppingItem(supabase, { taskId: TASK_A, name: 'staples' }),
    ).rejects.toThrow()
  })
})

describe('setShoppingItemChecked', () => {
  it('checks an unchecked item and returns the updated row', async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [item({ id: 'item-1', checked: false })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await setShoppingItemChecked(supabase, {
      itemId: 'item-1',
      checked: true,
    })

    expect(result.checked).toBe(true)
    expect(fake.getTable('task_shopping_items')[0]?.checked).toBe(true)
  })

  it('unchecks a checked item', async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [item({ id: 'item-1', checked: true })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await setShoppingItemChecked(supabase, {
      itemId: 'item-1',
      checked: false,
    })

    expect(result.checked).toBe(false)
    expect(fake.getTable('task_shopping_items')[0]?.checked).toBe(false)
  })

  it('throws when the item does not exist', async () => {
    const fake = new FakeSupabaseClient({ task_shopping_items: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      setShoppingItemChecked(supabase, { itemId: 'missing', checked: true }),
    ).rejects.toThrow('Shopping item not found')
  })

  it('propagates an update failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_shopping_items: [item({ id: 'item-1' })] },
      { table: 'task_shopping_items', op: 'update' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      setShoppingItemChecked(supabase, { itemId: 'item-1', checked: true }),
    ).rejects.toThrow()
  })
})

describe('renameShoppingItem', () => {
  it('renames an item with a trimmed name', async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [item({ id: 'item-1', name: 'fence posts' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await renameShoppingItem(supabase, {
      itemId: 'item-1',
      name: '  cedar fence posts  ',
    })

    expect(result.name).toBe('cedar fence posts')
    expect(fake.getTable('task_shopping_items')[0]?.name).toBe(
      'cedar fence posts',
    )
  })

  it('rejects an empty name without updating', async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [item({ id: 'item-1', name: 'fence posts' })],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      renameShoppingItem(supabase, { itemId: 'item-1', name: '   ' }),
    ).rejects.toThrow('Item name is required')

    expect(fake.getTable('task_shopping_items')[0]?.name).toBe('fence posts')
  })

  it('throws when the item does not exist', async () => {
    const fake = new FakeSupabaseClient({ task_shopping_items: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      renameShoppingItem(supabase, { itemId: 'missing', name: 'wire' }),
    ).rejects.toThrow('Shopping item not found')
  })
})

describe('removeShoppingItem', () => {
  it("removes only the given item, leaving other tasks' items alone", async () => {
    const fake = new FakeSupabaseClient({
      task_shopping_items: [
        item({ id: 'item-1' }),
        item({ id: 'item-2' }),
        item({ id: 'item-3', task_id: 'task-b' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await removeShoppingItem(supabase, 'item-1')

    expect(fake.getTable('task_shopping_items').map((row) => row.id)).toEqual([
      'item-2',
      'item-3',
    ])
  })

  it('propagates a delete failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_shopping_items: [item({ id: 'item-1' })] },
      { table: 'task_shopping_items', op: 'delete' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(removeShoppingItem(supabase, 'item-1')).rejects.toThrow()
  })
})
