import { createRemovalController, type Removal } from '~/utils/undoable-removal'

/**
 * "Remove, then Undo" for small list items: the item disappears at once, a
 * toast offers Undo for a few seconds, and the real delete only runs when
 * that window closes. Call from a component's setup — it flushes any pending
 * removal on unmount and on page unload (best effort).
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

  function flush(): void {
    void controller.flush()
  }

  if (import.meta.client) {
    window.addEventListener('beforeunload', flush)
    onBeforeUnmount(() => {
      window.removeEventListener('beforeunload', flush)
      if (controller.hasPending) {
        flush()
        // The Undo it offered no longer does anything.
        hideToast()
      }
    })
  }

  function removeWithUndo(removal: Removal): void {
    controller.start(removal)
  }

  return { removeWithUndo }
}
