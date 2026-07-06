import type { Database } from '~/types/database.types'
import { listTagsWithCounts, type TagSummaryWithCount } from '~/services/tags'

/**
 * Tags for the active farm with usage counts, for the read-only `/tags`
 * page. Mirrors `useCategories`' shape (loading/error state, re-fetch on
 * farm switch); separate from `useTags` since that composable's consumers
 * (task creation/edit autocomplete) don't need counts.
 */
export function useTagSummaries() {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no tags
  const tags = ref<TagSummaryWithCount[] | null>(null)
  const tagsError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchTags(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      tags.value = null
      return
    }
    loading.value = true
    try {
      tags.value = await listTagsWithCounts(supabase, farmId)
      tagsError.value = null
    } catch (error) {
      tagsError.value =
        error instanceof Error ? error.message : 'Failed to load tags'
    } finally {
      loading.value = false
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchTags()
  })

  return {
    tags,
    tagsError,
    loading,
    fetchTags,
  }
}
