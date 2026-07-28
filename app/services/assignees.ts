import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

type Client = SupabaseClient<Database>

/**
 * Validate a task's assignee set app-side, the complement to the DB's
 * composite primary key on `task_assignees` (task_id, user_id): no member id
 * can appear twice. Unlike `task_completers`, every assignee is a farm
 * member — no free-text names — so there's no per-entry XOR to check (see
 * docs/ROADMAP.md's chore-assignment entry for why members-only).
 */
export function assertValidAssignees(userIds: string[]): void {
  const seen = new Set<string>()
  for (const userId of userIds) {
    if (seen.has(userId)) {
      throw new Error('A chore cannot list the same assignee twice')
    }
    seen.add(userId)
  }
}

/**
 * Replace a task's full assignee set: delete existing `task_assignees` rows
 * for the task, then bulk-insert the new set — the delete-then-bulk-insert
 * pattern from `setTaskTags`/`setTaskCompleters`. The set is validated (no
 * duplicates) before any write, and the insert is skipped entirely for an
 * empty set ("assigned to nobody" — SPEC: anyone can do it).
 */
export async function setTaskAssignees(
  supabase: Client,
  opts: { taskId: string; userIds: string[] },
): Promise<void> {
  assertValidAssignees(opts.userIds)

  const { error: deleteError } = await supabase
    .from('task_assignees')
    .delete()
    .eq('task_id', opts.taskId)
  if (deleteError) throw new Error(deleteError.message)

  if (opts.userIds.length === 0) return

  const { error: insertError } = await supabase
    .from('task_assignees')
    .insert(
      opts.userIds.map((userId) => ({ task_id: opts.taskId, user_id: userId })),
    )
  if (insertError) throw new Error(insertError.message)
}

/**
 * Bulk-fetch assignee user ids for multiple tasks, keyed by task id and
 * sorted by user id within each task — one query, patterned on
 * `listTagsForTasks`/`listCompletersForTasks`.
 */
export async function listAssigneesForTasks(
  supabase: Client,
  taskIds: string[],
): Promise<Map<string, string[]>> {
  if (taskIds.length === 0) return new Map()

  const { data, error } = await supabase
    .from('task_assignees')
    .select('task_id, user_id')
    .in('task_id', taskIds)
  if (error) throw new Error(error.message)

  const result = new Map<string, string[]>()
  for (const row of data) {
    const list = result.get(row.task_id)
    if (list) list.push(row.user_id)
    else result.set(row.task_id, [row.user_id])
  }
  for (const list of result.values()) list.sort()
  return result
}
