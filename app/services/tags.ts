import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface TagSummary {
  id: string
  name: string
  created_at: string
}

export interface TagUsageSummary extends TagSummary {
  taskCount: number
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
 * Normalize a tag name to this app's stored convention: lowercase, trimmed,
 * with internal whitespace collapsed to single spaces (so "Fence   Repair"
 * and "fence repair" are the same tag, not just case-insensitively equal).
 */
function normalizeTagName(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, ' ')
}

/**
 * Resolve freeform tag name input into `tags` rows, creating any that don't
 * exist yet for the farm. Names are normalized (trimmed, lowercased, internal
 * whitespace collapsed) before matching or creating, so "Fence", "fence ",
 * and "fence  " all resolve to the same stored `fence` row. Postgres `text`
 * comparison is case-sensitive, so `.in('name', [...])` can't be relied on
 * for a case-insensitive match; instead this fetches all of the farm's tags
 * and matches in JS.
 */
export async function resolveTags(
  supabase: Client,
  opts: { farmId: string; names: string[] },
): Promise<TagSummary[]> {
  const uniqueNames = [
    ...new Set(opts.names.map(normalizeTagName).filter(Boolean)),
  ]
  if (uniqueNames.length === 0) return []

  const existing = await listTags(supabase, opts.farmId)
  const existingByKey = new Map(
    existing.map((tag) => [normalizeTagName(tag.name), tag]),
  )

  const namesToCreate = uniqueNames.filter((name) => !existingByKey.has(name))

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
    created.map((tag) => [normalizeTagName(tag.name), tag]),
  )

  return uniqueNames.map((key) => {
    const tag = existingByKey.get(key) ?? createdByKey.get(key)
    if (!tag) throw new Error(`Failed to resolve tag "${key}"`)
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

/**
 * All of a farm's tags with a usage count (how many tasks carry each tag),
 * sorted by name. Two queries instead of a join, mirroring
 * `listTagsForTasks`: fetch the farm's tags, then the `task_tags` rows for
 * those tag ids (already farm-scoped since the tags themselves are), and
 * count occurrences per tag id in JS.
 */
export async function listTagsWithCounts(
  supabase: Client,
  farmId: string,
): Promise<TagUsageSummary[]> {
  const tags = await listTags(supabase, farmId)
  if (tags.length === 0) return []

  const tagIds = tags.map((tag) => tag.id)
  const { data: links, error: linksError } = await supabase
    .from('task_tags')
    .select('tag_id')
    .in('tag_id', tagIds)
  if (linksError) throw new Error(linksError.message)

  const countByTagId = new Map<string, number>()
  for (const link of links) {
    countByTagId.set(link.tag_id, (countByTagId.get(link.tag_id) ?? 0) + 1)
  }

  return tags.map((tag) => ({
    ...tag,
    taskCount: countByTagId.get(tag.id) ?? 0,
  }))
}
