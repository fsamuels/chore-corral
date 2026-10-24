import { createRemovalController, type Removal } from '~/utils/undoable-removal'

/**
 * "Remove, then Undo" for small list items: the item disappears at once, a
 * toast offers Undo for a few seconds, and the real delete only runs when
 * that window closes. Call from a component's setup — it flushes any pending
 * removal on unmount, and as soon as the page is hidden (screen off, app
 * switched, tab closed): phones often suspend JS right after that, so
 * waiting out the timer would leave the delete for whenever the app wakes —
 * or lose it entirely if the OS kills it meanwhile.
 */
export function useUndoableRemove() {
  const { showToast, hideToast } = useToast()

  const controller = createRemovalController({
    onPending: (message, undo) =>
      showToast(message, { action: { label: 'Undo', onClick: undo } }),
    onCommitError: (error, removal) =>
      showToast(
        error instanceof Error && error.message
          ? error.message
          : `${removal.message} — couldn't finish, restored`,
        { tone: 'error' },
      ),
  })

  // Commit now rather than on the timer; the Undo the toast offered no
  // longer does anything, so drop it too.
  function flush(): void {
    if (!controller.hasPending) return
    void controller.flush()
    hideToast()
  }

  // `visibilitychange` is the event mobile browsers reliably fire on screen
  // lock and app switch; `pagehide` covers tab close / navigation away where
  // it doesn't.
  function onVisibilityChange(): void {
    if (document.visibilityState === 'hidden') flush()
  }

  if (import.meta.client) {
    document.addEventListener('visibilitychange', onVisibilityChange)
    window.addEventListener('pagehide', flush)
    onBeforeUnmount(() => {
      document.removeEventListener('visibilitychange', onVisibilityChange)
      window.removeEventListener('pagehide', flush)
      flush()
    })
  }

  function removeWithUndo(removal: Removal): void {
    controller.start(removal)
  }

  return { removeWithUndo }
}
