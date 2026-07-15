<script setup lang="ts">
import type { VForm } from 'vuetify/components'
import type {
  CategorySummary,
  CategorySummaryWithCount,
} from '~/services/categories'
import { TASK_STATUSES } from '~/services/tags'
import { STATUS_DISPLAY } from '~/utils/task-display'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const {
  categories,
  categoriesError,
  loading,
  fetchCategories,
  create,
  update,
  remove,
} = useCategories()
const {
  categories: categorySummaries,
  fetchCategories: fetchCategorySummaries,
} = useCategorySummaries()

// Fetch farms first so the active farm resolves during SSR, then load its
// categories (the composable's watch covers later farm switches).
await fetchFarms()
await fetchCategories()
await fetchCategorySummaries()

function summaryFor(
  category: CategorySummary,
): CategorySummaryWithCount | undefined {
  return categorySummaries.value?.find((summary) => summary.id === category.id)
}

// Deep-link into the tasks page filtered by this category (and optionally a
// status). Mirrors `tags.vue`'s `tasksLink`, but by id (categories aren't
// addressable by name in the tasks-page filter).
function tasksLink(category: CategorySummary, status?: string): string {
  const params = new URLSearchParams({ category: category.id })
  if (status) params.set('status', status)
  return `/tasks?${params.toString()}`
}

function statusEntries(category: CategorySummary) {
  const summary = summaryFor(category)
  return TASK_STATUSES.map((status) => ({
    status,
    label: STATUS_DISPLAY[status].label,
    icon: STATUS_DISPLAY[status].icon,
    count: summary?.statusCounts[status] ?? 0,
    to: tasksLink(category, status),
  }))
}

const newName = ref('')
const newEmoji = ref<string | null>(null)
const creating = ref(false)
const createError = ref<string | null>(null)
const nameRules = [(v: string) => !!v.trim() || 'Name is required']
const createForm = ref<VForm | null>(null)

async function submitCreate() {
  const name = newName.value.trim()
  if (!name) return
  creating.value = true
  createError.value = null
  try {
    await create(name, newEmoji.value)
    await fetchCategorySummaries()
    newName.value = ''
    newEmoji.value = null
    // Clearing the field re-triggers `nameRules` against the now-empty
    // string, which would otherwise flash a spurious "Name is required"
    // right after a successful create. VTextField validates its new value
    // on the next tick, so resetValidation must run after that, not before.
    await nextTick()
    createForm.value?.resetValidation()
  } catch (error) {
    createError.value =
      error instanceof Error ? error.message : 'Failed to create category'
  } finally {
    creating.value = false
  }
}

// Edit: explicit edit mode with Save/Cancel, like the locations page (blur-
// commit would fire on every field-navigation click, which reads as jumpy
// for a plain text field too).
const editingId = ref<string | null>(null)
const editName = ref('')
const editEmoji = ref<string | null>(null)
const saving = ref(false)
const saveError = ref<string | null>(null)

function startEditing(category: CategorySummary) {
  editingId.value = category.id
  editName.value = category.name
  editEmoji.value = category.emoji
  saveError.value = null
}

function cancelEditing() {
  editingId.value = null
  saveError.value = null
}

async function saveEditing() {
  const id = editingId.value
  const name = editName.value.trim()
  if (!id || !name) return
  saving.value = true
  saveError.value = null
  try {
    await update(id, name, editEmoji.value)
    await fetchCategorySummaries()
    editingId.value = null
  } catch (error) {
    saveError.value =
      error instanceof Error ? error.message : 'Failed to save category'
  } finally {
    saving.value = false
  }
}

// Delete confirmation dialog state.
const toDelete = ref<CategorySummary | null>(null)
const deleting = ref(false)
const deleteError = ref<string | null>(null)
const blockedMessage = ref<string | null>(null)
const showBlocked = ref(false)

function confirmDelete(category: CategorySummary) {
  toDelete.value = category
  deleteError.value = null
}

function cancelDelete() {
  toDelete.value = null
}

async function performDelete() {
  if (!toDelete.value) return
  deleting.value = true
  deleteError.value = null
  try {
    const result = await remove(toDelete.value.id)
    if (!result.deleted) {
      const n = result.activeTaskCount
      blockedMessage.value = `Can't delete — ${n} active chore${
        n === 1 ? '' : 's'
      } still use${n === 1 ? 's' : ''} this category.`
      showBlocked.value = true
    } else {
      await fetchCategorySummaries()
    }
    toDelete.value = null
  } catch (error) {
    deleteError.value =
      error instanceof Error ? error.message : 'Failed to delete category'
  } finally {
    deleting.value = false
  }
}
</script>

<template>
  <v-container>
    <v-alert
      v-if="farmsError"
      type="error"
      variant="tonal"
      title="Couldn't load your farms"
      class="mb-4"
    >
      {{ farmsError }} — try reloading; if this persists, the database may not
      be reachable.
    </v-alert>
    <template v-else-if="activeFarm">
      <h1 class="text-h4 mb-1">Categories</h1>
      <p class="cc-eyebrow mb-6">{{ activeFarm.name }}</p>

      <v-form
        ref="createForm"
        class="cc-card mb-6"
        @submit.prevent="submitCreate"
      >
        <div class="d-flex align-start ga-2">
          <v-text-field
            v-model="newName"
            label="New category"
            :rules="nameRules"
            :disabled="creating"
            density="comfortable"
            variant="outlined"
            hide-details="auto"
          />
          <v-btn
            type="submit"
            color="primary"
            size="large"
            :loading="creating"
            :disabled="!newName.trim()"
            class="mt-1"
          >
            Add
          </v-btn>
        </div>
        <p class="cc-eyebrow mt-4 mb-2">Emoji (optional)</p>
        <CategoryEmojiPicker v-model="newEmoji" :disabled="creating" />
        <v-alert
          v-if="createError"
          type="error"
          variant="tonal"
          density="compact"
          class="mt-2"
        >
          {{ createError }}
        </v-alert>
      </v-form>

      <v-alert
        v-if="categoriesError"
        type="error"
        variant="tonal"
        title="Couldn't load categories"
        class="mb-4"
      >
        {{ categoriesError }} — try reloading; if this persists, the database
        may not be reachable.
      </v-alert>

      <div v-else-if="loading && categories === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="!categories || categories.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-shape-outline" size="64" class="mb-4" />
        <p class="text-body-1">
          No categories yet. Add one above to start organizing chores.
        </p>
      </div>

      <div v-else class="cc-card pa-0" style="overflow: hidden">
        <v-list lines="one">
          <template v-for="category in categories" :key="category.id">
            <div v-if="editingId === category.id" class="pa-4">
              <v-text-field
                v-model="editName"
                label="Name"
                :rules="nameRules"
                :disabled="saving"
                density="comfortable"
                variant="outlined"
                hide-details="auto"
                autofocus
                @keyup.enter="saveEditing"
              />
              <p class="cc-eyebrow mt-4 mb-2">Emoji (optional)</p>
              <CategoryEmojiPicker v-model="editEmoji" :disabled="saving" />
              <v-alert
                v-if="saveError"
                type="error"
                variant="tonal"
                density="compact"
                class="mt-2"
              >
                {{ saveError }}
              </v-alert>
              <div class="d-flex justify-end ga-2 mt-3">
                <v-btn size="small" :disabled="saving" @click="cancelEditing">
                  Cancel
                </v-btn>
                <v-btn
                  size="small"
                  color="primary"
                  :loading="saving"
                  :disabled="!editName.trim()"
                  @click="saveEditing"
                >
                  Save
                </v-btn>
              </div>
            </div>
            <v-list-item v-else lines="two">
              <template #prepend>
                <span
                  class="category-emoji"
                  :class="{ 'category-emoji--empty': !category.emoji }"
                  aria-hidden="true"
                >
                  {{ category.emoji ?? '🏷️' }}
                </span>
              </template>
              <template #title>
                <NuxtLink :to="tasksLink(category)" class="entity-row__title">
                  <span>{{ category.name }}</span>
                  <span class="cc-pill cc-pill--muted entity-row__total">
                    {{ summaryFor(category)?.taskCount ?? 0 }} chore{{
                      (summaryFor(category)?.taskCount ?? 0) === 1 ? '' : 's'
                    }}
                  </span>
                </NuxtLink>
              </template>
              <template #subtitle>
                <div class="entity-row__statuses">
                  <template
                    v-for="entry in statusEntries(category)"
                    :key="entry.status"
                  >
                    <NuxtLink
                      v-if="entry.count > 0"
                      :to="entry.to"
                      class="entity-status entity-status--link"
                    >
                      <v-icon :icon="entry.icon" size="14" />
                      <span
                        >{{ entry.count }} {{ entry.label.toLowerCase() }}</span
                      >
                    </NuxtLink>
                    <span v-else class="entity-status entity-status--empty">
                      <v-icon :icon="entry.icon" size="14" />
                      <span>0 {{ entry.label.toLowerCase() }}</span>
                    </span>
                  </template>
                </div>
              </template>
              <template #append>
                <div class="d-flex ga-2">
                  <button
                    type="button"
                    class="cc-icon-btn cc-icon-btn--sm"
                    :aria-label="`Edit ${category.name}`"
                    :title="`Edit ${category.name}`"
                    @click="startEditing(category)"
                  >
                    <v-icon icon="mdi-pencil-outline" size="18" />
                  </button>
                  <button
                    type="button"
                    class="cc-icon-btn cc-icon-btn--sm"
                    :aria-label="`Delete ${category.name}`"
                    :title="`Delete ${category.name}`"
                    @click="confirmDelete(category)"
                  >
                    <v-icon icon="mdi-delete-outline" size="18" />
                  </button>
                </div>
              </template>
            </v-list-item>
            <v-divider />
          </template>
        </v-list>
      </div>
    </template>

    <v-dialog :model-value="toDelete !== null" max-width="420" persistent>
      <v-card>
        <v-card-title>Delete category?</v-card-title>
        <v-card-text>
          Delete “{{ toDelete?.name }}”? This can't be undone.
          <v-alert
            v-if="deleteError"
            type="error"
            variant="tonal"
            density="compact"
            class="mt-3"
          >
            {{ deleteError }}
          </v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn :disabled="deleting" @click="cancelDelete">Cancel</v-btn>
          <v-btn color="error" :loading="deleting" @click="performDelete">
            Delete
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="showBlocked" color="warning" :timeout="6000">
      {{ blockedMessage }}
    </v-snackbar>
  </v-container>
</template>

<style scoped>
/* Emoji chip in a category row; the placeholder tag is dimmed so real emoji
   read as the accent. */
.category-emoji {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  font-size: 1.25rem;
  line-height: 1;
}

.category-emoji--empty {
  opacity: 0.35;
}

.entity-row__title {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: var(--cc-ink);
}

.entity-row__total {
  flex-shrink: 0;
}

.entity-row__statuses {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 6px;
  white-space: normal;
}

.entity-status {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border-radius: 999px;
  padding: 4px 10px;
  font-size: 0.75rem;
  font-weight: 600;
  line-height: 1.4;
  white-space: nowrap;
  text-decoration: none;
}

.entity-status--link {
  background: var(--cc-field);
  border: 1px solid var(--cc-field-border);
  color: var(--cc-ink);
}

.entity-status--link:hover {
  border-color: var(--cc-accent);
  color: var(--cc-accent);
}

.entity-status--empty {
  color: var(--cc-ink-muted);
  opacity: 0.6;
}
</style>
