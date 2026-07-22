<script setup lang="ts">
import type { Database } from '~/types/database.types'
import {
  isTaskOverdue,
  partitionHomeTasks,
  compareUpNext,
  compareBacklog,
  toLocalDateString,
  type TaskSummary,
} from '~/services/tasks'
import { startTimer, stopTimer } from '~/services/time-entries'
import { matchesSearch } from '~/utils/task-filters'

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks } = useTasks()
const { categories, fetchCategories } = useCategories()
const { runningEntry, refresh: refreshRunningTimer } = useRunningTimer()

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

const searchQuery = ref('')

// The quick search only narrows the "Up next" / "Backlog" groups below — the
// stat pills above stay a summary of *all* outstanding tasks regardless.
const searchedTasks = computed(() =>
  outstandingTasks.value.filter((task) =>
    matchesSearch(task, searchQuery.value),
  ),
)

const homeGroups = computed(() => {
  const { upNext, backlog } = partitionHomeTasks(
    searchedTasks.value,
    today.value,
  )
  return {
    upNext: [...upNext].sort(compareUpNext),
    backlog: [...backlog].sort(compareBacklog),
  }
})
const upNext = computed(() => homeGroups.value.upNext)
const backlog = computed(() => homeGroups.value.backlog)

function categoryName(task: TaskSummary): string {
  return categoryDisplayName(task.category_id, categories.value).text
}

function categoryEmoji(task: TaskSummary): string | null {
  return categories.value?.find((c) => c.id === task.category_id)?.emoji ?? null
}

// Which task, if any, currently holds the user's running timer.
function isTimerRunning(task: TaskSummary): boolean {
  return runningEntry.value?.task_id === task.id
}

const updatingTaskId = ref<string | null>(null)
const snackbarMessage = ref<string | null>(null)
const snackbarColor = ref<'error' | 'success'>('success')
const showSnackbar = ref(false)

function notify(message: string, color: 'error' | 'success') {
  snackbarMessage.value = message
  snackbarColor.value = color
  showSnackbar.value = true
}

/**
 * Start this task's timer, or stop it if it's already the running one. Starting
 * can flip the task to in_progress and auto-stop a timer on another task (both
 * handled service-side), so afterward we refetch tasks and the running-timer
 * state to reflect whatever actually happened.
 */
async function toggleTimer(task: TaskSummary) {
  const farmId = activeFarmId.value
  const actorUserId = getActorUserId(user.value)
  if (!farmId || !actorUserId) return

  const running = runningEntry.value
  updatingTaskId.value = task.id
  try {
    if (running && running.task_id === task.id) {
      await stopTimer(supabase, running.id)
      notify(`Timer stopped for “${task.title}”`, 'success')
    } else {
      await startTimer(supabase, { farmId, taskId: task.id, actorUserId })
      notify(`Timer started for “${task.title}”`, 'success')
    }
    await refreshRunningTimer()
    await fetchTasks()
  } catch (error) {
    notify(
      error instanceof Error ? error.message : 'Failed to update timer',
      'error',
    )
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
        title="Couldn't load chores"
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

        <v-text-field
          v-if="outstandingTasks.length > 0"
          v-model="searchQuery"
          placeholder="Search chores"
          prepend-inner-icon="mdi-magnify"
          density="compact"
          variant="outlined"
          hide-details
          clearable
          class="home__search mb-4"
        />

        <div
          v-if="!tasks || tasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-clipboard-text-outline" size="64" class="mb-4" />
          <p class="text-body-1 mb-4">
            No chores yet. Add one to start tracking work on this farm.
          </p>
          <v-btn color="primary" variant="tonal" size="large" to="/tasks/new"
            >New chore</v-btn
          >
        </div>

        <div
          v-else-if="outstandingTasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-check-circle-outline" size="64" class="mb-4" />
          <p class="text-body-1">Nothing outstanding — every chore is done.</p>
        </div>

        <div
          v-else-if="searchedTasks.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-magnify" size="64" class="mb-4" />
          <p class="text-body-1">No chores match “{{ searchQuery }}”.</p>
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
                :category-emoji="categoryEmoji(task)"
                :today="today"
                :updating="updatingTaskId === task.id"
                :timer-running="isTimerRunning(task)"
                @toggle-timer="toggleTimer"
              />
            </div>
          </section>

          <section v-if="backlog.length > 0" class="home__section">
            <div class="home__section-heading home__section-heading--row">
              <h2 class="cc-section-title">Backlog</h2>
              <span class="home__section-count">
                {{ backlog.length }}
                {{ backlog.length === 1 ? 'chore' : 'chores' }}
              </span>
            </div>
            <div class="home__cards">
              <TaskCard
                v-for="task in backlog"
                :key="task.id"
                :task="task"
                :category-name="categoryName(task)"
                :category-emoji="categoryEmoji(task)"
                :today="today"
                :updating="updatingTaskId === task.id"
                :timer-running="isTimerRunning(task)"
                @toggle-timer="toggleTimer"
              />
            </div>
          </section>

          <div class="text-center mt-4">
            <NuxtLink to="/tasks" class="cc-text-link cc-text-link--muted">
              View all chores
            </NuxtLink>
          </div>
        </template>
      </template>
    </template>

    <v-snackbar v-model="showSnackbar" :color="snackbarColor" :timeout="4000">
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

.home__search {
  max-width: 320px;
}

@media (max-width: 600px) {
  .home__search {
    max-width: 100%;
  }
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
</style>
