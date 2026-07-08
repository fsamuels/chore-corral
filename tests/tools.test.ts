import { describe, expect, it } from 'vitest'
import {
  addToolItem,
  listToolItems,
  removeToolItem,
  renameToolItem,
  setToolItemChecked,
} from '../app/services/tools'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type ItemRow = Database['public']['Tables']['task_tools']['Row']

const TASK_A = 'task-a'

function item(overrides: Partial<ItemRow> = {}): ItemRow {
  return {
    id: 'item-seed',
    task_id: TASK_A,
    name: 'chainsaw',
    checked: false,
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

describe('listToolItems', () => {
  it('returns an empty list for a task with no items', async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [item({ id: 'item-1', task_id: 'task-b' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listToolItems(supabase, TASK_A)

    expect(result).toEqual([])
  })

  it("returns only the given task's items, in insertion order", async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [
        item({ id: 'item-2', created_at: '2026-01-02T00:00:00.000Z' }),
        item({ id: 'item-1', created_at: '2026-01-01T00:00:00.000Z' }),
        item({ id: 'item-3', task_id: 'task-b' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listToolItems(supabase, TASK_A)

    expect(result.map((i) => i.id)).toEqual(['item-1', 'item-2'])
  })

  it('breaks created_at ties by id, so bulk-inserted rows have a stable order', async () => {
    const sharedTimestamp = '2026-01-01T00:00:00.000Z'
    const fake = new FakeSupabaseClient({
      task_tools: [
        item({ id: 'item-b', created_at: sharedTimestamp }),
        item({ id: 'item-a', created_at: sharedTimestamp }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listToolItems(supabase, TASK_A)

    expect(result.map((i) => i.id)).toEqual(['item-a', 'item-b'])
  })

  it('propagates a select failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_tools: [] },
      { table: 'task_tools', op: 'select' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(listToolItems(supabase, TASK_A)).rejects.toThrow()
  })
})

describe('addToolItem', () => {
  it('inserts an unchecked row and returns it with a trimmed name', async () => {
    const fake = new FakeSupabaseClient({ task_tools: [] })
    const supabase = asSupabaseClient(fake)

    const result = await addToolItem(supabase, {
      taskId: TASK_A,
      name: '  post driver  ',
    })

    expect(result.name).toBe('post driver')
    expect(result.checked).toBe(false)
    expect(fake.getTable('task_tools')).toHaveLength(1)
    expect(fake.getTable('task_tools')[0]).toMatchObject({
      task_id: TASK_A,
      name: 'post driver',
      checked: false,
    })
  })

  it('rejects an empty or whitespace-only name without inserting', async () => {
    const fake = new FakeSupabaseClient({ task_tools: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      addToolItem(supabase, { taskId: TASK_A, name: '' }),
    ).rejects.toThrow('Tool name is required')
    await expect(
      addToolItem(supabase, { taskId: TASK_A, name: '   ' }),
    ).rejects.toThrow('Tool name is required')

    expect(fake.getTable('task_tools')).toHaveLength(0)
  })

  it('allows duplicate tool names on the same task', async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [item({ id: 'item-1', name: 'chainsaw' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await addToolItem(supabase, {
      taskId: TASK_A,
      name: 'chainsaw',
    })

    expect(result.name).toBe('chainsaw')
    expect(fake.getTable('task_tools')).toHaveLength(2)
  })

  it('propagates an insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_tools: [] },
      { table: 'task_tools', op: 'insert' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      addToolItem(supabase, { taskId: TASK_A, name: 'ladder' }),
    ).rejects.toThrow()
  })
})

describe('setToolItemChecked', () => {
  it('checks an unchecked item and returns the updated row', async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [item({ id: 'item-1', checked: false })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await setToolItemChecked(supabase, {
      itemId: 'item-1',
      checked: true,
    })

    expect(result.checked).toBe(true)
    expect(fake.getTable('task_tools')[0]?.checked).toBe(true)
  })

  it('unchecks a checked item', async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [item({ id: 'item-1', checked: true })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await setToolItemChecked(supabase, {
      itemId: 'item-1',
      checked: false,
    })

    expect(result.checked).toBe(false)
    expect(fake.getTable('task_tools')[0]?.checked).toBe(false)
  })

  it('throws when the item does not exist', async () => {
    const fake = new FakeSupabaseClient({ task_tools: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      setToolItemChecked(supabase, { itemId: 'missing', checked: true }),
    ).rejects.toThrow('Tool item not found')
  })

  it('propagates an update failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_tools: [item({ id: 'item-1' })] },
      { table: 'task_tools', op: 'update' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      setToolItemChecked(supabase, { itemId: 'item-1', checked: true }),
    ).rejects.toThrow()
  })
})

describe('renameToolItem', () => {
  it('renames an item with a trimmed name', async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [item({ id: 'item-1', name: 'chainsaw' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await renameToolItem(supabase, {
      itemId: 'item-1',
      name: '  cordless chainsaw  ',
    })

    expect(result.name).toBe('cordless chainsaw')
    expect(fake.getTable('task_tools')[0]?.name).toBe('cordless chainsaw')
  })

  it('rejects an empty name without updating', async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [item({ id: 'item-1', name: 'chainsaw' })],
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      renameToolItem(supabase, { itemId: 'item-1', name: '   ' }),
    ).rejects.toThrow('Tool name is required')

    expect(fake.getTable('task_tools')[0]?.name).toBe('chainsaw')
  })

  it('throws when the item does not exist', async () => {
    const fake = new FakeSupabaseClient({ task_tools: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      renameToolItem(supabase, { itemId: 'missing', name: 'wrench' }),
    ).rejects.toThrow('Tool item not found')
  })
})

describe('removeToolItem', () => {
  it("removes only the given item, leaving other tasks' items alone", async () => {
    const fake = new FakeSupabaseClient({
      task_tools: [
        item({ id: 'item-1' }),
        item({ id: 'item-2' }),
        item({ id: 'item-3', task_id: 'task-b' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await removeToolItem(supabase, 'item-1')

    expect(fake.getTable('task_tools').map((row) => row.id)).toEqual([
      'item-2',
      'item-3',
    ])
  })

  it('propagates a delete failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_tools: [item({ id: 'item-1' })] },
      { table: 'task_tools', op: 'delete' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(removeToolItem(supabase, 'item-1')).rejects.toThrow()
  })
})
