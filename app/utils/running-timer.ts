import type { TimeEntrySummary } from '../services/time-entries'

/**
 * Same running session? A time entry is immutable while it runs (only its
 * `ended_at` changes, when it stops), so id + started_at identifies it —
 * started_at is compared too in case an edit moved the start on another
 * device, which the dock's elapsed time must pick up.
 */
export function isSameRunningEntry(
  a: Pick<TimeEntrySummary, 'id' | 'started_at'> | null,
  b: Pick<TimeEntrySummary, 'id' | 'started_at'> | null,
): boolean {
  if (a === null || b === null) return a === b
  return a.id === b.id && a.started_at === b.started_at
}

/**
 * The value the shared running-entry state should hold after a fetch: the
 * existing object when the fetch found the same session (so anything
 * watching the entry — or keyed on its id — isn't re-triggered by a periodic
 * poll that changed nothing), otherwise the fetched one.
 */
export function reconcileRunningEntry(
  current: TimeEntrySummary | null,
  fetched: TimeEntrySummary | null,
): TimeEntrySummary | null {
  return isSameRunningEntry(current, fetched) ? current : fetched
}
