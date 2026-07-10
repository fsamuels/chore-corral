<script setup lang="ts">
import type { VForm } from 'vuetify/components'
import type { CategorySummary } from '~/services/categories'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const {
  categories,
  categoriesError,
  loading,
  fetchCategories,
  create,
  remove,
} = useCategories()

// Fetch farms first so the active farm resolves during SSR, then load its
// categories (the composable's watch covers later farm switches).
await fetchFarms()
await fetchCategories()

const newName = ref('')
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
    await create(name)
    newName.value = ''
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
      blockedMessage.value = `Can't delete — ${n} active task${
        n === 1 ? '' : 's'
      } still use${n === 1 ? 's' : ''} this category.`
      showBlocked.value = true
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
            :loading="creating"
            :disabled="!newName.trim()"
            class="mt-1"
          >
            Add
          </v-btn>
        </div>
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
          No categories yet. Add one above to start organizing tasks.
        </p>
      </div>

      <div v-else class="cc-card pa-0" style="overflow: hidden">
        <v-list lines="one">
          <v-list-item
            v-for="category in categories"
            :key="category.id"
            :title="category.name"
          >
            <template #append>
              <v-btn
                icon="mdi-delete-outline"
                variant="text"
                density="comfortable"
                :aria-label="`Delete ${category.name}`"
                :title="`Delete ${category.name}`"
                @click="confirmDelete(category)"
              />
            </template>
          </v-list-item>
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
