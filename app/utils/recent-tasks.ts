/** How many chores the home page's "Jump back in" strip shows at most. */
export const JUMP_BACK_IN_LIMIT = 3

/** How far back the strip looks for timer activity. */
export const JUMP_BACK_IN_WINDOW_DAYS = 7

/**
 * Split the home page's (already searched) outstanding tasks into the
 * "Jump back in" strip and everything else. The strip holds up to `limit`
 * tasks from `recentTaskIds`, in that order; ids not in `tasks` (Done, in
 * another farm, filtered out by search) are skipped. Tasks in the strip are
 * left out of `rest`, so a chore never shows twice on the page.
 */
export function splitJumpBackIn<T extends { id: string }>(
  tasks: readonly T[],
  recentTaskIds: readonly string[],
  limit: number = JUMP_BACK_IN_LIMIT,
): { recent: T[]; rest: T[] } {
  const byId = new Map(tasks.map((task) => [task.id, task]))
  const recent: T[] = []
  for (const id of recentTaskIds) {
    if (recent.length >= limit) break
    const task = byId.get(id)
    if (task) recent.push(task)
  }
  const recentIds = new Set(recent.map((task) => task.id))
  return { recent, rest: tasks.filter((task) => !recentIds.has(task.id)) }
}
