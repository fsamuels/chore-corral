/**
 * Timing / state machine behind "remove, then offer Undo" (see
 * `useUndoableRemove`). Kept free of Vue and Nuxt so it can be unit-tested
 * with fake timers.
 *
 * Lifecycle of one removal: `hide()` runs immediately, then the removal
 * waits `timeoutMs` for an Undo. Undo calls `restore()` and drops the
 * removal; otherwise the timer (or a flush) calls `commit()`. A failed
 * commit calls `restore()` and reports the error. Only one removal is ever
 * pending: starting a second commits the first immediately.
 */

export const UNDO_TIMEOUT_MS = 5000

export interface Removal {
  /** Take the item out of view right away (local state only). */
  hide: () => void
  /** Put the item back in view (undo, or a failed commit). */
  restore: () => void
  /** The real, destructive call. */
  commit: () => Promise<void>
  /** Toast text, e.g. "Photo deleted". */
  message: string
}

export interface RemovalControllerOptions {
  timeoutMs?: number
  /** Show the Undo affordance for a freshly hidden item. */
  onPending: (message: string, undo: () => void) => void
  /** A commit failed and the item was restored. */
  onCommitError: (error: unknown, removal: Removal) => void
}

export interface RemovalController {
  start: (removal: Removal) => void
  /** Commit the pending removal now, if any. Resolves once it settles. */
  flush: () => Promise<void>
  readonly hasPending: boolean
}

interface Pending {
  removal: Removal
  timer: ReturnType<typeof setTimeout>
}

export function createRemovalController(
  options: RemovalControllerOptions,
): RemovalController {
  const timeoutMs = options.timeoutMs ?? UNDO_TIMEOUT_MS
  let pending: Pending | null = null

  async function settle(entry: Pending): Promise<void> {
    clearTimeout(entry.timer)
    if (pending === entry) pending = null
    try {
      await entry.removal.commit()
    } catch (error) {
      entry.removal.restore()
      options.onCommitError(error, entry.removal)
    }
  }

  function undo(entry: Pending): void {
    // Stale Undo (already committed, or superseded): nothing to bring back.
    if (pending !== entry) return
    clearTimeout(entry.timer)
    pending = null
    entry.removal.restore()
  }

  function start(removal: Removal): void {
    // Fire-and-forget: the new removal must not wait on the old commit.
    if (pending) void settle(pending)
    removal.hide()
    const entry: Pending = {
      removal,
      timer: setTimeout(() => void settle(entry), timeoutMs),
    }
    pending = entry
    options.onPending(removal.message, () => undo(entry))
  }

  return {
    start,
    flush: async () => {
      if (pending) await settle(pending)
    },
    get hasPending() {
      return pending !== null
    },
  }
}
