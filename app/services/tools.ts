import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface ToolItemSummary {
  id: string
  name: string
  checked: boolean
  created_at: string
}

const ITEM_COLUMNS = 'id, name, checked, created_at'

type Client = SupabaseClient<Database>

/**
 * All tool items for one task, in insertion order. `id` is a secondary sort
 * key because `created_at`/`now()` is transaction-time — rows inserted in the
 * same transaction share a timestamp, and order shouldn't be undefined if
 * that ever happens.
 */
export async function listToolItems(
  supabase: Client,
  taskId: string,
): Promise<ToolItemSummary[]> {
  const { data, error } = await supabase
    .from('task_tools')
    .select(ITEM_COLUMNS)
    .eq('task_id', taskId)
    .order('created_at')
    .order('id')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Add a tool to a task's tool list. `checked` is written explicitly
 * (matching the DB default) so the returned summary is complete without a
 * re-read.
 */
export async function addToolItem(
  supabase: Client,
  opts: { taskId: string; name: string },
): Promise<ToolItemSummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Tool name is required')

  const { data, error } = await supabase
    .from('task_tools')
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
async function updateToolItem(
  supabase: Client,
  itemId: string,
  patch: { name?: string; checked?: boolean },
): Promise<ToolItemSummary> {
  const { data, error } = await supabase
    .from('task_tools')
    .update(patch)
    .eq('id', itemId)
    .select(ITEM_COLUMNS)
  if (error) throw new Error(error.message)
  const item = data[0]
  if (!item) throw new Error('Tool item not found')
  return item
}

/** Set a tool's checked (have it ready) state. */
export async function setToolItemChecked(
  supabase: Client,
  opts: { itemId: string; checked: boolean },
): Promise<ToolItemSummary> {
  return updateToolItem(supabase, opts.itemId, { checked: opts.checked })
}

/** Rename a tool, trimming the new name. */
export async function renameToolItem(
  supabase: Client,
  opts: { itemId: string; name: string },
): Promise<ToolItemSummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Tool name is required')
  return updateToolItem(supabase, opts.itemId, { name })
}

/** Delete a tool from a task's tool list. */
export async function removeToolItem(
  supabase: Client,
  itemId: string,
): Promise<void> {
  const { error } = await supabase.from('task_tools').delete().eq('id', itemId)
  if (error) throw new Error(error.message)
}
