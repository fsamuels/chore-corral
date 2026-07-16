import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

type Client = SupabaseClient<Database>

/**
 * One entry in a task's completer set: EITHER a completing member (`user_id`,
 * an `auth.users` id) OR a free-text name (`completer_name`) for someone who
 * isn't an app user — never both, never neither. The row's own `id` isn't
 * carried here; callers identify a completer by its member id or name.
 */
export interface TaskCompleter {
  user_id: string | null
  completer_name: string | null
}

/**
 * Validate a task's completer set app-side, the complement to the DB's per-row
 * XOR CHECK and the two partial unique indexes on `task_completers`:
 *
 * - Per-entry XOR: exactly one of `user_id` / `completer_name` is set on each
 *   entry (mirrors the old `assertCompletedByXorName`, applied per row now).
 * - No duplicates: the same member id can't appear twice, nor the same
 *   free-text name — the app-layer complement to the partial unique indexes, so
 *   a duplicate fails with a readable message before Postgres does.
 *
 * Mixing members and free-text names within one set is allowed; only the
 * per-entry rule and duplicate rule are enforced.
 */
export function assertValidCompleters(completers: TaskCompleter[]): void {
  const seenUsers = new Set<string>()
  const seenNames = new Set<string>()
  for (const completer of completers) {
    const hasUser = completer.user_id !== null
    const hasName = completer.completer_name !== null
    if (hasUser === hasName) {
      throw new Error(
        'A completer is either a member or a free-text name, not both',
      )
    }
    if (hasUser) {
      if (seenUsers.has(completer.user_id!)) {
        throw new Error('A chore cannot list the same completer twice')
      }
      seenUsers.add(completer.user_id!)
    } else {
      if (seenNames.has(completer.completer_name!)) {
        throw new Error('A chore cannot list the same completer twice')
      }
      seenNames.add(completer.completer_name!)
    }
  }
}

// Deterministic display order: members first (by id), then free-text names (by
// name). Keeps the comma-joined attribution stable across renders without
// needing emails at this layer.
function compareCompleters(a: TaskCompleter, b: TaskCompleter): number {
  if (a.user_id !== null && b.user_id !== null) {
    return a.user_id.localeCompare(b.user_id)
  }
  if (a.user_id !== null) return -1
  if (b.user_id !== null) return 1
  return (a.completer_name ?? '').localeCompare(b.completer_name ?? '')
}

/**
 * Replace a task's full completer set: delete existing `task_completers` rows
 * for the task, then bulk-insert the new set — the delete-then-bulk-insert
 * pattern from `setTaskTags`. Free-text names are trimmed and empty ones
 * dropped; the set is validated (per-entry XOR, no duplicates) before any
 * write, and the insert is skipped entirely for an empty set (both because
 * there's nothing to write and to avoid an insert-of-empty-array call).
 */
export async function setTaskCompleters(
  supabase: Client,
  opts: { taskId: string; completers: TaskCompleter[] },
): Promise<void> {
  const normalized = opts.completers
    .map((completer) =>
      completer.user_id !== null
        ? { user_id: completer.user_id, completer_name: null }
        : {
            user_id: null,
            completer_name: (completer.completer_name ?? '').trim() || null,
          },
    )
    .filter(
      (completer) =>
        completer.user_id !== null || completer.completer_name !== null,
    )

  assertValidCompleters(normalized)

  const { error: deleteError } = await supabase
    .from('task_completers')
    .delete()
    .eq('task_id', opts.taskId)
  if (deleteError) throw new Error(deleteError.message)

  if (normalized.length === 0) return

  const { error: insertError } = await supabase.from('task_completers').insert(
    normalized.map((completer) => ({
      task_id: opts.taskId,
      user_id: completer.user_id,
      completer_name: completer.completer_name,
    })),
  )
  if (insertError) throw new Error(insertError.message)
}

/**
 * Bulk-fetch completers for multiple tasks, keyed by task id and sorted within
 * each task (members first, then names). One query, patterned on
 * `listTagsForTasks` — the test fake doesn't support joins, and this codebase
 * favors straightforward `.in()` queries over PostgREST embedded resources.
 */
export async function listCompletersForTasks(
  supabase: Client,
  taskIds: string[],
): Promise<Map<string, TaskCompleter[]>> {
  if (taskIds.length === 0) return new Map()

  const { data, error } = await supabase
    .from('task_completers')
    .select('task_id, user_id, completer_name')
    .in('task_id', taskIds)
  if (error) throw new Error(error.message)

  const result = new Map<string, TaskCompleter[]>()
  for (const row of data) {
    const completer: TaskCompleter = {
      user_id: row.user_id,
      completer_name: row.completer_name,
    }
    const list = result.get(row.task_id)
    if (list) list.push(completer)
    else result.set(row.task_id, [completer])
  }
  for (const list of result.values()) list.sort(compareCompleters)
  return result
}
