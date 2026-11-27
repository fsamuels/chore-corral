import type { TimeEntrySummary } from '../services/time-entries'
import { sameLabels } from './session-labels'

/**
 * Same running session? A session is identified by id + started_at —
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
 * existing object when the fetch found the same session with the same
 * labels (so anything watching the entry — or keyed on its id — isn't
 * re-triggered by a periodic poll that changed nothing), otherwise the
 * fetched one. Labels are compared so a label added on another device shows
 * up in the dock; a new object with the same id doesn't re-trigger
 * id-keyed watchers.
 */
export function reconcileRunningEntry(
  current: TimeEntrySummary | null,
  fetched: TimeEntrySummary | null,
): TimeEntrySummary | null {
  return isSameRunningEntry(current, fetched) &&
    sameLabels(current?.labels, fetched?.labels)
    ? current
    : fetched
}

/**
 * Latest-request-wins gate over a shared counter. Each fetch of the running
 * entry takes a token with `begin()` and applies its result only if
 * `isLatest(token)` still holds when it lands; `invalidate()` voids every
 * token in flight (a stop that just happened locally). This stops a slow
 * poll that started before a start/stop from landing after it and putting
 * back the stale timer. The counter is passed in so it can live in shared
 * (`useState`) state across every caller.
 */
export function createLatestGate(counter: { value: number }) {
  return {
    begin: (): number => ++counter.value,
    isLatest: (token: number): boolean => token === counter.value,
    invalidate: (): void => {
      counter.value++
    },
  }
}
