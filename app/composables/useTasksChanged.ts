/**
 * A "chores changed outside the page showing the list" signal. Flows in the
 * layout can change chores while a list page is open: the dock bar's Finish
 * flow marks a chore done, and the quick-add dialog adds a chore for
 * tomorrow. Home and /tasks hold their own `useTasks` lists (not shared), so
 * they watch these counters and refetch.
 *
 * `version` bumps on every change (the open list may be stale). `doneVersion`
 * bumps only when the Done list may be stale too, so /tasks can keep its
 * "Load more" Done pages when nothing finished.
 */
export function useTasksChanged() {
  const version = useState<number>('tasks-changed-version', () => 0)
  const doneVersion = useState<number>('tasks-changed-done-version', () => 0)
  function notifyTasksChanged(options: { done?: boolean } = {}): void {
    version.value++
    if (options.done ?? true) doneVersion.value++
  }
  return { version, doneVersion, notifyTasksChanged }
}
