<script setup lang="ts">
import {
  isTaskOverdue,
  type TaskStatus,
  type TaskSummary,
} from '~/services/tasks'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks, setStatus } = useTasks()
const { categories, fetchCategories } = useCategories()

// Fetch farms first so the active farm resolves during SSR, then load its
// tasks and categories (the composables' watch covers later farm switches).
await fetchFarms()
await fetchTasks()
await fetchCategories()

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

function openTask(taskId: string) {
  navigateTo(`/tasks/${taskId}`)
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
        <v-btn color="primary" to="/tasks/new">New task</v-btn>
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

      <div
        v-else-if="!tasks || tasks.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-clipboard-text-outline" size="64" class="mb-4" />
        <p class="text-body-1 mb-4">
          No tasks yet. Add one to start tracking work on this farm.
        </p>
        <v-btn color="primary" to="/tasks/new">New task</v-btn>
      </div>

      <div
        v-else-if="filteredTasks.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-filter-variant-remove" size="64" class="mb-4" />
        <p class="text-body-1">No tasks in this category.</p>
      </div>

      <v-data-table
        v-else
        :headers="headers"
        :items="filteredTasks"
        :items-per-page="-1"
        hide-default-footer
        density="comfortable"
        elevation="1"
      >
        <template #item="{ item }">
          <tr
            style="cursor: pointer"
            :aria-label="`Open ${item.title}`"
            @click="openTask(item.id)"
          >
            <td>
              <span
                :class="{
                  'text-medium-emphasis text-decoration-line-through':
                    item.status === 'done',
                }"
              >
                {{ item.title }}
              </span>
              <div
                v-if="item.tags.length > 0"
                class="d-flex flex-wrap ga-1 mt-1"
              >
                <v-chip
                  v-for="tag in item.tags"
                  :key="tag.id"
                  size="x-small"
                  variant="tonal"
                >
                  {{ tag.name }}
                </v-chip>
              </div>
            </td>

            <td>
              <span
                :class="{
                  'text-medium-emphasis font-italic': categoryDisplay(
                    item.category_id,
                  ).deleted,
                }"
              >
                {{ categoryDisplay(item.category_id).text }}
              </span>
            </td>

            <td>
              <v-chip
                size="small"
                :prepend-icon="PRIORITY_DISPLAY[item.priority].icon"
                :color="PRIORITY_DISPLAY[item.priority].color || undefined"
              >
                {{ PRIORITY_DISPLAY[item.priority].label }}
              </v-chip>
            </td>

            <td @click.stop>
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
                    :prepend-icon="
                      STATUS_DISPLAY[option.value as TaskStatus].icon
                    "
                  />
                </template>
              </v-select>
            </td>

            <td>
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
            </td>
          </tr>
        </template>
      </v-data-table>
    </template>

    <v-snackbar v-model="showSnackbar" color="error" :timeout="6000">
      {{ snackbarMessage }}
    </v-snackbar>
  </v-container>
</template>
