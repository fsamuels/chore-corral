import type { Database } from '~/types/database.types'
import {
  listRecentTimeEntriesForUser,
  recentTaskIdsFromEntries,
} from '~/services/time-entries'
import { JUMP_BACK_IN_WINDOW_DAYS } from '~/utils/recent-tasks'

const DAY_MS = 24 * 60 * 60 * 1000

/**
 * Ids of the chores the signed-in user has timed in the last
 * `JUMP_BACK_IN_WINDOW_DAYS` days, most recently worked on first (see
 * `recentTaskIdsFromEntries`) — the source for the home page's "Jump back
 * in" strip. Ids span every farm; the page intersects them with its list.
 *
 * Reloads when the user's running timer starts, stops or switches anywhere
 * in the app (the shared `useRunningTimer` state). Client-only and
 * supplementary: a failed load keeps the last good ids (or none), so the
 * page falls back to its plain Up next / Backlog groups.
 */
export function useRecentTimedTaskIds() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { runningEntry } = useRunningTimer()

  const recentTaskIds = ref<string[]>([])

  let requestSeq = 0
  async function load() {
    if (import.meta.server) return
    const seq = ++requestSeq
    const actorUserId = getActorUserId(user.value)
    if (!actorUserId) {
      recentTaskIds.value = []
      return
    }
    try {
      const since = new Date(
        Date.now() - JUMP_BACK_IN_WINDOW_DAYS * DAY_MS,
      ).toISOString()
      const entries = await listRecentTimeEntriesForUser(
        supabase,
        actorUserId,
        { since },
      )
      if (seq !== requestSeq) return
      // A timer started before the window but still running is still the
      // chore being worked on right now.
      const running = runningEntry.value
      if (running && !entries.some((entry) => entry.id === running.id)) {
        entries.push(running)
      }
      recentTaskIds.value = recentTaskIdsFromEntries(entries)
    } catch {
      // Keep whatever was showing — see the doc comment above.
    }
  }

  watch(() => runningEntry.value?.id ?? null, load, { immediate: true })

  return { recentTaskIds, reload: load }
}
