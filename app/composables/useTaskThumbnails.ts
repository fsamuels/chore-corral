import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import type { TaskSummary } from '~/services/tasks'
import { createTaskThumbnailStore } from '~/utils/task-thumbnails'

/**
 * Card thumbnails for a page's task list — a thin wrapper that syncs a
 * `createTaskThumbnailStore` (see there for the caching/expiry/fallback
 * rules) whenever the set of photo-bearing tasks or their photo counts
 * changes. Pages pass `thumbnailFor(task)` to `TaskCard`'s `thumbnailUrl`
 * and wire its `thumbnailError` event to `onThumbnailError`.
 *
 * The full compressed photo is loaded even though it's drawn small — see
 * ROADMAP.md for generating dedicated thumbnails at upload time.
 */
export function useTaskThumbnails(
  tasks: Ref<readonly TaskSummary[] | null | undefined>,
) {
  const store = createTaskThumbnailStore(useSupabaseClient<Database>())

  // One derived list drives both the watch key and the sync, so the two
  // can't disagree about which tasks need thumbnails.
  const photoTasks = computed(() =>
    (tasks.value ?? []).filter((task) => task.photo_count > 0),
  )

  // A string key rather than the array itself, so unrelated task edits
  // (title, priority, timer state) don't trigger a sync.
  watch(
    () => photoTasks.value.map((t) => `${t.id}:${t.photo_count}`).join(','),
    () => store.sync(photoTasks.value),
    { immediate: true },
  )

  return {
    thumbnailFor: store.thumbnailFor,
    onThumbnailError: store.reportError,
  }
}
