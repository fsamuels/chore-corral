<script setup lang="ts">
import type { ShoppingItemSummary } from '~/services/shopping'

// Only rendered once a task exists (parents guard with v-if="task"), so a
// task id is always present.
const props = defineProps<{ taskId: string }>()

const {
  items,
  itemsError,
  loading,
  adding,
  mutationError,
  add,
  toggle,
  rename,
  remove,
} = useTaskShoppingList(toRef(props, 'taskId'))

const newItemName = ref('')

async function onAdd(): Promise<void> {
  const name = newItemName.value.trim()
  if (!name) return
  await add(name)
  if (!mutationError.value) newItemName.value = ''
}

// Name drafts are edited locally and committed on blur, seeded from each
// item as it appears (same pattern as TaskPhotos captions).
const drafts = reactive<Record<string, string>>({})
watch(
  items,
  (list) => {
    if (!list) return
    for (const item of list) {
      if (!(item.id in drafts)) drafts[item.id] = item.name
    }
  },
  { immediate: true },
)

async function onNameBlur(item: ShoppingItemSummary): Promise<void> {
  const draft = (drafts[item.id] ?? '').trim()
  if (!draft) {
    // An item can't be renamed to nothing — reset instead (delete is the
    // explicit way to remove an item).
    drafts[item.id] = item.name
    return
  }
  // The items watcher never overwrites an existing draft, so the field's
  // display state has to be kept in sync here: normalize to the trimmed
  // value (what actually gets stored) up front, and revert to the last
  // saved name if the rename fails rather than showing an unsaved edit.
  drafts[item.id] = draft
  if (draft === item.name) return
  await rename(item, draft)
  if (mutationError.value) drafts[item.id] = item.name
}

// Per-item in-flight tracking so only the affected row's controls disable.
const pendingIds = ref<Set<string>>(new Set())

async function withPending(
  item: ShoppingItemSummary,
  action: () => Promise<void>,
): Promise<void> {
  const next = new Set(pendingIds.value)
  next.add(item.id)
  pendingIds.value = next
  try {
    await action()
  } finally {
    const done = new Set(pendingIds.value)
    done.delete(item.id)
    pendingIds.value = done
  }
}

function onToggle(item: ShoppingItemSummary): void {
  withPending(item, () => toggle(item))
}

function onRemove(item: ShoppingItemSummary): void {
  withPending(item, () => remove(item))
}
</script>

<template>
  <div>
    <p class="text-body-2 mb-2">Shopping list</p>

    <v-alert
      v-if="itemsError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ itemsError }}
    </v-alert>

    <v-alert
      v-if="mutationError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ mutationError }}
    </v-alert>

    <div v-if="items === null && loading" class="py-2">
      <v-progress-circular indeterminate size="24" color="primary" />
    </div>

    <p
      v-else-if="items && items.length === 0"
      class="text-body-2 text-medium-emphasis"
    >
      No items yet.
    </p>

    <div v-else-if="items">
      <div
        v-for="item in items"
        :key="item.id"
        class="d-flex align-center ga-1"
      >
        <v-checkbox-btn
          :model-value="item.checked"
          :disabled="pendingIds.has(item.id)"
          :aria-label="`Mark ${item.name} as ${item.checked ? 'not bought' : 'bought'}`"
          density="compact"
          class="flex-grow-0"
          @update:model-value="onToggle(item)"
        />
        <v-text-field
          v-model="drafts[item.id]"
          density="compact"
          variant="underlined"
          hide-details
          class="flex-grow-1"
          :class="{
            'text-medium-emphasis text-decoration-line-through': item.checked,
          }"
          @blur="onNameBlur(item)"
          @keydown.enter.prevent="($event.target as HTMLInputElement).blur()"
        />
        <v-btn
          icon="mdi-close"
          size="x-small"
          variant="text"
          :loading="pendingIds.has(item.id)"
          :disabled="pendingIds.has(item.id)"
          aria-label="Remove item"
          title="Remove item"
          @click="onRemove(item)"
        />
      </div>
    </div>

    <div class="d-flex align-center ga-2 mt-2">
      <v-text-field
        v-model="newItemName"
        placeholder="Add an item to buy"
        density="compact"
        variant="outlined"
        hide-details
        :disabled="adding"
        @keydown.enter.prevent="onAdd"
      />
      <v-btn
        size="small"
        variant="tonal"
        prepend-icon="mdi-cart-plus"
        :loading="adding"
        :disabled="adding || !newItemName.trim()"
        @click="onAdd"
      >
        Add
      </v-btn>
    </div>
  </div>
</template>
