<script setup lang="ts">
import {
  isTaskOverdue,
  partitionHomeTasks,
  compareUpNext,
  compareBacklog,
  isCollapsibleBacklogTask,
  toLocalDateString,
  type TaskStatus,
  type TaskSummary,
} from '~/services/tasks'
import {
  PRIORITY_DISPLAY,
  STATUS_DISPLAY,
  formatDueDate,
} from '~/utils/task-display'

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

// Stat chips always summarize *all* outstanding tasks, unfiltered.
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

function nextStatus(status: TaskStatus): TaskStatus | null {
  if (status === 'not_started') return 'in_progress'
  if (status === 'in_progress') return 'done'
  return null
}

function statusActionIcon(status: TaskStatus): string {
  return status === 'in_progress'
    ? 'mdi-check-circle-outline'
    : 'mdi-play-circle-outline'
}

function statusActionLabel(status: TaskStatus): string {
  return status === 'in_progress' ? 'Mark done' : 'Start'
}

async function advanceStatus(task: TaskSummary) {
  const next = nextStatus(task.status)
  if (!next) return
  updatingTaskId.value = task.id
  try {
    await setStatus(task.id, next)
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
        <div class="d-flex flex-wrap ga-2 mb-6">
          <v-chip size="small" variant="tonal">
            {{ outstandingTasks.length }} outstanding
          </v-chip>
          <v-chip
            size="small"
            variant="tonal"
            :color="urgentCount > 0 ? 'warning' : undefined"
          >
            {{ urgentCount }} urgent
          </v-chip>
          <v-chip
            size="small"
            variant="tonal"
            :color="overdueCount > 0 ? 'error' : undefined"
          >
            {{ overdueCount }} overdue
          </v-chip>
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
          <v-list v-if="upNext.length > 0" lines="two" class="mb-2">
            <v-list-subheader>Up next</v-list-subheader>
            <v-list-item
              v-for="task in upNext"
              :key="task.id"
              :to="`/tasks/${task.id}`"
              border
              rounded
              elevation="1"
              class="mb-2 task-row"
              :class="`task-row--${task.priority}`"
            >
              <template #prepend>
                <v-btn
                  v-if="nextStatus(task.status)"
                  variant="text"
                  :icon="statusActionIcon(task.status)"
                  :aria-label="statusActionLabel(task.status)"
                  :title="statusActionLabel(task.status)"
                  :loading="updatingTaskId === task.id"
                  class="mr-2"
                  @click.stop.prevent="advanceStatus(task)"
                />
                <v-icon
                  v-else
                  :icon="STATUS_DISPLAY[task.status].icon"
                  :aria-label="STATUS_DISPLAY[task.status].label"
                  :title="STATUS_DISPLAY[task.status].label"
                  class="mr-2"
                />
              </template>
              <v-list-item-title :class="{ 'text-error': isTaskOverdue(task) }">
                {{ task.title }}
              </v-list-item-title>
              <v-list-item-subtitle>
                {{ categoryName(task) }}
                <template v-if="task.due_date">
                  ·
                  <span :class="{ 'text-error': isTaskOverdue(task) }">
                    {{ formatDueDate(task.due_date, today) }}
                  </span>
                </template>
              </v-list-item-subtitle>
              <template #append>
                <div class="d-flex align-center ga-2 text-medium-emphasis">
                  <v-icon
                    v-if="task.lat !== null && task.lng !== null"
                    icon="mdi-map-marker-outline"
                    size="small"
                    aria-label="Has location"
                    title="Has location"
                  />
                  <span
                    v-if="task.photo_count > 0"
                    class="d-flex align-center ga-1"
                  >
                    <v-icon
                      icon="mdi-image-outline"
                      size="small"
                      aria-label="Has photos"
                      title="Has photos"
                    />
                    <span v-if="task.photo_count > 1" class="text-caption">
                      {{ task.photo_count }}
                    </span>
                  </span>
                  <v-icon
                    :icon="PRIORITY_DISPLAY[task.priority].icon"
                    size="small"
                    :aria-label="`${PRIORITY_DISPLAY[task.priority].label} priority`"
                    :title="`${PRIORITY_DISPLAY[task.priority].label} priority`"
                  />
                </div>
              </template>
            </v-list-item>
          </v-list>

          <v-list v-if="backlogDisplayed.length > 0" lines="two" class="mb-2">
            <v-list-subheader>Backlog</v-list-subheader>
            <v-list-item
              v-for="task in backlogDisplayed"
              :key="task.id"
              :to="`/tasks/${task.id}`"
              border
              rounded
              elevation="1"
              class="mb-2 task-row"
              :class="`task-row--${task.priority}`"
            >
              <template #prepend>
                <v-btn
                  v-if="nextStatus(task.status)"
                  variant="text"
                  :icon="statusActionIcon(task.status)"
                  :aria-label="statusActionLabel(task.status)"
                  :title="statusActionLabel(task.status)"
                  :loading="updatingTaskId === task.id"
                  class="mr-2"
                  @click.stop.prevent="advanceStatus(task)"
                />
                <v-icon
                  v-else
                  :icon="STATUS_DISPLAY[task.status].icon"
                  :aria-label="STATUS_DISPLAY[task.status].label"
                  :title="STATUS_DISPLAY[task.status].label"
                  class="mr-2"
                />
              </template>
              <v-list-item-title :class="{ 'text-error': isTaskOverdue(task) }">
                {{ task.title }}
              </v-list-item-title>
              <v-list-item-subtitle>
                {{ categoryName(task) }}
                <template v-if="task.due_date">
                  ·
                  <span :class="{ 'text-error': isTaskOverdue(task) }">
                    {{ formatDueDate(task.due_date, today) }}
                  </span>
                </template>
              </v-list-item-subtitle>
              <template #append>
                <div class="d-flex align-center ga-2 text-medium-emphasis">
                  <v-icon
                    v-if="task.lat !== null && task.lng !== null"
                    icon="mdi-map-marker-outline"
                    size="small"
                    aria-label="Has location"
                    title="Has location"
                  />
                  <span
                    v-if="task.photo_count > 0"
                    class="d-flex align-center ga-1"
                  >
                    <v-icon
                      icon="mdi-image-outline"
                      size="small"
                      aria-label="Has photos"
                      title="Has photos"
                    />
                    <span v-if="task.photo_count > 1" class="text-caption">
                      {{ task.photo_count }}
                    </span>
                  </span>
                  <v-icon
                    :icon="PRIORITY_DISPLAY[task.priority].icon"
                    size="small"
                    :aria-label="`${PRIORITY_DISPLAY[task.priority].label} priority`"
                    :title="`${PRIORITY_DISPLAY[task.priority].label} priority`"
                  />
                </div>
              </template>
            </v-list-item>
          </v-list>

          <div v-if="collapsedCount > 0" class="mb-4">
            <v-btn
              variant="text"
              density="comfortable"
              @click="tailExpanded = !tailExpanded"
            >
              {{ tailExpanded ? 'Show less' : `Show ${collapsedCount} more` }}
            </v-btn>
          </div>

          <div class="text-center mt-2">
            <v-btn variant="text" to="/tasks">View all tasks</v-btn>
          </div>
        </template>
      </template>
    </template>

    <v-btn
      icon="mdi-plus"
      color="primary"
      size="large"
      elevation="6"
      class="home-fab"
      :class="{ 'home-fab--above-bottom-nav': mobile }"
      aria-label="Add task"
      title="Add task"
      to="/tasks/new"
    />

    <v-snackbar v-model="showSnackbar" color="error" :timeout="6000">
      {{ snackbarMessage }}
    </v-snackbar>
  </v-container>
</template>

<style scoped>
.task-row {
  border-left: 4px solid transparent;
}

.task-row--urgent {
  border-left-color: rgb(var(--v-theme-error));
}

.task-row--soon {
  border-left-color: rgb(var(--v-theme-warning));
}

/* Material Design FAB: fixed bottom-right, above the mobile bottom nav
   (56px tall) when it's present so the two don't overlap. */
.home-fab {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 10;
}

.home-fab--above-bottom-nav {
  bottom: 80px;
}
</style>
