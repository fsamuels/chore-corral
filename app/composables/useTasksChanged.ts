/**
 * A "some chore's status changed outside the page showing the list" signal.
 * The dock bar's Finish flow can mark a chore done while Home is open; Home
 * holds its own `useTasks` list (not shared), so it watches `version` and
 * refetches. Bumped only by flows that change tasks from the layout.
 */
export function useTasksChanged() {
  const version = useState<number>('tasks-changed-version', () => 0)
  function notifyTasksChanged(): void {
    version.value++
  }
  return { version, notifyTasksChanged }
}
