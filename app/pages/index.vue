<script setup lang="ts">
import { isTaskOverdue, type TaskSummary } from '~/services/tasks'

const user = useSupabaseUser()
const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks } = useTasks()
const { categories, fetchCategories } = useCategories()

await fetchFarms()
await fetchTasks()
await fetchCategories()

// `tasks` is already urgent-first / oldest-first within a tier (see
// `compareTasks`), so filtering to non-done preserves that priority order.
const outstandingTasks = computed(
  () => tasks.value?.filter((task) => task.status !== 'done') ?? [],
)

const overdueCount = computed(
  () => outstandingTasks.value.filter((task) => isTaskOverdue(task)).length,
)
const urgentCount = computed(
  () =>
    outstandingTasks.value.filter((task) => task.priority === 'urgent').length,
)

function categoryName(task: TaskSummary): string {
  return categoryDisplayName(task.category_id, categories.value).text
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
          <h1 class="text-h4 mb-1">{{ activeFarm.name }}</h1>
          <p class="text-body-2 text-medium-emphasis">
            Signed in as {{ user?.email }}
          </p>
        </div>
        <v-btn color="primary" variant="tonal" to="/tasks">
          Manage tasks
        </v-btn>
      </div>

      <v-alert
        v-if="tasksError"
        type="error"
        variant="tonal"
        title="Couldn't load tasks"
        class="mb-4 mt-4"
      >
        {{ tasksError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && tasks === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <template v-else>
        <div class="d-flex flex-wrap ga-3 mt-4 mb-6">
          <v-card
            variant="tonal"
            color="primary"
            class="flex-grow-1"
            style="min-width: 160px"
          >
            <v-card-text class="d-flex align-center ga-3">
              <v-icon icon="mdi-format-list-checks" size="large" />
              <div>
                <div class="text-h5">{{ outstandingTasks.length }}</div>
                <div class="text-body-2">Outstanding</div>
              </div>
            </v-card-text>
          </v-card>

          <v-card
            variant="tonal"
            :color="urgentCount > 0 ? 'warning' : undefined"
            class="flex-grow-1"
            style="min-width: 160px"
          >
            <v-card-text class="d-flex align-center ga-3">
              <v-icon icon="mdi-fire" size="large" />
              <div>
                <div class="text-h5">{{ urgentCount }}</div>
                <div class="text-body-2">Urgent</div>
              </div>
            </v-card-text>
          </v-card>

          <v-card
            variant="tonal"
            :color="overdueCount > 0 ? 'error' : undefined"
            class="flex-grow-1"
            style="min-width: 160px"
          >
            <v-card-text class="d-flex align-center ga-3">
              <v-icon icon="mdi-alert-circle" size="large" />
              <div>
                <div class="text-h5">{{ overdueCount }}</div>
                <div class="text-body-2">Overdue</div>
              </div>
            </v-card-text>
          </v-card>
        </div>

        <div
          v-if="!tasks || tasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-clipboard-text-outline" size="64" class="mb-4" />
          <p class="text-body-1 mb-4">
            No tasks yet. Add one to start tracking work on this farm.
          </p>
          <v-btn color="primary" variant="tonal" to="/tasks">New task</v-btn>
        </div>

        <div
          v-else-if="outstandingTasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-check-circle-outline" size="64" class="mb-4" />
          <p class="text-body-1">Nothing outstanding — every task is done.</p>
        </div>

        <v-list v-else lines="two" class="mb-2">
          <v-list-item
            v-for="task in outstandingTasks"
            :key="task.id"
            :to="`/tasks/${task.id}`"
            border
            rounded
            elevation="1"
            class="mb-2"
          >
            <template #prepend>
              <v-icon :icon="STATUS_DISPLAY[task.status].icon" class="mr-3" />
            </template>
            <v-list-item-title :class="{ 'text-error': isTaskOverdue(task) }">
              {{ task.title }}
            </v-list-item-title>
            <v-list-item-subtitle>
              {{ categoryName(task) }}
              <span v-if="task.due_date"> · Due {{ task.due_date }}</span>
            </v-list-item-subtitle>
            <template #append>
              <v-chip
                size="small"
                class="mr-2"
                :prepend-icon="PRIORITY_DISPLAY[task.priority].icon"
                :color="PRIORITY_DISPLAY[task.priority].color || undefined"
              >
                {{ PRIORITY_DISPLAY[task.priority].label }}
              </v-chip>
              <v-chip
                v-if="isTaskOverdue(task)"
                size="small"
                color="error"
                :prepend-icon="OVERDUE_ICON"
              >
                Overdue
              </v-chip>
            </template>
          </v-list-item>
        </v-list>
      </template>
    </template>
  </v-container>
</template>
