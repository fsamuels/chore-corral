import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface TagSummary {
  id: string
  name: string
  created_at: string
}

type Client = SupabaseClient<Database>

/** Active per-farm tags, sorted by name. */
export async function listTags(
  supabase: Client,
  farmId: string,
): Promise<TagSummary[]> {
  const { data, error } = await supabase
    .from('tags')
    .select('id, name, created_at')
    .eq('farm_id', farmId)
    .order('name')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Resolve freeform tag name input into `tags` rows, creating any that don't
 * exist yet for the farm. Names are trimmed, empty entries dropped, and
 * duplicates (case-insensitively — "Fence"/"fence" are the same tag) merged,
 * keeping the first-seen casing. Postgres `text` comparison is case-sensitive,
 * so `.in('name', [...])` can't be relied on for the case-insensitive match;
 * instead this fetches all of the farm's tags and matches in JS.
 */
export async function resolveTags(
  supabase: Client,
  opts: { farmId: string; names: string[] },
): Promise<TagSummary[]> {
  const trimmed = opts.names.map((name) => name.trim()).filter(Boolean)
  if (trimmed.length === 0) return []

  const uniqueByKey = new Map<string, string>()
  for (const name of trimmed) {
    const key = name.toLowerCase()
    if (!uniqueByKey.has(key)) uniqueByKey.set(key, name)
  }

  const existing = await listTags(supabase, opts.farmId)
  const existingByKey = new Map(
    existing.map((tag) => [tag.name.toLowerCase(), tag]),
  )

  const namesToCreate = [...uniqueByKey.entries()]
    .filter(([key]) => !existingByKey.has(key))
    .map(([, name]) => name)

  let created: TagSummary[] = []
  if (namesToCreate.length > 0) {
    const { data, error } = await supabase
      .from('tags')
      .insert(namesToCreate.map((name) => ({ farm_id: opts.farmId, name })))
      .select('id, name, created_at')
    if (error) throw new Error(error.message)
    created = data
  }
  const createdByKey = new Map(
    created.map((tag) => [tag.name.toLowerCase(), tag]),
  )

  return [...uniqueByKey.keys()].map((key) => {
    const tag = existingByKey.get(key) ?? createdByKey.get(key)
    if (!tag) throw new Error(`Failed to resolve tag "${uniqueByKey.get(key)}"`)
    return tag
  })
}

/**
 * Replace a task's full tag set: delete existing `task_tags` rows for the
 * task, then bulk-insert the new set. Skips the insert entirely when
 * `tagIds` is empty, both because there's nothing to write and to avoid an
 * insert-of-empty-array call.
 */
export async function setTaskTags(
  supabase: Client,
  opts: { taskId: string; tagIds: string[] },
): Promise<void> {
  const { error: deleteError } = await supabase
    .from('task_tags')
    .delete()
    .eq('task_id', opts.taskId)
  if (deleteError) throw new Error(deleteError.message)

  if (opts.tagIds.length === 0) return

  const { error: insertError } = await supabase
    .from('task_tags')
    .insert(
      opts.tagIds.map((tagId) => ({ task_id: opts.taskId, tag_id: tagId })),
    )
  if (insertError) throw new Error(insertError.message)
}

/**
 * Bulk-fetch tags for multiple tasks, keyed by task id and sorted by name
 * within each task. Two queries instead of a join — the test fake doesn't
 * support joins, and this codebase's other services favor straightforward
 * sequential queries over relying on PostgREST's embedded-resource syntax.
 */
export async function listTagsForTasks(
  supabase: Client,
  taskIds: string[],
): Promise<Map<string, TagSummary[]>> {
  if (taskIds.length === 0) return new Map()

  const { data: links, error: linksError } = await supabase
    .from('task_tags')
    .select('task_id, tag_id')
    .in('task_id', taskIds)
  if (linksError) throw new Error(linksError.message)

  const tagIds = [...new Set(links.map((link) => link.tag_id))]
  if (tagIds.length === 0) return new Map()

  const { data: tags, error: tagsError } = await supabase
    .from('tags')
    .select('id, name, created_at')
    .in('id', tagIds)
  if (tagsError) throw new Error(tagsError.message)
  const tagsById = new Map(tags.map((tag) => [tag.id, tag]))

  const result = new Map<string, TagSummary[]>()
  for (const link of links) {
    const tag = tagsById.get(link.tag_id)
    if (!tag) continue
    const list = result.get(link.task_id)
    if (list) list.push(tag)
    else result.set(link.task_id, [tag])
  }
  for (const list of result.values()) {
    list.sort((a, b) => a.name.localeCompare(b.name))
  }
  return result
}
