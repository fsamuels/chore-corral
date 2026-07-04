<script setup lang="ts">
import {
  isTaskOverdue,
  type TaskPriority,
  type TaskStatus,
  type TaskSummary,
} from '~/services/tasks'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const {
  tasks,
  tasksError,
  loading,
  fetchTasks,
  create,
  update,
  setStatus,
  remove,
} = useTasks()
const { categories, fetchCategories } = useCategories()
const { tags, fetchTags } = useTags()

// Fetch farms first so the active farm resolves during SSR, then load its
// tasks, categories, and tags (the composables' watch covers later farm
// switches).
await fetchFarms()
await fetchTasks()
await fetchCategories()
await fetchTags()

// Deep link from the map view (?task=<id>): open that task's edit dialog,
// then strip the param so a reload/refresh doesn't reopen it. Client-only —
// the dialog is a client interaction, and a bogus/unknown id is ignored.
// Deferred to onMounted (rather than run inline here) so the dialog opens
// after the page has actually mounted, not mid-hydration — opening it
// synchronously during setup crashed the whole page's render.
if (import.meta.client) {
  onMounted(() => {
    const route = useRoute()
    const router = useRouter()
    const taskId = route.query.task
    if (typeof taskId === 'string') {
      const match = tasks.value?.find((task) => task.id === taskId)
      if (match) openEdit(match)
      router.replace({ query: {} })
    }
  })
}

const tagSuggestions = computed(() => (tags.value ?? []).map((t) => t.name))

const priorityItems: { title: string; value: TaskPriority }[] = [
  { title: 'Urgent', value: 'urgent' },
  { title: 'Soon', value: 'soon' },
  { title: 'Whenever', value: 'whenever' },
]

const statusItems: { title: string; value: TaskStatus }[] = [
  { title: 'Not started', value: 'not_started' },
  { title: 'In progress', value: 'in_progress' },
  { title: 'Done', value: 'done' },
]

const headers = [
  { title: 'Title', key: 'title', sortable: false },
  { title: 'Category', key: 'category', sortable: false },
  { title: 'Priority', key: 'priority', sortable: false },
  { title: 'Status', key: 'status', sortable: false },
  { title: 'Due date', key: 'due_date', sortable: false },
  { title: 'Actions', key: 'actions', sortable: false, align: 'end' as const },
]

const categoryItems = computed(() =>
  (categories.value ?? []).map((category) => ({
    title: category.name,
    value: category.id,
  })),
)

// Sentinel for "no filter"; `null` is a real value (Uncategorized), so the
// filter needs a distinct value for "all categories".
const ALL_CATEGORIES = 'all'
const selectedCategory = ref<string | null>(ALL_CATEGORIES)

const filterItems = computed(() => [
  { title: 'All categories', value: ALL_CATEGORIES },
  { title: 'Uncategorized', value: null },
  ...categoryItems.value,
])

const filteredTasks = computed(() => {
  const all = tasks.value ?? []
  if (selectedCategory.value === ALL_CATEGORIES) return all
  return all.filter((task) => task.category_id === selectedCategory.value)
})

function categoryDisplay(categoryId: string | null): {
  text: string
  deleted: boolean
} {
  return categoryDisplayName(categoryId, categories.value)
}

// Mini-map starting point before a pin exists (SPEC: the farm's default
// map center, manually set at farm creation — may be unset).
const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

const snackbarMessage = ref<string | null>(null)
const showSnackbar = ref(false)

function notifyError(message: string) {
  snackbarMessage.value = message
  showSnackbar.value = true
}

async function onStatusChange(task: TaskSummary, status: TaskStatus) {
  if (task.status === status) return
  try {
    await setStatus(task.id, status)
  } catch (error) {
    notifyError(
      error instanceof Error ? error.message : 'Failed to update status',
    )
    // Make sure the list reflects reality rather than a stale/optimistic value.
    await fetchTasks()
  }
}

// --- Create dialog ---
const showCreate = ref(false)
const newTitle = ref('')
const newCategoryId = ref<string | null>(null)
const newPriority = ref<TaskPriority>('whenever')
const newDueDate = ref('')
const newNotes = ref('')
const newTags = ref<string[]>([])
const newLocation = ref<{ lat: number; lng: number } | null>(null)
const moreDetailsOpen = ref(false)
const creating = ref(false)
const createError = ref<string | null>(null)
const titleRules = [(v: string) => !!v.trim() || 'Title is required']

function openCreate() {
  resetCreateForm()
  showCreate.value = true
}

function resetCreateForm() {
  newTitle.value = ''
  newCategoryId.value = null
  newPriority.value = 'whenever'
  newDueDate.value = ''
  newNotes.value = ''
  newTags.value = []
  newLocation.value = null
  moreDetailsOpen.value = false
  createError.value = null
}

async function submitCreate() {
  const title = newTitle.value.trim()
  if (!title) return
  creating.value = true
  createError.value = null
  try {
    await create({
      title,
      categoryId: newCategoryId.value,
      priority: newPriority.value,
      dueDate: newDueDate.value || null,
      notes: newNotes.value || null,
      lat: newLocation.value?.lat ?? null,
      lng: newLocation.value?.lng ?? null,
      tagNames: newTags.value,
    })
    showCreate.value = false
    resetCreateForm()
  } catch (error) {
    createError.value =
      error instanceof Error ? error.message : 'Failed to create task'
  } finally {
    creating.value = false
  }
}

// --- Edit dialog ---
const editing = ref<TaskSummary | null>(null)
const editTitle = ref('')
const editCategoryId = ref<string | null>(null)
const editPriority = ref<TaskPriority>('whenever')
const editDueDate = ref('')
const editNotes = ref('')
const editTags = ref<string[]>([])
const editLocation = ref<{ lat: number; lng: number } | null>(null)
const saving = ref(false)
const editError = ref<string | null>(null)

const editCategoryItems = computed(() => {
  const items = [
    { title: 'Uncategorized', value: null },
    ...categoryItems.value,
  ]
  const categoryId = editing.value?.category_id ?? null
  if (categoryId && !categories.value?.some((c) => c.id === categoryId)) {
    items.push({
      title: '(deleted category)',
      value: categoryId,
      disabled: true,
    } as { title: string; value: string | null })
  }
  return items
})

function openEdit(task: TaskSummary) {
  editing.value = task
  editTitle.value = task.title
  editCategoryId.value = task.category_id
  editPriority.value = task.priority
  editDueDate.value = task.due_date ?? ''
  editNotes.value = task.notes ?? ''
  editTags.value = task.tags.map((tag) => tag.name)
  editLocation.value =
    task.lat !== null && task.lng !== null
      ? { lat: task.lat, lng: task.lng }
      : null
  editError.value = null
}

function closeEdit() {
  editing.value = null
}

async function submitEdit() {
  if (!editing.value) return
  const title = editTitle.value.trim()
  if (!title) return
  saving.value = true
  editError.value = null
  try {
    await update({
      taskId: editing.value.id,
      title,
      categoryId: editCategoryId.value,
      priority: editPriority.value,
      dueDate: editDueDate.value || null,
      notes: editNotes.value || null,
      lat: editLocation.value?.lat ?? null,
      lng: editLocation.value?.lng ?? null,
      tagNames: editTags.value,
    })
    closeEdit()
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'Failed to save task'
  } finally {
    saving.value = false
  }
}

// --- Delete confirmation (opened from the edit dialog) ---
const toDelete = ref<TaskSummary | null>(null)
const deleting = ref(false)
const deleteError = ref<string | null>(null)

function confirmDelete() {
  if (!editing.value) return
  toDelete.value = editing.value
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
    await remove(toDelete.value.id)
    toDelete.value = null
    closeEdit()
  } catch (error) {
    deleteError.value =
      error instanceof Error ? error.message : 'Failed to delete task'
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
      <div class="d-flex align-start justify-space-between mb-1">
        <div>
          <h1 class="text-h4 mb-1">Tasks</h1>
          <p class="text-body-2 text-medium-emphasis">{{ activeFarm.name }}</p>
        </div>
        <v-btn color="primary" @click="openCreate">New task</v-btn>
      </div>

      <v-select
        v-model="selectedCategory"
        :items="filterItems"
        label="Category"
        density="comfortable"
        variant="outlined"
        hide-details
        style="max-width: 280px"
        class="mb-6"
      />

      <v-alert
        v-if="tasksError"
        type="error"
        variant="tonal"
        title="Couldn't load tasks"
        class="mb-4"
      >
        {{ tasksError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && tasks === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <v-card v-else-if="!tasks || tasks.length === 0" variant="tonal">
        <v-card-text>
          No tasks yet. Add one above to start tracking work on this farm.
        </v-card-text>
      </v-card>

      <v-card v-else-if="filteredTasks.length === 0" variant="tonal">
        <v-card-text> No tasks in this category. </v-card-text>
      </v-card>

      <v-data-table
        v-else
        :headers="headers"
        :items="filteredTasks"
        :items-per-page="-1"
        hide-default-footer
        density="comfortable"
      >
        <template #[`item.title`]="{ item }">
          <span
            :class="{
              'text-medium-emphasis text-decoration-line-through':
                item.status === 'done',
            }"
          >
            {{ item.title }}
          </span>
          <div v-if="item.tags.length > 0" class="d-flex flex-wrap ga-1 mt-1">
            <v-chip
              v-for="tag in item.tags"
              :key="tag.id"
              size="x-small"
              variant="tonal"
            >
              {{ tag.name }}
            </v-chip>
          </div>
        </template>

        <template #[`item.category`]="{ item }">
          <span
            :class="{
              'text-medium-emphasis font-italic': categoryDisplay(
                item.category_id,
              ).deleted,
            }"
          >
            {{ categoryDisplay(item.category_id).text }}
          </span>
        </template>

        <template #[`item.priority`]="{ item }">
          <v-chip
            size="small"
            :prepend-icon="PRIORITY_DISPLAY[item.priority as TaskPriority].icon"
            :color="
              PRIORITY_DISPLAY[item.priority as TaskPriority].color || undefined
            "
          >
            {{ PRIORITY_DISPLAY[item.priority as TaskPriority].label }}
          </v-chip>
        </template>

        <template #[`item.status`]="{ item }">
          <v-select
            :model-value="item.status"
            :items="statusItems"
            density="compact"
            variant="outlined"
            hide-details
            style="width: 170px"
            @update:model-value="
              (value: TaskStatus) => onStatusChange(item, value)
            "
          >
            <template #selection="{ item: selected }">
              <v-icon
                :icon="STATUS_DISPLAY[selected.value as TaskStatus].icon"
                size="small"
                class="mr-1"
              />
              {{ selected.title }}
            </template>
            <template #item="{ item: option, props: itemProps }">
              <v-list-item
                v-bind="itemProps"
                :prepend-icon="STATUS_DISPLAY[option.value as TaskStatus].icon"
              />
            </template>
          </v-select>
        </template>

        <template #[`item.due_date`]="{ item }">
          <span :class="{ 'text-error': isTaskOverdue(item) }">
            {{ item.due_date ?? '' }}
          </span>
          <v-chip
            v-if="isTaskOverdue(item)"
            size="x-small"
            color="error"
            :prepend-icon="OVERDUE_ICON"
            class="ml-2"
          >
            Overdue
          </v-chip>
        </template>

        <template #[`item.actions`]="{ item }">
          <v-btn
            icon="mdi-pencil-outline"
            variant="text"
            density="comfortable"
            :aria-label="`Edit ${item.title}`"
            :title="`Edit ${item.title}`"
            @click="openEdit(item)"
          />
        </template>
      </v-data-table>
    </template>

    <!-- Create dialog -->
    <v-dialog v-model="showCreate" max-width="480">
      <v-card>
        <v-card-title>New task</v-card-title>
        <v-form @submit.prevent="submitCreate">
          <v-card-text>
            <v-text-field
              v-model="newTitle"
              label="Title"
              :rules="titleRules"
              :disabled="creating"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
              class="mb-4"
              autofocus
            />
            <v-select
              v-model="newCategoryId"
              :items="[
                { title: 'Uncategorized', value: null },
                ...categoryItems,
              ]"
              label="Category"
              :disabled="creating"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-4"
            />
            <v-select
              v-model="newPriority"
              :items="priorityItems"
              label="Priority"
              :disabled="creating"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-2"
            />

            <v-btn
              variant="text"
              size="small"
              :append-icon="
                moreDetailsOpen ? 'mdi-chevron-up' : 'mdi-chevron-down'
              "
              class="mt-2 mb-2"
              @click="moreDetailsOpen = !moreDetailsOpen"
            >
              More details
            </v-btn>

            <div v-if="moreDetailsOpen">
              <v-textarea
                v-model="newNotes"
                label="Notes"
                rows="3"
                :disabled="creating"
                density="comfortable"
                variant="outlined"
                hide-details
                class="mb-4"
              />
              <v-combobox
                v-model="newTags"
                :items="tagSuggestions"
                label="Tags"
                multiple
                chips
                closable-chips
                :disabled="creating"
                density="comfortable"
                variant="outlined"
                hide-details
                class="mb-4"
              />
              <v-text-field
                v-model="newDueDate"
                label="Due date"
                type="date"
                :disabled="creating"
                density="comfortable"
                variant="outlined"
                hide-details
                class="mb-4"
              />
              <p class="text-body-2 mb-2">Location</p>
              <LocationPicker
                v-model="newLocation"
                auto-capture
                :fallback-center="farmCenter"
                :disabled="creating"
              />
            </div>

            <v-alert
              v-if="createError"
              type="error"
              variant="tonal"
              density="compact"
              class="mt-4"
            >
              {{ createError }}
            </v-alert>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn :disabled="creating" @click="showCreate = false">
              Cancel
            </v-btn>
            <v-btn
              type="submit"
              color="primary"
              :loading="creating"
              :disabled="!newTitle.trim()"
            >
              Add
            </v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>

    <!-- Edit dialog -->
    <v-dialog
      :model-value="editing !== null"
      max-width="480"
      @update:model-value="(v: boolean) => !v && closeEdit()"
    >
      <v-card v-if="editing">
        <v-card-title>Edit task</v-card-title>
        <v-form @submit.prevent="submitEdit">
          <v-card-text>
            <v-text-field
              v-model="editTitle"
              label="Title"
              :rules="titleRules"
              :disabled="saving"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
              class="mb-4"
            />
            <v-select
              v-model="editCategoryId"
              :items="editCategoryItems"
              label="Category"
              :disabled="saving"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-4"
            />
            <v-select
              v-model="editPriority"
              :items="priorityItems"
              label="Priority"
              :disabled="saving"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-4"
            />
            <v-text-field
              v-model="editDueDate"
              label="Due date"
              type="date"
              :disabled="saving"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-4"
            />
            <v-textarea
              v-model="editNotes"
              label="Notes"
              rows="3"
              :disabled="saving"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-4"
            />
            <v-combobox
              v-model="editTags"
              :items="tagSuggestions"
              label="Tags"
              multiple
              chips
              closable-chips
              :disabled="saving"
              density="comfortable"
              variant="outlined"
              hide-details
              class="mb-4"
            />
            <p class="text-body-2 mb-2">Location</p>
            <LocationPicker
              v-model="editLocation"
              :fallback-center="farmCenter"
              :disabled="saving"
            />

            <v-divider class="my-4" />
            <TaskPhotos v-if="editing" :task-id="editing.id" />

            <v-alert
              v-if="editError"
              type="error"
              variant="tonal"
              density="compact"
              class="mt-4"
            >
              {{ editError }}
            </v-alert>
          </v-card-text>
          <v-card-actions>
            <v-btn
              color="error"
              variant="text"
              :disabled="saving"
              @click="confirmDelete"
            >
              Delete
            </v-btn>
            <v-spacer />
            <v-btn :disabled="saving" @click="closeEdit">Cancel</v-btn>
            <v-btn
              type="submit"
              color="primary"
              :loading="saving"
              :disabled="!editTitle.trim()"
            >
              Save
            </v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>

    <!-- Delete confirmation -->
    <v-dialog :model-value="toDelete !== null" max-width="420" persistent>
      <v-card>
        <v-card-title>Delete task?</v-card-title>
        <v-card-text>
          Delete “{{ toDelete?.title }}”? This can't be undone.
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

    <v-snackbar v-model="showSnackbar" color="error" :timeout="6000">
      {{ snackbarMessage }}
    </v-snackbar>
  </v-container>
</template>
