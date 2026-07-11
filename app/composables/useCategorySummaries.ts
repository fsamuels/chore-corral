import type { Database } from '~/types/database.types'
import {
  listCategoriesWithCounts,
  type CategorySummaryWithCount,
} from '~/services/categories'

/**
 * Categories for the active farm with usage counts, for the pill/filter-link
 * display on the `/categories` page. Mirrors `useTagSummaries`' shape
 * (loading/error state, re-fetch on farm switch); separate from
 * `useCategories` since that composable's consumers (task create/edit
 * dropdown, the plain CRUD list) don't need counts.
 */
export function useCategorySummaries() {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no categories
  const categories = ref<CategorySummaryWithCount[] | null>(null)
  const categoriesError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchCategories(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      categories.value = null
      return
    }
    loading.value = true
    try {
      categories.value = await listCategoriesWithCounts(supabase, farmId)
      categoriesError.value = null
    } catch (error) {
      categoriesError.value =
        error instanceof Error ? error.message : 'Failed to load categories'
    } finally {
      loading.value = false
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchCategories()
  })

  return {
    categories,
    categoriesError,
    loading,
    fetchCategories,
  }
}
