import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface ShoppingItemSummary {
  id: string
  name: string
  checked: boolean
  created_at: string
}

const ITEM_COLUMNS = 'id, name, checked, created_at'

type Client = SupabaseClient<Database>

/**
 * All shopping items for one task, in insertion order. `id` is a secondary
 * sort key because `created_at`/`now()` is transaction-time — rows inserted
 * in the same transaction share a timestamp, and order shouldn't be
 * undefined if that ever happens.
 */
export async function listShoppingItems(
  supabase: Client,
  taskId: string,
): Promise<ShoppingItemSummary[]> {
  const { data, error } = await supabase
    .from('task_shopping_items')
    .select(ITEM_COLUMNS)
    .eq('task_id', taskId)
    .order('created_at')
    .order('id')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Add an item to a task's shopping list. `checked` is written explicitly
 * (matching the DB default) so the returned summary is complete without a
 * re-read.
 */
export async function addShoppingItem(
  supabase: Client,
  opts: { taskId: string; name: string },
): Promise<ShoppingItemSummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Item name is required')

  const { data, error } = await supabase
    .from('task_shopping_items')
    .insert({ task_id: opts.taskId, name, checked: false })
    .select(ITEM_COLUMNS)
    .single()
  if (error) throw new Error(error.message)
  return data
}

/**
 * Shared update path for the two single-field mutations below. Follows
 * `updateTask`'s pattern: `.update().eq().select()` returns an array, and
 * the first element is taken (`.single()` chained after `.update()` isn't
 * supported — see `updateTaskPhotoCaption`).
 */
async function updateShoppingItem(
  supabase: Client,
  itemId: string,
  patch: { name?: string; checked?: boolean },
): Promise<ShoppingItemSummary> {
  const { data, error } = await supabase
    .from('task_shopping_items')
    .update(patch)
    .eq('id', itemId)
    .select(ITEM_COLUMNS)
  if (error) throw new Error(error.message)
  const item = data[0]
  if (!item) throw new Error('Shopping item not found')
  return item
}

/** Set an item's checked (bought) state. */
export async function setShoppingItemChecked(
  supabase: Client,
  opts: { itemId: string; checked: boolean },
): Promise<ShoppingItemSummary> {
  return updateShoppingItem(supabase, opts.itemId, { checked: opts.checked })
}

/** Rename an item, trimming the new name. */
export async function renameShoppingItem(
  supabase: Client,
  opts: { itemId: string; name: string },
): Promise<ShoppingItemSummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Item name is required')
  return updateShoppingItem(supabase, opts.itemId, { name })
}

/** Delete an item from a task's shopping list. */
export async function removeShoppingItem(
  supabase: Client,
  itemId: string,
): Promise<void> {
  const { error } = await supabase
    .from('task_shopping_items')
    .delete()
    .eq('id', itemId)
  if (error) throw new Error(error.message)
}
