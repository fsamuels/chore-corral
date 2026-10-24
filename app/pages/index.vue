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
import {
  listFarmMemberProfiles,
  type FarmMemberProfile,
} from '~/services/members'
import { memberShortLabels } from '~/utils/member-display'
import { assigneeDisplayNames } from '~/utils/task-display'

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
// The home screen only shows outstanding work (SPEC: its list is scoped to
// the non-Done subset), so there's no reason to fetch a farm's full Done
// history here — see listTasks' `excludeDone` option.
const { tasks, tasksError, loading, fetchTasks } = useTasks({
  excludeDone: true,
})
const { categories, fetchCategories } = useCategories()
const { locations, fetchLocations } = useLocations()
const { runningEntry, refresh: refreshRunningTimer } = useRunningTimer()
const { thumbnailFor, onThumbnailError } = useTaskThumbnails(tasks)

// Farm members, resolved to short labels for the assignee indicator on each
// card — no composable exists for this (only the activity service reads
// farm_member_profiles), so it's a direct service call, refetched on farm
// switch like locations/categories above.
const members = ref<FarmMemberProfile[]>([])

async function fetchMembers() {
  const farmId = activeFarmId.value
  if (!farmId) {
    members.value = []
    return
  }
  members.value = await listFarmMemberProfiles(supabase, farmId)
}

// Farms must resolve first (tasks/categories/locations/members all key off
// activeFarmId, which is derived from the farm list), but once it has, the
// other four are independent of each other and safe to fetch concurrently.
await fetchFarms()
await Promise.all([
  fetchTasks(),
  fetchCategories(),
  fetchLocations(),
  fetchMembers(),
])
watch(activeFarmId, () => fetchMembers())

const memberLabels = computed(() => memberShortLabels(members.value))

function assigneeNames(task: TaskSummary): string[] {
  return assigneeDisplayNames(task.assignee_ids, memberLabels.value)
}

const today = computed(() => toLocalDateString(new Date()))

// `tasks` is already urgent-first / oldest-first within a tier (see
// `compareTasks`), but the home screen re-groups/re-sorts into "Up next" /
// "Backlog" below, so that upstream order isn't relied on here. Already
// excludes Done (see the `useTasks({ excludeDone: true })` call above).
const outstandingTasks = computed(() => tasks.value ?? [])

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

function locationName(task: TaskSummary): string | null {
  return locationDisplayName(task.location_id, locations.value)
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
  <div class="cc-page">
    <LoadErrorAlert
      v-if="farmsError"
      title="Couldn't load your farms"
      :message="farmsError"
      :retry="() => fetchFarms()"
    />
    <template v-else-if="activeFarm">
      <LoadErrorAlert
        v-if="tasksError"
        title="Couldn't load chores"
        :message="tasksError"
        :retry="() => fetchTasks()"
      />

      <ListSkeleton v-else-if="loading && tasks === null" />

      <template v-else>
        <div class="cc-stat-row">
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
          density="comfortable"
          variant="outlined"
          hide-details
          clearable
          class="home__search mb-4"
        />

        <EmptyState
          v-if="!tasks || tasks.length === 0"
          icon="mdi-clipboard-text-outline"
        >
          No chores yet. Add one to start tracking work on this farm.
          <template #action>
            <NuxtLink
              class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
              to="/tasks/new"
            >
              New chore
            </NuxtLink>
          </template>
        </EmptyState>

        <EmptyState
          v-else-if="outstandingTasks.length === 0"
          icon="mdi-check-circle-outline"
        >
          Nothing outstanding — every chore is done.
        </EmptyState>

        <EmptyState v-else-if="searchedTasks.length === 0" icon="mdi-magnify">
          No chores match “{{ searchQuery }}”.
        </EmptyState>

        <template v-else>
          <section v-if="upNext.length > 0" class="home__section">
            <h2 class="cc-section-title home__section-heading">Up next</h2>
            <div class="cc-card-list">
              <TaskCard
                v-for="task in upNext"
                :key="task.id"
                :task="task"
                :category-name="categoryName(task)"
                :category-emoji="categoryEmoji(task)"
                :location-name="locationName(task)"
                :assignee-names="assigneeNames(task)"
                :thumbnail-url="thumbnailFor(task)"
                :today="today"
                :updating="updatingTaskId === task.id"
                :timer-running="isTimerRunning(task)"
                @thumbnail-error="onThumbnailError"
                @toggle-timer="toggleTimer"
              />
            </div>
          </section>

          <section v-if="backlog.length > 0" class="home__section">
            <div class="cc-section-head home__section-heading">
              <h2 class="cc-section-title">Backlog</h2>
              <span class="cc-muted home__section-count">
                {{ backlog.length }}
                {{ backlog.length === 1 ? 'chore' : 'chores' }}
              </span>
            </div>
            <div class="cc-card-list">
              <TaskCard
                v-for="task in backlog"
                :key="task.id"
                :task="task"
                :category-name="categoryName(task)"
                :category-emoji="categoryEmoji(task)"
                :location-name="locationName(task)"
                :assignee-names="assigneeNames(task)"
                :thumbnail-url="thumbnailFor(task)"
                :today="today"
                :updating="updatingTaskId === task.id"
                :timer-running="isTimerRunning(task)"
                @thumbnail-error="onThumbnailError"
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
  </div>
</template>

<style scoped>
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

.home__section-count {
  font-size: 0.8125rem;
}
</style>
