import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import {
  addShoppingItem,
  listShoppingItems,
  removeShoppingItem,
  renameShoppingItem,
  setShoppingItemChecked,
  type ShoppingItemSummary,
} from '~/services/shopping'

/**
 * Shopping list for a single task. Like `useTaskPhotos` (and unlike the
 * per-farm composables), this is keyed on a *task*, so it watches the passed
 * task id ref and refetches whenever it changes — including clearing to the
 * "not fetched" state when the id goes null.
 */
export function useTaskShoppingList(taskId: Ref<string | null | undefined>) {
  const supabase = useSupabaseClient<Database>()

  // null = not fetched yet; [] = fetched, task has no items.
  const items = ref<ShoppingItemSummary[] | null>(null)
  const itemsError = ref<string | null>(null)
  const loading = ref(false)

  const adding = ref(false)
  // Single surface for write-action failures (add/toggle/rename/remove),
  // shown inline by the component near the add field.
  const mutationError = ref<string | null>(null)

  async function fetchItems(): Promise<void> {
    const id = taskId.value
    if (!id) {
      items.value = null
      itemsError.value = null
      return
    }
    loading.value = true
    try {
      const list = await listShoppingItems(supabase, id)
      // A slower fetch for a task that's no longer open must not overwrite
      // the current task's list (the watcher has already kicked off a fresh
      // fetch that owns the state now).
      if (taskId.value !== id) return
      items.value = list
      itemsError.value = null
    } catch (error) {
      if (taskId.value !== id) return
      itemsError.value =
        error instanceof Error ? error.message : 'Failed to load shopping list'
    } finally {
      if (taskId.value === id) loading.value = false
    }
  }

  // Refetch whenever the open task changes (and on initial mount).
  watch(taskId, () => fetchItems(), { immediate: true })

  async function add(name: string): Promise<void> {
    mutationError.value = null
    const id = taskId.value
    if (!id) {
      mutationError.value = 'No active task'
      return
    }
    adding.value = true
    try {
      const item = await addShoppingItem(supabase, { taskId: id, name })
      // Same staleness guard as fetchItems: don't append to another task's
      // list if the open task changed while the insert was in flight.
      if (taskId.value === id) items.value = [...(items.value ?? []), item]
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to add item'
    } finally {
      adding.value = false
    }
  }

  // Safe across task switches: if the open task changed mid-flight, the
  // updated id is no longer in the list and the map is a no-op.
  function replaceItem(updated: ShoppingItemSummary): void {
    items.value =
      items.value?.map((i) => (i.id === updated.id ? updated : i)) ?? null
  }

  async function toggle(item: ShoppingItemSummary): Promise<void> {
    mutationError.value = null
    try {
      replaceItem(
        await setShoppingItemChecked(supabase, {
          itemId: item.id,
          checked: !item.checked,
        }),
      )
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to update item'
    }
  }

  async function rename(
    item: ShoppingItemSummary,
    name: string,
  ): Promise<void> {
    mutationError.value = null
    try {
      replaceItem(await renameShoppingItem(supabase, { itemId: item.id, name }))
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to rename item'
    }
  }

  async function remove(item: ShoppingItemSummary): Promise<void> {
    mutationError.value = null
    try {
      await removeShoppingItem(supabase, item.id)
      items.value = items.value?.filter((i) => i.id !== item.id) ?? null
    } catch (error) {
      mutationError.value =
        error instanceof Error ? error.message : 'Failed to remove item'
    }
  }

  return {
    items,
    itemsError,
    loading,
    adding,
    mutationError,
    fetchItems,
    add,
    toggle,
    rename,
    remove,
  }
}
