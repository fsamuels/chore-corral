import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

// Statuses that block category deletion (DATA_MODEL.md: a category can't be
// soft-deleted while any task referencing it has status != 'done'). This is
// the app-layer half of the authorization split — RLS only backstops farm
// scoping, it can't express this rule.
export const ACTIVE_TASK_STATUSES = ['not_started', 'in_progress'] as const

export interface CategorySummary {
  id: string
  name: string
  /** Optional decorative emoji (null when unset). */
  emoji: string | null
  created_at: string
}

// Normalize category emoji input: trim, and treat empty as "no emoji" (null).
// Kept short to a single emoji at the DB layer (categories_emoji_length),
// which this doesn't re-check — bad input surfaces as the DB constraint error.
function normalizeEmoji(emoji: string | null | undefined): string | null {
  const trimmed = emoji?.trim()
  return trimmed ? trimmed : null
}

export type DeleteCategoryResult =
  | { deleted: true }
  | { deleted: false; reason: 'active_tasks'; activeTaskCount: number }

type Client = SupabaseClient<Database>

/** Active (non-soft-deleted) categories for one farm, sorted by name. */
export async function listCategories(
  supabase: Client,
  farmId: string,
): Promise<CategorySummary[]> {
  const { data, error } = await supabase
    .from('categories')
    .select('id, name, emoji, created_at')
    .eq('farm_id', farmId)
    .is('deleted_at', null)
    .order('name')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Create a category and log a `category_created` event.
 *
 * The two inserts are sequential, not transactional (supabase-js has no
 * client-side transactions): if the log insert fails the category still
 * exists and the thrown error surfaces the partial failure. Acceptable for
 * MVP; an RPC wrapping both in one transaction is the upgrade path.
 */
export async function createCategory(
  supabase: Client,
  opts: {
    farmId: string
    name: string
    emoji?: string | null
    actorUserId: string
  },
): Promise<CategorySummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Category name is required')

  const { data, error } = await supabase
    .from('categories')
    .insert({ farm_id: opts.farmId, name, emoji: normalizeEmoji(opts.emoji) })
    .select('id, name, emoji, created_at')
    .single()
  if (error) throw new Error(error.message)

  await logCategoryEvent(supabase, 'category_created', data, opts)
  return data
}

/**
 * Edit a category's name. Not logged (field edits, like a location's, are
 * not major events).
 */
export async function updateCategory(
  supabase: Client,
  opts: {
    farmId: string
    categoryId: string
    name: string
    emoji?: string | null
  },
): Promise<CategorySummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Category name is required')

  const { data, error } = await supabase
    .from('categories')
    .update({ name, emoji: normalizeEmoji(opts.emoji) })
    .eq('id', opts.categoryId)
    .eq('farm_id', opts.farmId)
    .is('deleted_at', null)
    .select('id, name, emoji, created_at')
  if (error) throw new Error(error.message)
  const category = data[0]
  if (!category) throw new Error('Category not found or already deleted')
  return category
}

/**
 * Soft-delete a category, unless any active task still references it —
 * the check and the update are two statements, so a concurrent task
 * creation can slip between them; fine at this app's scale (see
 * ARCHITECTURE.md's app-layer vs RLS split for where this rule lives).
 * Logs a `category_deleted` event on success.
 */
export async function deleteCategory(
  supabase: Client,
  opts: { farmId: string; categoryId: string; actorUserId: string },
): Promise<DeleteCategoryResult> {
  const { count, error: countError } = await supabase
    .from('tasks')
    .select('id', { count: 'exact', head: true })
    .eq('farm_id', opts.farmId)
    .eq('category_id', opts.categoryId)
    .in('status', [...ACTIVE_TASK_STATUSES])
  if (countError) throw new Error(countError.message)
  if (count !== null && count > 0) {
    return { deleted: false, reason: 'active_tasks', activeTaskCount: count }
  }

  const { data, error } = await supabase
    .from('categories')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', opts.categoryId)
    .eq('farm_id', opts.farmId)
    .is('deleted_at', null)
    .select('id, name')
  if (error) throw new Error(error.message)
  const category = data[0]
  if (!category) throw new Error('Category not found or already deleted')

  await logCategoryEvent(supabase, 'category_deleted', category, opts)
  return { deleted: true }
}

// event_detail snapshots the category name (the category analog of the
// task_title snapshot DATA_MODEL.md requires on task events) so log entries
// stay readable without joining back to a possibly-soft-deleted row.
async function logCategoryEvent(
  supabase: Client,
  eventType: 'category_created' | 'category_deleted',
  category: { id: string; name: string },
  opts: { farmId: string; actorUserId: string },
): Promise<void> {
  const { error } = await supabase.from('activity_log').insert({
    farm_id: opts.farmId,
    task_id: null,
    event_type: eventType,
    event_detail: { category_id: category.id, category_name: category.name },
    actor_user_id: opts.actorUserId,
  })
  if (error) throw new Error(error.message)
}
