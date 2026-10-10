import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import type { TaskSummary } from '~/services/tasks'
import { getTaskPhotoUrls, listFirstPhotoPaths } from '~/services/photos'

/**
 * Card thumbnails for a list of tasks: a signed URL for each task's first
 * photo, keyed by task id. Watches the list and refetches when the set of
 * photo-bearing tasks changes. Only tasks with `photo_count > 0` are queried,
 * and all their paths are signed in one batched storage request.
 *
 * Signed URLs are cached by storage path for the page's lifetime, so a list
 * refetch (e.g. after a timer toggle) doesn't re-sign photos already shown —
 * and the `<img>` src stays stable, so the browser doesn't reload them.
 *
 * Thumbnails are best-effort decoration: a failure leaves the cards without
 * images rather than surfacing an error.
 *
 * The full compressed photo is loaded even though it's drawn small — see
 * ROADMAP.md for generating dedicated thumbnails at upload time.
 */
export function useTaskThumbnails(
  tasks: Ref<readonly TaskSummary[] | null | undefined>,
) {
  const supabase = useSupabaseClient<Database>()

  const thumbnailUrls = ref<Map<string, string>>(new Map())
  const signedUrlsByPath = new Map<string, string>()

  // Watch a stable string key rather than the array itself so unrelated
  // task edits (title, priority, timer state) don't trigger a refetch.
  const photoTaskKey = computed(() =>
    (tasks.value ?? [])
      .filter((task) => task.photo_count > 0)
      .map((task) => `${task.id}:${task.photo_count}`)
      .sort()
      .join(','),
  )

  // Guards against an older, slower fetch overwriting a newer one's result.
  let requestId = 0

  async function fetchThumbnails(): Promise<void> {
    const current = ++requestId
    const taskIds = (tasks.value ?? [])
      .filter((task) => task.photo_count > 0)
      .map((task) => task.id)
    if (taskIds.length === 0) {
      thumbnailUrls.value = new Map()
      return
    }
    try {
      const pathsByTask = await listFirstPhotoPaths(supabase, taskIds)
      const unsigned = [...new Set(pathsByTask.values())].filter(
        (path) => !signedUrlsByPath.has(path),
      )
      const fresh = await getTaskPhotoUrls(supabase, unsigned)
      for (const [path, url] of fresh) signedUrlsByPath.set(path, url)
      if (current !== requestId) return

      const next = new Map<string, string>()
      for (const [taskId, path] of pathsByTask) {
        const url = signedUrlsByPath.get(path)
        if (url) next.set(taskId, url)
      }
      thumbnailUrls.value = next
    } catch {
      // Best-effort: keep whatever thumbnails were already showing.
    }
  }

  watch(photoTaskKey, () => fetchThumbnails(), { immediate: true })

  return { thumbnailUrls }
}
