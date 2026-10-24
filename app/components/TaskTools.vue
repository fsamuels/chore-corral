<script setup lang="ts">
import type { ToolItemSummary } from '~/services/tools'

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
} = useTaskTools(toRef(props, 'taskId'))

const newItemName = ref('')

async function onAdd(): Promise<void> {
  const name = newItemName.value.trim()
  if (!name) return
  await add(name)
  if (!mutationError.value) newItemName.value = ''
}

// Name drafts are edited locally and committed on blur, seeded from each
// item as it appears (same pattern as TaskShoppingList).
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

async function onNameBlur(item: ToolItemSummary): Promise<void> {
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
  item: ToolItemSummary,
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

function onToggle(item: ToolItemSummary): void {
  withPending(item, () => toggle(item))
}

// Removal is undoable: the row is hidden right away and the real delete only
// runs once the Undo toast times out. `remove` reports failure via
// `mutationError` rather than throwing, so surface that as a failed commit
// (which restores the row).
const hiddenIds = ref<Set<string>>(new Set())
const visibleItems = computed(
  () => items.value?.filter((i) => !hiddenIds.value.has(i.id)) ?? null,
)

function setHidden(id: string, hidden: boolean): void {
  const next = new Set(hiddenIds.value)
  if (hidden) next.add(id)
  else next.delete(id)
  hiddenIds.value = next
}

const { removeWithUndo } = useUndoableRemove()

function onRemove(item: ToolItemSummary): void {
  removeWithUndo({
    hide: () => setHidden(item.id, true),
    restore: () => setHidden(item.id, false),
    commit: async () => {
      await remove(item)
      if (mutationError.value) throw new Error(mutationError.value)
      setHidden(item.id, false)
    },
    message: 'Tool removed',
  })
}
</script>

<template>
  <div>
    <p class="cc-eyebrow mb-2">Tools</p>

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
      v-else-if="visibleItems && visibleItems.length === 0"
      class="cc-empty-inline"
    >
      No tools yet.
    </p>

    <div v-else-if="visibleItems">
      <div
        v-for="item in visibleItems"
        :key="item.id"
        class="d-flex align-center ga-1 mb-1"
      >
        <v-checkbox-btn
          :model-value="item.checked"
          :disabled="pendingIds.has(item.id)"
          :aria-label="`Mark ${item.name} as ${item.checked ? 'not ready' : 'ready'}`"
          density="compact"
          class="flex-grow-0"
          @update:model-value="onToggle(item)"
        />
        <input
          v-model="drafts[item.id]"
          type="text"
          class="cc-field item-name"
          :class="{ 'item-name--checked': item.checked }"
          aria-label="Tool name"
          @blur="onNameBlur(item)"
          @keydown.enter.prevent="($event.target as HTMLInputElement).blur()"
        />
        <button
          type="button"
          class="cc-icon-btn cc-icon-btn--sm"
          :disabled="pendingIds.has(item.id)"
          aria-label="Remove tool"
          title="Remove tool"
          @click="onRemove(item)"
        >
          <v-progress-circular
            v-if="pendingIds.has(item.id)"
            indeterminate
            size="16"
            width="2"
          />
          <v-icon v-else icon="mdi-close" size="18" />
        </button>
      </div>
    </div>

    <div class="cc-add-row mt-2">
      <input
        v-model="newItemName"
        type="text"
        placeholder="Add a tool you'll need"
        class="cc-field cc-field--pill"
        aria-label="New tool name"
        :disabled="adding"
        @keydown.enter.prevent="onAdd"
      />
      <button
        type="button"
        class="cc-icon-btn"
        :disabled="adding || !newItemName.trim()"
        aria-label="Add tool"
        title="Add tool"
        @click="onAdd"
      >
        <v-progress-circular v-if="adding" indeterminate size="18" width="2" />
        <v-icon v-else icon="mdi-plus" size="20" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.item-name {
  flex: 1 1 auto;
  min-width: 0;
  width: auto;
  padding: 8px 12px;
}

.item-name--checked {
  color: var(--cc-ink-muted);
  text-decoration: line-through;
}
</style>
