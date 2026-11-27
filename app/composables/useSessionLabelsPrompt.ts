import type { Database } from '~/types/database.types'
import {
  listTimeEntries,
  updateTimeEntryLabels,
  type TimeEntrySummary,
} from '~/services/time-entries'
import { canonicalizeLabels, labelSuggestions } from '~/utils/session-labels'

export type SessionLabelsMode = 'stop' | 'edit'

// Settles the promise handed to whoever opened the dialog. Module-level
// rather than `useState` because a function can't be serialized; the
// dialog only ever opens in the browser, so it's never shared across
// server requests.
let settle: ((done: boolean) => void) | null = null

/**
 * The one session-labels dialog, rendered from the default layout
 * (`SessionLabelsDialog.vue`) and opened from anywhere:
 *
 * - `requestStop()` — the stop prompt. Every Stop button (dock bar, chore
 *   page, Home card) goes through it, so you can label the session as you
 *   end it. Confirming stops the timer and saves the labels in one update.
 * - `requestLabels(entry)` — add or change one session's labels, running
 *   (the dock's label button) or finished (the chore page's sessions list).
 *
 * Both resolve once the dialog closes: true if the stop or save happened,
 * false on Cancel. Suggestions are the chore's earlier labels, loaded when
 * the dialog opens; a failed load just means no suggestions.
 */
export function useSessionLabelsPrompt() {
  const supabase = useSupabaseClient<Database>()
  const running = useRunningTimer()

  const open = useState('session-labels-open', () => false)
  const mode = useState<SessionLabelsMode>('session-labels-mode', () => 'edit')
  const entry = useState<TimeEntrySummary | null>(
    'session-labels-entry',
    () => null,
  )
  const suggestions = useState<string[]>('session-labels-suggestions', () => [])
  const busy = useState('session-labels-busy', () => false)
  const error = useState<string | null>('session-labels-error', () => null)

  let loadSeq = 0
  async function loadSuggestions(taskId: string): Promise<void> {
    const seq = ++loadSeq
    suggestions.value = []
    try {
      const entries = await listTimeEntries(supabase, taskId)
      if (seq === loadSeq) suggestions.value = labelSuggestions(entries)
    } catch {
      // Suggestions are a convenience; typing a label still works.
    }
  }

  function begin(
    target: TimeEntrySummary,
    nextMode: SessionLabelsMode,
  ): Promise<boolean> {
    settle?.(false)
    entry.value = target
    mode.value = nextMode
    error.value = null
    busy.value = false
    open.value = true
    void loadSuggestions(target.task_id)
    return new Promise((resolve) => {
      settle = resolve
    })
  }

  function finish(done: boolean): void {
    open.value = false
    const resolve = settle
    settle = null
    resolve?.(done)
  }

  /** Ask for labels, then stop the running timer. False if none runs. */
  function requestStop(): Promise<boolean> {
    const current = running.runningEntry.value
    if (!current) return Promise.resolve(false)
    return begin(current, 'stop')
  }

  /** Add or change the labels on one session. */
  function requestLabels(target: TimeEntrySummary): Promise<boolean> {
    return begin(target, 'edit')
  }

  async function confirm(labels: readonly string[]): Promise<void> {
    const target = entry.value
    if (!target || busy.value) return
    const cleaned = canonicalizeLabels(labels, suggestions.value)
    busy.value = true
    error.value = null
    try {
      if (mode.value === 'stop') {
        // The dock's stop resyncs rather than throwing when the timer was
        // already stopped elsewhere; either way it isn't running any more.
        await running.stop(cleaned)
        if (running.runningEntry.value?.id === target.id) {
          error.value = 'Couldn’t stop the timer. Try again.'
          return
        }
      } else if (running.runningEntry.value?.id === target.id) {
        await running.setLabels(cleaned)
      } else {
        await updateTimeEntryLabels(supabase, {
          entryId: target.id,
          labels: cleaned,
        })
      }
      finish(true)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to save labels'
    } finally {
      busy.value = false
    }
  }

  function cancel(): void {
    if (busy.value) return
    finish(false)
  }

  return {
    open,
    mode,
    entry,
    suggestions,
    busy,
    error,
    requestStop,
    requestLabels,
    confirm,
    cancel,
  }
}
