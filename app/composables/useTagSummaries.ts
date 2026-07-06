import type { Database } from '~/types/database.types'
import { listTagsWithCounts, type TagUsageSummary } from '~/services/tags'

/**
 * Tag usage summaries (name + task count) for the active farm, backing the
 * read-only `/tags` page. Mirrors `useCategories`' shape: plain
 * per-composable state, re-fetched whenever the active farm changes.
 * Separate from `useTags` (which only fetches bare `TagSummary[]` for
 * task-tagging autocomplete) since this page needs the extra count query.
 */
export function useTagSummaries() {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no tags
  const tagSummaries = ref<TagUsageSummary[] | null>(null)
  const tagSummariesError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchTagSummaries(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      tagSummaries.value = null
      return
    }
    loading.value = true
    try {
      tagSummaries.value = await listTagsWithCounts(supabase, farmId)
      tagSummariesError.value = null
    } catch (error) {
      tagSummariesError.value =
        error instanceof Error ? error.message : 'Failed to load tags'
    } finally {
      loading.value = false
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchTagSummaries()
  })

  return {
    tagSummaries,
    tagSummariesError,
    loading,
    fetchTagSummaries,
  }
}
