<script setup lang="ts">
import type { TaskPriority } from '~/services/tasks'

const route = useRoute()
const taskId = computed(() => route.params.id as string)

const { fetchFarms, activeFarm, farmsError } = useFarms()
const { task, taskError, loading, fetchTask } = useTask(taskId)
const { update, remove } = useTasks()
const { categories, fetchCategories } = useCategories()
const { tags, fetchTags } = useTags()

await fetchFarms()
await fetchTask()
await fetchCategories()
await fetchTags()

const tagSuggestions = computed(() => (tags.value ?? []).map((t) => t.name))

const priorityItems: { title: string; value: TaskPriority }[] = [
  { title: 'Urgent', value: 'urgent' },
  { title: 'Soon', value: 'soon' },
  { title: 'Whenever', value: 'whenever' },
]

const categoryItems = computed(() => {
  const items = [
    { title: 'Uncategorized', value: null as string | null },
    ...(categories.value ?? []).map((category) => ({
      title: category.name,
      value: category.id as string | null,
    })),
  ]
  const currentCategoryId = task.value?.category_id ?? null
  if (
    currentCategoryId &&
    !categories.value?.some((c) => c.id === currentCategoryId)
  ) {
    items.push({
      title: '(deleted category)',
      value: currentCategoryId,
      disabled: true,
    } as { title: string; value: string | null })
  }
  return items
})

const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

const editTitle = ref('')
const editCategoryId = ref<string | null>(null)
const editPriority = ref<TaskPriority>('whenever')
const editDueDate = ref('')
const editNotes = ref('')
const editTags = ref<string[]>([])
const editLocation = ref<{ lat: number; lng: number } | null>(null)

// Seed the form fields once the task loads (not `immediate` on `task`
// itself, since `undefined` -> "not fetched" shouldn't reset the form).
watch(
  task,
  (value) => {
    if (!value) return
    editTitle.value = value.title
    editCategoryId.value = value.category_id
    editPriority.value = value.priority
    editDueDate.value = value.due_date ?? ''
    editNotes.value = value.notes ?? ''
    editTags.value = value.tags.map((tag) => tag.name)
    editLocation.value =
      value.lat !== null && value.lng !== null
        ? { lat: value.lat, lng: value.lng }
        : null
  },
  { immediate: true },
)

const saving = ref(false)
const editError = ref<string | null>(null)
const titleRules = [(v: string) => !!v.trim() || 'Title is required']

async function submitEdit() {
  if (!task.value) return
  const title = editTitle.value.trim()
  if (!title) return
  saving.value = true
  editError.value = null
  try {
    await update({
      taskId: task.value.id,
      title,
      categoryId: editCategoryId.value,
      priority: editPriority.value,
      dueDate: editDueDate.value || null,
      notes: editNotes.value || null,
      lat: editLocation.value?.lat ?? null,
      lng: editLocation.value?.lng ?? null,
      tagNames: editTags.value,
    })
    await navigateTo(`/tasks/${task.value.id}`)
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'Failed to save task'
  } finally {
    saving.value = false
  }
}

// --- Delete confirmation ---
const confirmingDelete = ref(false)
const deleting = ref(false)
const deleteError = ref<string | null>(null)

async function performDelete() {
  if (!task.value) return
  deleting.value = true
  deleteError.value = null
  try {
    await remove(task.value.id)
    await navigateTo('/tasks')
  } catch (error) {
    deleteError.value =
      error instanceof Error ? error.message : 'Failed to delete task'
  } finally {
    deleting.value = false
  }
}
</script>

<template>
  <v-container style="max-width: 640px">
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
      <div class="d-flex ga-2 mb-2">
        <v-btn variant="text" prepend-icon="mdi-arrow-left" to="/tasks">
          Back to tasks
        </v-btn>
        <v-btn
          v-if="task"
          variant="text"
          prepend-icon="mdi-eye-outline"
          :to="`/tasks/${task.id}`"
        >
          View
        </v-btn>
      </div>

      <v-alert
        v-if="taskError"
        type="error"
        variant="tonal"
        title="Couldn't load task"
        class="mb-4"
      >
        {{ taskError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && task === undefined" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="task === null"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-clipboard-alert-outline" size="64" class="mb-4" />
        <p class="text-body-1 mb-4">
          Task not found. It may have been deleted, or the link may be out of
          date.
        </p>
        <v-btn color="primary" to="/tasks">Back to tasks</v-btn>
      </div>

      <template v-else-if="task">
        <h1 class="text-h4 mb-4">Edit task</h1>

        <v-form @submit.prevent="submitEdit">
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
            :items="categoryItems"
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
          <TaskPhotos :task-id="task.id" />

          <v-alert
            v-if="editError"
            type="error"
            variant="tonal"
            density="compact"
            class="mt-4"
          >
            {{ editError }}
          </v-alert>

          <div class="d-flex justify-space-between mt-6">
            <v-btn
              color="error"
              variant="text"
              :disabled="saving"
              @click="confirmingDelete = true"
            >
              Delete
            </v-btn>
            <div class="d-flex ga-2">
              <v-btn :disabled="saving" :to="`/tasks/${task.id}`">
                Cancel
              </v-btn>
              <v-btn
                type="submit"
                color="primary"
                :loading="saving"
                :disabled="!editTitle.trim()"
              >
                Save
              </v-btn>
            </div>
          </div>
        </v-form>

        <v-dialog v-model="confirmingDelete" max-width="420" persistent>
          <v-card>
            <v-card-title>Delete task?</v-card-title>
            <v-card-text>
              Delete "{{ task.title }}"? This can't be undone.
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
              <v-btn :disabled="deleting" @click="confirmingDelete = false">
                Cancel
              </v-btn>
              <v-btn color="error" :loading="deleting" @click="performDelete">
                Delete
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </template>
    </template>
  </v-container>
</template>
