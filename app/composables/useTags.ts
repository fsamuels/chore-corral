import type { Database } from '~/types/database.types'
import { listTags, type TagSummary } from '~/services/tags'

/**
 * Tags for the active farm (from `useFarms`). Mirrors `useCategories`' shape:
 * plain per-composable state, re-fetched whenever the active farm changes.
 * Read-only — tag creation happens implicitly via task save through
 * `resolveTags`, not directly through this composable.
 */
export function useTags() {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no tags
  const tags = ref<TagSummary[] | null>(null)
  const tagsError = ref<string | null>(null)

  async function fetchTags(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      tags.value = null
      return
    }
    try {
      tags.value = await listTags(supabase, farmId)
      tagsError.value = null
    } catch (error) {
      tagsError.value =
        error instanceof Error ? error.message : 'Failed to load tags'
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchTags()
  })

  return {
    tags,
    tagsError,
    fetchTags,
  }
}
