import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import type { TaskSummary } from '~/services/tasks'
import {
  listTimeEntriesForTasks,
  totalTrackedMs,
  type TrackedSpan,
} from '~/services/time-entries'

// A card's figure is minutes-resolution ("1h 30m", "75%"), so a running
// entry only needs re-totalling about once a minute.
const TICK_MS = 60_000

/**
 * Per-task tracked time for a page's task list, behind `TaskCard`'s time
 * indicator. Pages pass `trackedMsFor(task)` to the card's `trackedMs` prop.
 *
 * Refetches when the set of listed task ids changes and when the user's
 * running timer starts or stops anywhere in the app (the shared
 * `useRunningTimer` state), so the card that just stopped shows its new
 * total. While any listed task has a running entry (the user's or another
 * member's), a client-side minute tick keeps the totals counting up.
 *
 * The indicator is supplementary, so a failed fetch keeps the last good
 * totals (or none) rather than surfacing an error on the page.
 */
export function useTaskTrackedTime(
  tasks: Ref<readonly TaskSummary[] | null | undefined>,
) {
  const supabase = useSupabaseClient<Database>()
  const { runningEntry } = useRunningTimer()

  const entriesByTask = shallowRef(new Map<string, TrackedSpan[]>())
  const now = ref(new Date())

  const taskIds = computed(() => (tasks.value ?? []).map((task) => task.id))

  // Latest request wins, so a slow reply for an older id set can't
  // overwrite a newer one.
  let requestSeq = 0
  async function load() {
    // Client-only: the server render would just discard the result (the
    // watch below doesn't block rendering), and both sides then hydrate with
    // no indicator before it fills in.
    if (import.meta.server) return
    const seq = ++requestSeq
    try {
      const result = await listTimeEntriesForTasks(supabase, taskIds.value)
      if (seq !== requestSeq) return
      entriesByTask.value = result
      now.value = new Date()
    } catch {
      // Keep whatever was showing — see the doc comment above.
    }
  }

  // String keys rather than the arrays/objects themselves, so unrelated task
  // edits (title, priority) don't refetch.
  watch(
    () => [taskIds.value.join(','), runningEntry.value?.id ?? ''].join('|'),
    load,
    { immediate: true },
  )

  const hasOpenEntry = computed(() => {
    for (const spans of entriesByTask.value.values()) {
      if (spans.some((span) => span.ended_at === null)) return true
    }
    return false
  })

  let ticker: ReturnType<typeof setInterval> | undefined
  function stopTicker() {
    if (ticker) clearInterval(ticker)
    ticker = undefined
  }
  if (import.meta.client) {
    watch(
      hasOpenEntry,
      (open) => {
        if (open && !ticker) {
          now.value = new Date()
          ticker = setInterval(() => (now.value = new Date()), TICK_MS)
        } else if (!open) {
          stopTicker()
        }
      },
      { immediate: true },
    )
    onScopeDispose(stopTicker)
  }

  function trackedMsFor(task: Pick<TaskSummary, 'id'>): number {
    const spans = entriesByTask.value.get(task.id)
    return spans ? totalTrackedMs(spans, now.value) : 0
  }

  return { trackedMsFor }
}
