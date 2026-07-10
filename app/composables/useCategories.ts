import type { Database } from '~/types/database.types'
import {
  createCategory,
  deleteCategory,
  listCategories,
  updateCategory,
  type CategorySummary,
  type DeleteCategoryResult,
} from '~/services/categories'

/**
 * Categories for the active farm (from `useFarms`). Unlike `useFarms`' shared
 * session cache, this is plain per-composable state: the categories page is the
 * only consumer, and the list is re-fetched whenever the active farm changes.
 */
export function useCategories() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no categories
  const categories = ref<CategorySummary[] | null>(null)
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
      categories.value = await listCategories(supabase, farmId)
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

  async function create(name: string): Promise<void> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) return
    const created = await createCategory(supabase, {
      farmId,
      name,
      actorUserId,
    })
    const next = [...(categories.value ?? []), created]
    next.sort((a, b) => a.name.localeCompare(b.name))
    categories.value = next
  }

  async function update(categoryId: string, name: string): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) return
    const updated = await updateCategory(supabase, {
      farmId,
      categoryId,
      name,
    })
    const next = (categories.value ?? []).map((category) =>
      category.id === categoryId ? updated : category,
    )
    next.sort((a, b) => a.name.localeCompare(b.name))
    categories.value = next
  }

  async function remove(categoryId: string): Promise<DeleteCategoryResult> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) {
      throw new Error('No active farm or signed-in user')
    }
    const result = await deleteCategory(supabase, {
      farmId,
      categoryId,
      actorUserId,
    })
    if (result.deleted) {
      categories.value =
        categories.value?.filter((category) => category.id !== categoryId) ??
        null
    }
    return result
  }

  return {
    categories,
    categoriesError,
    loading,
    fetchCategories,
    create,
    update,
    remove,
  }
}
