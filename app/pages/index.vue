<script setup lang="ts">
import {
  isTaskOverdue,
  partitionHomeTasks,
  compareUpNext,
  compareBacklog,
  isCollapsibleBacklogTask,
  toLocalDateString,
  type TaskSummary,
} from '~/services/tasks'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks, setStatus } = useTasks()
const { categories, fetchCategories } = useCategories()
const { mobile } = useDisplay()

await fetchFarms()
await fetchTasks()
await fetchCategories()

const today = computed(() => toLocalDateString(new Date()))

// `tasks` is already urgent-first / oldest-first within a tier (see
// `compareTasks`), but the home screen re-groups/re-sorts into "Up next" /
// "Backlog" below, so that upstream order isn't relied on here.
const outstandingTasks = computed(
  () => tasks.value?.filter((task) => task.status !== 'done') ?? [],
)

// Stat pills always summarize *all* outstanding tasks, unfiltered.
const overdueCount = computed(
  () => outstandingTasks.value.filter((task) => isTaskOverdue(task)).length,
)
const urgentCount = computed(
  () =>
    outstandingTasks.value.filter((task) => task.priority === 'urgent').length,
)

const homeGroups = computed(() => {
  const { upNext, backlog } = partitionHomeTasks(
    outstandingTasks.value,
    today.value,
  )
  return {
    upNext: [...upNext].sort(compareUpNext),
    backlog: [...backlog].sort(compareBacklog),
  }
})
const upNext = computed(() => homeGroups.value.upNext)
const backlog = computed(() => homeGroups.value.backlog)

// The backlog "tail" — lowest priority, no due date — is collapsed by
// default behind a "Show N more" toggle, unless those tasks are the only
// tasks on the whole page (nothing else to show instead).
const backlogVisible = computed(() =>
  backlog.value.filter((task) => !isCollapsibleBacklogTask(task)),
)
const backlogCollapsedTail = computed(() =>
  backlog.value.filter((task) => isCollapsibleBacklogTask(task)),
)
const showAllTasksAreCollapsible = computed(
  () =>
    upNext.value.length === 0 &&
    backlogVisible.value.length === 0 &&
    backlogCollapsedTail.value.length > 0,
)
const tailExpanded = ref(false)
const backlogDisplayed = computed(() =>
  showAllTasksAreCollapsible.value || tailExpanded.value
    ? backlog.value
    : backlogVisible.value,
)
const collapsedCount = computed(() =>
  showAllTasksAreCollapsible.value ? 0 : backlogCollapsedTail.value.length,
)

function categoryName(task: TaskSummary): string {
  return categoryDisplayName(task.category_id, categories.value).text
}

const updatingTaskId = ref<string | null>(null)
const snackbarMessage = ref<string | null>(null)
const showSnackbar = ref(false)

async function completeTask(task: TaskSummary) {
  updatingTaskId.value = task.id
  try {
    await setStatus(task.id, 'done')
  } catch (error) {
    snackbarMessage.value =
      error instanceof Error ? error.message : 'Failed to update status'
    showSnackbar.value = true
    // Make sure the list reflects reality rather than a stale/optimistic value.
    await fetchTasks()
  } finally {
    updatingTaskId.value = null
  }
}
</script>

<template>
  <v-container class="home">
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

      <template v-else>
        <div class="home__stats">
          <span class="cc-pill cc-pill--surface">
            {{ outstandingTasks.length }} open
          </span>
          <span
            class="cc-pill"
            :class="urgentCount > 0 ? 'cc-pill--urgent' : 'cc-pill--muted'"
          >
            {{ urgentCount }} urgent
          </span>
          <span
            class="cc-pill"
            :class="overdueCount > 0 ? 'cc-pill--error' : 'cc-pill--muted'"
          >
            {{ overdueCount }} overdue
          </span>
        </div>

        <div
          v-if="!tasks || tasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-clipboard-text-outline" size="64" class="mb-4" />
          <p class="text-body-1 mb-4">
            No tasks yet. Add one to start tracking work on this farm.
          </p>
          <v-btn color="primary" variant="tonal" size="large" to="/tasks/new"
            >New task</v-btn
          >
        </div>

        <div
          v-else-if="outstandingTasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-check-circle-outline" size="64" class="mb-4" />
          <p class="text-body-1">Nothing outstanding — every task is done.</p>
        </div>

        <template v-else>
          <section v-if="upNext.length > 0" class="home__section">
            <h2 class="cc-section-title home__section-heading">Up next</h2>
            <div class="home__cards">
              <TaskCard
                v-for="task in upNext"
                :key="task.id"
                :task="task"
                :category-name="categoryName(task)"
                :today="today"
                :updating="updatingTaskId === task.id"
                @complete="completeTask"
              />
            </div>
          </section>

          <section v-if="backlogDisplayed.length > 0" class="home__section">
            <div class="home__section-heading home__section-heading--row">
              <h2 class="cc-section-title">Backlog</h2>
              <span class="home__section-count">
                {{ backlog.length }}
                {{ backlog.length === 1 ? 'chore' : 'chores' }}
              </span>
            </div>
            <div class="home__cards">
              <TaskCard
                v-for="task in backlogDisplayed"
                :key="task.id"
                :task="task"
                :category-name="categoryName(task)"
                :today="today"
                :updating="updatingTaskId === task.id"
                @complete="completeTask"
              />
            </div>
          </section>

          <div v-if="collapsedCount > 0" class="mb-4">
            <button
              type="button"
              class="cc-text-link"
              @click="tailExpanded = !tailExpanded"
            >
              {{ tailExpanded ? 'Show less' : `Show ${collapsedCount} more` }}
            </button>
          </div>

          <div class="text-center mt-4">
            <NuxtLink to="/tasks" class="cc-text-link cc-text-link--muted">
              View all tasks
            </NuxtLink>
          </div>
        </template>
      </template>
    </template>

    <NuxtLink
      to="/tasks/new"
      class="home-fab"
      :class="{ 'home-fab--above-bottom-nav': mobile }"
      aria-label="New chore"
      title="New chore"
    >
      <v-icon icon="mdi-plus" size="20" />
      <span>New chore</span>
    </NuxtLink>

    <v-snackbar v-model="showSnackbar" color="error" :timeout="6000">
      {{ snackbarMessage }}
    </v-snackbar>
  </v-container>
</template>

<style scoped>
.home {
  max-width: 900px;
}

.home__stats {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 24px;
}

.home__section {
  margin-bottom: 24px;
}

.home__section-heading {
  margin-bottom: 12px;
}

.home__section-heading--row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
}

.home__section-count {
  color: var(--cc-ink-muted);
  font-size: 0.8125rem;
}

.home__cards {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* Floating pill "+ New chore" button: fixed bottom-right, above the mobile
   bottom nav (56px tall) when it's present so the two don't overlap. */
.home-fab {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 10;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: var(--cc-accent);
  color: var(--cc-accent-contrast);
  border-radius: 999px;
  padding: 12px 20px;
  font-weight: 600;
  font-size: 0.9375rem;
  text-decoration: none;
  box-shadow: 0 4px 12px rgba(43, 33, 24, 0.25);
}

.home-fab--above-bottom-nav {
  bottom: 80px;
}
</style>
