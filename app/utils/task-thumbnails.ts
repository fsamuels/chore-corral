import { reactive } from 'vue'
import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.types'
import { getTaskPhotoUrls, listFirstPhotoPaths } from '../services/photos'
import type { TaskSummary } from '../services/tasks'

type ThumbnailTask = Pick<TaskSummary, 'id' | 'photo_count'>

// Signed-URL lifetime, and how close to expiry a cached URL is re-signed
// on the next sync rather than reused.
export const THUMBNAIL_URL_TTL_SECONDS = 3600
const RESIGN_MARGIN_MS = 5 * 60 * 1000

/**
 * Card-thumbnail state for task lists, kept framework-light (plain Vue
 * `reactive`) so it can be unit-tested without Nuxt — `useTaskThumbnails`
 * wraps it for pages.
 *
 * Caches are incremental: a task's first-photo path is looked up once per
 * `id:photo_count` (so "Load more" on /tasks queries only the new page's
 * tasks, and an upload/delete that changes the count re-looks it up), and a
 * path's signed URL is reused until it nears expiry. What a card shows is
 * derived on read from those caches for the tasks currently in the list, so
 * a slow or failed fetch never leaves another fetch's stale map on screen.
 *
 * `thumbnailFor` returns a URL to show; `null` when there's definitively
 * nothing to show (no photos, lookup/sign failed, or the image wouldn't
 * load), so the card falls back to its photo icon; or `undefined` while
 * still loading, so the card shows neither and doesn't flicker icon → image.
 */
export function createTaskThumbnailStore(
  supabase: SupabaseClient<Database>,
  options: { now?: () => number } = {},
) {
  const now = options.now ?? Date.now

  // `${id}:${photo_count}` → first photo's storage path, or null when the
  // view has no row for it (photos deleted since the list loaded).
  const paths = reactive(new Map<string, string | null>())
  // storage path → signed URL and when it expires (epoch ms).
  const urls = reactive(new Map<string, { url: string; expiresAt: number }>())
  // Lookups/signings that failed this round: shown as null (icon fallback)
  // and retried on the next sync.
  const failedKeys = reactive(new Set<string>())
  const failedPaths = reactive(new Set<string>())
  // Keys whose image errored even after a fresh lookup + re-sign: stay null
  // until photo_count changes (which changes the key).
  const brokenKeys = reactive(new Set<string>())
  // Keys that already used their one fresh-lookup retry after an image error.
  const retriedKeys = new Set<string>()

  const pendingKeys = new Set<string>()
  const pendingPaths = new Set<string>()
  let lastTasks: readonly ThumbnailTask[] = []

  function keyOf(task: ThumbnailTask): string {
    return `${task.id}:${task.photo_count}`
  }

  function thumbnailFor(task: ThumbnailTask): string | null | undefined {
    if (task.photo_count <= 0) return null
    const key = keyOf(task)
    if (brokenKeys.has(key) || failedKeys.has(key)) return null
    const path = paths.get(key)
    if (path === undefined) return undefined
    if (path === null || failedPaths.has(path)) return null
    return urls.get(path)?.url
  }

  /** Bring caches up to date for `tasks`, fetching only what's missing. */
  async function sync(tasks: readonly ThumbnailTask[]): Promise<void> {
    lastTasks = tasks
    const photoTasks = tasks.filter((task) => task.photo_count > 0)

    const lookups = photoTasks.filter((task) => {
      const key = keyOf(task)
      return !paths.has(key) && !pendingKeys.has(key) && !brokenKeys.has(key)
    })
    if (lookups.length > 0) {
      const keys = lookups.map(keyOf)
      for (const key of keys) pendingKeys.add(key)
      try {
        const found = await listFirstPhotoPaths(
          supabase,
          lookups.map((task) => task.id),
        )
        lookups.forEach((task, i) => {
          paths.set(keys[i]!, found.get(task.id) ?? null)
          failedKeys.delete(keys[i]!)
        })
      } catch {
        for (const key of keys) failedKeys.add(key)
      } finally {
        for (const key of keys) pendingKeys.delete(key)
      }
    }

    const signAfter = now() + RESIGN_MARGIN_MS
    const toSign = new Set<string>()
    for (const task of photoTasks) {
      const path = paths.get(keyOf(task))
      if (!path || pendingPaths.has(path)) continue
      const cached = urls.get(path)
      if (!cached || cached.expiresAt <= signAfter) toSign.add(path)
    }
    if (toSign.size === 0) return

    const signing = [...toSign]
    for (const path of signing) pendingPaths.add(path)
    const requestedAt = now()
    try {
      const signed = await getTaskPhotoUrls(
        supabase,
        signing,
        THUMBNAIL_URL_TTL_SECONDS,
      )
      const expiresAt = requestedAt + THUMBNAIL_URL_TTL_SECONDS * 1000
      for (const path of signing) {
        const url = signed.get(path)
        if (url) {
          urls.set(path, { url, expiresAt })
          failedPaths.delete(path)
        } else {
          failedPaths.add(path)
        }
      }
    } catch {
      for (const path of signing) failedPaths.add(path)
    } finally {
      for (const path of signing) pendingPaths.delete(path)
    }
  }

  /**
   * A card's `<img>` failed to load: the URL expired (page left open past
   * the TTL), or the photo was deleted/replaced since its path was cached.
   * An expired URL is just re-signed (it doesn't count as a failure, so a
   * page left open for hours keeps working). Otherwise, the first time,
   * drop the cached path and URL and re-run the lookup + signing; if the
   * fresh one fails too, give up on this key so the card shows its photo
   * icon instead of retrying forever.
   */
  async function reportError(task: ThumbnailTask): Promise<void> {
    const key = keyOf(task)
    const path = paths.get(key)
    const cached = path ? urls.get(path) : undefined
    if (path) urls.delete(path)
    if (cached && cached.expiresAt <= now()) {
      await sync(lastTasks)
      return
    }
    if (retriedKeys.has(key)) {
      brokenKeys.add(key)
      return
    }
    retriedKeys.add(key)
    paths.delete(key)
    await sync(lastTasks)
  }

  return { thumbnailFor, sync, reportError }
}
