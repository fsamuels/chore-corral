import type { CatalogEmoji, EmojiGroup } from '~/utils/emoji-catalog'
import { groupCatalog, loadEmojiCatalog } from '~/utils/emoji-catalog'

/**
 * Reactive wrapper over the lazily loaded emoji catalog. Call `ensureLoaded`
 * when the picker first opens; the underlying dataset is fetched once and
 * cached module-level, so repeat opens resolve instantly. Loading and error
 * flags drive the dialog's spinner / offline message.
 */
export function useEmojiCatalog() {
  const catalog = ref<CatalogEmoji[]>([])
  const groups = ref<EmojiGroup[]>([])
  const loading = ref(false)
  const error = ref(false)
  const loaded = ref(false)

  async function ensureLoaded(): Promise<void> {
    if (loaded.value || loading.value) return
    loading.value = true
    error.value = false
    try {
      const data = await loadEmojiCatalog()
      catalog.value = data
      groups.value = groupCatalog(data)
      loaded.value = true
    } catch {
      // Import failed (offline / chunk load error). Surfaced to the user; a
      // later open retries since the module cache was cleared on failure.
      error.value = true
    } finally {
      loading.value = false
    }
  }

  return { catalog, groups, loading, error, loaded, ensureLoaded }
}
