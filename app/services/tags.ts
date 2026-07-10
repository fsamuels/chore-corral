import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import type { TaskStatus } from './tasks'

export interface TagSummary {
  id: string
  name: string
  created_at: string
}

/** All progress statuses, in the order the tags page renders their counts. */
export const TASK_STATUSES = ['not_started', 'in_progress', 'done'] as const

function emptyStatusCounts(): Record<TaskStatus, number> {
  return { not_started: 0, in_progress: 0, done: 0 }
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
 * Normalize a tag name to this app's storage convention: trimmed, internal
 * whitespace collapsed to single spaces, lowercased (see docs/DECISIONS.md's
 * tag-naming-convention entry — "fence repair", not "Fence Repair" or
 * "fence-repair").
 */
function normalizeTagName(name: string): string {
  return name.trim().replace(/\s+/g, ' ').toLowerCase()
}

/**
 * Resolve freeform tag name input into `tags` rows, creating any that don't
 * exist yet for the farm. Names are normalized (see `normalizeTagName`)
 * before matching/creating and deduped on the normalized form, so "Fence",
 * "fence", and "Fence   Repair"/"fence repair" all resolve to the same
 * stored tag, itself saved in normalized form. Postgres `text` comparison
 * doesn't do this normalization, so `.in('name', [...])` can't be relied on;
 * instead this fetches all of the farm's tags and matches normalized names
 * in JS (also tolerates any pre-normalization legacy rows still present).
 */
export async function resolveTags(
  supabase: Client,
  opts: { farmId: string; names: string[] },
): Promise<TagSummary[]> {
  const normalizedNames = opts.names.map(normalizeTagName).filter(Boolean)
  if (normalizedNames.length === 0) return []

  const uniqueNames = [...new Set(normalizedNames)]

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

  return uniqueNames.map((name) => {
    const tag = existingByKey.get(name) ?? createdByKey.get(name)
    if (!tag) throw new Error(`Failed to resolve tag "${name}"`)
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

export interface TagSummaryWithCount extends TagSummary {
  taskCount: number
  /** How many of the tagged tasks sit in each progress status. */
  statusCounts: Record<TaskStatus, number>
}

/**
 * The farm's tags (per `listTags`, alphabetical) alongside each one's usage
 * count — the number of tasks currently carrying it — broken down by progress
 * status. Three sequential queries instead of joins, matching
 * `listTagsForTasks`'s style: fetch the tags, their `task_tags` links, then
 * the linked tasks' statuses. No farm scoping is needed on the `task_tags`
 * fetch since tag ids are already farm-scoped via `tags`, and the status fetch
 * is scoped by the linked task ids. `taskCount` is the sum of the status
 * counts, so a `task_tags` row pointing at a task the caller can't see (RLS,
 * or an in-flight delete) contributes to neither.
 */
export async function listTagsWithCounts(
  supabase: Client,
  farmId: string,
): Promise<TagSummaryWithCount[]> {
  const tags = await listTags(supabase, farmId)
  if (tags.length === 0) return []

  const tagIds = tags.map((tag) => tag.id)
  const { data: links, error } = await supabase
    .from('task_tags')
    .select('tag_id, task_id')
    .in('tag_id', tagIds)
  if (error) throw new Error(error.message)

  const taskIds = [...new Set(links.map((link) => link.task_id))]
  const statusByTaskId = new Map<string, TaskStatus>()
  if (taskIds.length > 0) {
    const { data: taskRows, error: taskError } = await supabase
      .from('tasks')
      .select('id, status')
      .in('id', taskIds)
    if (taskError) throw new Error(taskError.message)
    for (const row of taskRows) statusByTaskId.set(row.id, row.status)
  }

  const countsByTag = new Map<string, Record<TaskStatus, number>>()
  for (const link of links) {
    const status = statusByTaskId.get(link.task_id)
    if (!status) continue
    let counts = countsByTag.get(link.tag_id)
    if (!counts) {
      counts = emptyStatusCounts()
      countsByTag.set(link.tag_id, counts)
    }
    counts[status] += 1
  }

  return tags.map((tag) => {
    const statusCounts = countsByTag.get(tag.id) ?? emptyStatusCounts()
    const taskCount =
      statusCounts.not_started + statusCounts.in_progress + statusCounts.done
    return { ...tag, taskCount, statusCounts }
  })
}
