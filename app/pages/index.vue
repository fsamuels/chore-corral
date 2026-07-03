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
          <v-chip size="large" variant="tonal">
            {{ outstandingTasks.length }} outstanding
          </v-chip>
          <v-chip
            size="large"
            variant="tonal"
            :color="urgentCount > 0 ? 'error' : undefined"
          >
            {{ urgentCount }} urgent
          </v-chip>
          <v-chip
            size="large"
            variant="tonal"
            :color="overdueCount > 0 ? 'error' : undefined"
          >
            {{ overdueCount }} overdue
          </v-chip>
        </div>

        <v-card v-if="!tasks || tasks.length === 0" variant="tonal">
          <v-card-text>
            No tasks yet.
            <NuxtLink to="/tasks">Add one</NuxtLink>
            to start tracking work on this farm.
          </v-card-text>
        </v-card>

        <v-card v-else-if="outstandingTasks.length === 0" variant="tonal">
          <v-card-text> Nothing outstanding — every task is done. </v-card-text>
        </v-card>

        <v-list v-else lines="two" class="mb-2">
          <v-list-item
            v-for="task in outstandingTasks"
            :key="task.id"
            :to="`/tasks?task=${task.id}`"
            border
            rounded
            class="mb-2"
          >
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
                :color="PRIORITY_DISPLAY[task.priority].color || undefined"
              >
                {{ PRIORITY_DISPLAY[task.priority].label }}
              </v-chip>
              <v-chip v-if="isTaskOverdue(task)" size="small" color="error">
                Overdue
              </v-chip>
            </template>
          </v-list-item>
        </v-list>
      </template>
    </template>
  </v-container>
</template>
