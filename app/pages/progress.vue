<script setup lang="ts">
import type { Database } from '~/types/database.types'
import {
  addWeeks,
  buildActivityDayGroups,
  completedTasksInWeek,
  listTaskActivity,
  weekDays,
  weekStartFor,
  type ActivityDayRow,
  type ActivityKind,
  type TaskActivity,
} from '~/services/progress'
import { parseLocalDateString } from '~/services/tasks'
import {
  listFarmMemberProfiles,
  type FarmMemberProfile,
} from '~/services/members'
import { formatElapsedDuration } from '~/utils/task-display'

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient<Database>()

const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
const { completedTasks, completedTasksError, loading, fetchCompletedTasks } =
  useWeeklyProgress()
const { categories, fetchCategories } = useCategories()

// Fetch farms first so the active farm resolves during SSR, then the farm's
// completed-task history and categories (the composables' watch covers later
// farm switches).
await fetchFarms()
await fetchCompletedTasks()
await fetchCategories()

// Farm members, for resolving completer `user_id` uuids to emails. No composable
// exists for this (only the activity/task-detail pages need it), so it's a
// direct service call into a local ref — same pattern as the task detail
// page — fetched once per farm and refetched on farm switch.
const members = ref<FarmMemberProfile[]>([])
async function fetchMembers() {
  const farmId = activeFarmId.value
  if (!farmId) {
    members.value = []
    return
  }
  try {
    members.value = await listFarmMemberProfiles(supabase, farmId)
  } catch {
    // Attribution is decorative on this page — a failed member lookup
    // shouldn't take the whole page down; affected rows degrade to
    // "unknown member".
    members.value = []
  }
}
await fetchMembers()
watch(activeFarmId, () => fetchMembers())

/**
 * The Monday ("YYYY-MM-DD") of the currently-displayed week, derived from
 * the `?week=` query param. Missing, unparseable, or otherwise invalid
 * values fall back to the current week; any other valid date snaps to its
 * own week's Monday (`weekStartFor` is idempotent for a date that's already
 * a Monday), so a deep link doesn't need to already point at one.
 */
function resolveWeekStart(raw: unknown): string {
  const current = weekStartFor(new Date())
  if (typeof raw !== 'string') return current
  try {
    const parsed = parseLocalDateString(raw)
    if (Number.isNaN(parsed.getTime())) return current
    const week = weekStartFor(parsed)
    // Never show a future week: the next-week arrow already stops at the
    // current week, and a deep link past it clamps the same way ("YYYY-MM-DD"
    // strings compare correctly as strings).
    return week > current ? current : week
  } catch {
    return current
  }
}

const currentWeekStart = computed(() => weekStartFor(new Date()))
const shownWeek = computed(() => resolveWeekStart(route.query.week))
const isCurrentWeek = computed(() => shownWeek.value === currentWeekStart.value)

function goToWeek(week: string) {
  router.replace({ query: { ...route.query, week } })
}
function goToPreviousWeek() {
  goToWeek(addWeeks(shownWeek.value, -1))
}
function goToNextWeek() {
  if (isCurrentWeek.value) return
  goToWeek(addWeeks(shownWeek.value, 1))
}

// Label + always-shown date range for the week navigator header, e.g.
// "This week · Jul 7 – Jul 13" or just "Jun 1 – Jun 7" for any other week.
const weekLabel = computed(() => {
  if (isCurrentWeek.value) return 'This week'
  if (shownWeek.value === addWeeks(currentWeekStart.value, -1))
    return 'Last week'
  return null
})

function formatRangeDate(day: string, includeYear: boolean): string {
  return parseLocalDateString(day).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: includeYear ? 'numeric' : undefined,
  })
}

const weekRangeText = computed(() => {
  const days = weekDays(shownWeek.value)
  const start = days[0]!
  const end = days[6]!
  const thisYear = new Date().getFullYear()
  const startText = formatRangeDate(
    start,
    parseLocalDateString(start).getFullYear() !== thisYear,
  )
  const endText = formatRangeDate(
    end,
    parseLocalDateString(end).getFullYear() !== thisYear,
  )
  return `${startText} – ${endText}`
})

const weekHeaderText = computed(() =>
  weekLabel.value
    ? `${weekLabel.value} · ${weekRangeText.value}`
    : weekRangeText.value,
)

// This week's completed tasks, sliced client-side from the farm's full
// completed-task history — switching weeks never refetches.
const weekTasks = computed(() =>
  completedTasksInWeek(completedTasks.value ?? [], shownWeek.value),
)

// The farm's tasks that have time-entry activity, with their raw entries.
// Fetched once per farm into a local ref — same direct-service pattern as
// `members` above — and sliced per week by `buildActivityDayGroups`, so
// switching weeks never refetches. Backs the "worked on but not completed
// today" rows and the per-day / per-week tracked-time figures.
const activities = ref<TaskActivity[]>([])
async function fetchActivities() {
  const farmId = activeFarmId.value
  if (!farmId) {
    activities.value = []
    return
  }
  try {
    activities.value = await listTaskActivity(supabase, farmId)
  } catch {
    // Activity rows enhance the completed-task list — a failed fetch degrades
    // the page to "completed tasks only" rather than taking it down.
    activities.value = []
  }
}
await fetchActivities()
watch(activeFarmId, () => fetchActivities())

function categoryPill(
  categoryId: string | null,
): { text: string; emoji: string | null } | null {
  if (categoryId === null) return null
  const category = categories.value?.find((c) => c.id === categoryId)
  return {
    text: category?.name ?? '(deleted category)',
    emoji: category?.emoji ?? null,
  }
}

// Mirrors the task detail page's `completedByLabel`: each completer resolved to
// a member's email (best-effort — "unknown member" if the id isn't in the
// fetched list) or its free-text name, comma-joined; null when the set is empty.
function completedByLabel(
  row: Pick<ActivityDayRow, 'completers'>,
): string | null {
  if (row.completers.length === 0) return null
  return row.completers
    .map((completer) =>
      completer.user_id !== null
        ? (members.value.find((m) => m.user_id === completer.user_id)?.email ??
          'unknown member')
        : completer.completer_name,
    )
    .join(', ')
}

function formatRowTime(timestamp: string): string {
  return new Date(timestamp).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  })
}

// The status chip a worked-on row shows so the day reads as "what happened
// today": a completed row shows none, a task finished on another day reads
// "done later", and one still open reads "in progress".
const STATUS_LABELS: Record<ActivityKind, string | null> = {
  completed: null,
  'done-later': 'done later',
  'in-progress': 'in progress',
}

interface ProgressRow {
  id: string
  title: string
  time: string
  tracked: string | null
  kind: ActivityKind
  statusLabel: string | null
  completedBy: string | null
  category: { text: string; emoji: string | null } | null
}

interface ProgressDayGroup {
  day: string
  heading: string
  completed: number
  tracked: string | null
  rows: ProgressRow[]
}

// The week's day-by-day activity: completed tasks merged with worked-on-but-
// not-completed-today tasks, plus each day's completed count and tracked total
// (see `buildActivityDayGroups`). Recomputes purely from the two already-
// fetched lists when the viewed week changes — no refetch.
const activityGroups = computed(() =>
  buildActivityDayGroups(shownWeek.value, weekTasks.value, activities.value),
)

const dayGroups = computed<ProgressDayGroup[]>(() =>
  activityGroups.value.map((group) => ({
    day: group.day,
    heading: parseLocalDateString(group.day).toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
    }),
    completed: group.completedCount,
    tracked:
      group.trackedMs > 0 ? formatElapsedDuration(group.trackedMs) : null,
    rows: group.rows.map((row) => ({
      id: row.id,
      title: row.title,
      time: formatRowTime(row.timestamp),
      tracked: row.trackedMs > 0 ? formatElapsedDuration(row.trackedMs) : null,
      kind: row.kind,
      statusLabel: STATUS_LABELS[row.kind],
      completedBy: row.kind === 'completed' ? completedByLabel(row) : null,
      category: categoryPill(row.category_id),
    })),
  })),
)

// Week "tracked" now means time tracked *during* the week — the sum of the
// per-day totals (entries whose timer started in the week) — rather than the
// old "time on tasks completed this week". That keeps the week pill equal to
// the sum of the day headings, and counts work on tasks not finished this week.
const weekTrackedMs = computed(() =>
  activityGroups.value.reduce((sum, group) => sum + group.trackedMs, 0),
)
const weekTrackedText = computed(() =>
  formatElapsedDuration(weekTrackedMs.value),
)
</script>

<template>
  <v-container class="progress">
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
      <h1 class="text-h4 mb-1">Progress</h1>
      <p class="cc-eyebrow mb-6">{{ activeFarm.name }}</p>

      <div class="progress-week">
        <button
          type="button"
          class="cc-icon-btn"
          aria-label="Previous week"
          title="Previous week"
          @click="goToPreviousWeek"
        >
          <v-icon icon="mdi-chevron-left" size="22" />
        </button>
        <div class="progress-week__label">{{ weekHeaderText }}</div>
        <button
          type="button"
          class="cc-icon-btn"
          aria-label="Next week"
          title="Next week"
          :disabled="isCurrentWeek"
          @click="goToNextWeek"
        >
          <v-icon icon="mdi-chevron-right" size="22" />
        </button>
      </div>

      <v-alert
        v-if="completedTasksError"
        type="error"
        variant="tonal"
        title="Couldn't load progress"
        class="mb-4"
      >
        {{ completedTasksError }} — try reloading; if this persists, the
        database may not be reachable.
      </v-alert>

      <div
        v-else-if="loading && completedTasks === null"
        class="text-center py-8"
      >
        <v-progress-circular indeterminate color="primary" />
      </div>

      <template v-else>
        <div class="progress-stats">
          <span class="cc-pill cc-pill--surface">
            {{ weekTasks.length }} completed
          </span>
          <span v-if="weekTrackedMs > 0" class="cc-pill cc-pill--surface">
            {{ weekTrackedText }} tracked
          </span>
        </div>

        <div
          v-if="dayGroups.length === 0"
          class="text-center py-12 text-medium-emphasis"
        >
          <v-icon icon="mdi-progress-check" size="64" class="mb-4" />
          <p class="text-body-1">
            No activity {{ isCurrentWeek ? 'this week' : 'that week' }}.
          </p>
        </div>

        <div v-else class="progress-days">
          <section
            v-for="group in dayGroups"
            :key="group.day"
            class="progress-day"
          >
            <div class="progress-day__head">
              <h2 class="cc-section-title progress-day__heading">
                {{ group.heading }}
              </h2>
              <div class="progress-day__metrics">
                <span class="cc-pill cc-pill--muted">
                  {{ group.completed }} completed
                </span>
                <span v-if="group.tracked" class="cc-pill cc-pill--muted">
                  <v-icon icon="mdi-timer-outline" size="14" />
                  {{ group.tracked }}
                </span>
              </div>
            </div>
            <div class="progress-day__rows">
              <NuxtLink
                v-for="row in group.rows"
                :key="row.id"
                :to="`/tasks/${row.id}`"
                class="cc-card progress-row"
                :class="{ 'progress-row--worked': row.kind !== 'completed' }"
              >
                <div class="progress-row__time">{{ row.time }}</div>
                <div class="progress-row__title">{{ row.title }}</div>
                <div
                  v-if="
                    row.statusLabel ||
                    row.completedBy ||
                    row.category ||
                    row.tracked
                  "
                  class="progress-row__meta"
                >
                  <span
                    v-if="row.statusLabel"
                    class="cc-pill progress-row__status"
                    :class="
                      row.kind === 'in-progress'
                        ? 'progress-row__status--active'
                        : 'cc-pill--muted'
                    "
                  >
                    {{ row.statusLabel }}
                  </span>
                  <span v-if="row.completedBy" class="progress-row__by">
                    {{ row.completedBy }}
                  </span>
                  <span v-if="row.tracked" class="progress-row__tracked">
                    <v-icon icon="mdi-timer-outline" size="14" />
                    {{ row.tracked }}
                  </span>
                  <span
                    v-if="row.category"
                    class="cc-pill cc-pill--muted progress-row__category"
                  >
                    <span v-if="row.category.emoji" aria-hidden="true">
                      {{ row.category.emoji }}
                    </span>
                    {{ row.category.text }}
                  </span>
                </div>
              </NuxtLink>
            </div>
          </section>
        </div>
      </template>
    </template>
  </v-container>
</template>

<style scoped>
.progress {
  max-width: 900px;
}

.progress-week {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-bottom: 24px;
}

.progress-week__label {
  flex: 1;
  text-align: center;
  font-family: var(--cc-font-slab);
  font-weight: 600;
  color: var(--cc-ink);
}

.progress-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 24px;
}

.progress-days {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.progress-day__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px 12px;
  margin-bottom: 12px;
}

.progress-day__heading {
  margin-bottom: 0;
}

.progress-day__metrics {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.progress-day__rows {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* Worked-on-but-not-completed-today rows: a muted accent rail sets them
   apart from the day's completed rows without shouting. */
.progress-row--worked {
  border-inline-start: 3px solid var(--cc-border);
}

.progress-row__status {
  font-size: 0.75rem;
  padding: 2px 10px;
}

.progress-row__status--active {
  background: var(--cc-accent);
  color: var(--cc-accent-contrast);
}

.progress-row {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 12px 16px;
  text-decoration: none;
  color: var(--cc-ink);
}

.progress-row__time {
  font-size: 0.8125rem;
  color: var(--cc-ink-muted);
}

.progress-row__title {
  font-family: var(--cc-font-slab);
  font-size: 1.0625rem;
  font-weight: 600;
  line-height: 1.3;
  overflow-wrap: anywhere;
}

.progress-row__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
  font-size: 0.8125rem;
  color: var(--cc-ink-muted);
}

.progress-row__category {
  font-size: 0.75rem;
  padding: 2px 10px;
}

.progress-row__tracked {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}
</style>
