<script setup lang="ts">
import { totalTrackedMs, type TimeEntrySummary } from '~/services/time-entries'
import { parseLocalDateString, toLocalDateString } from '~/services/tasks'

// Start/stop timer + tracked-time total for the View page. Only rendered
// once a task exists (parent guards with v-if="task"), so a task id is
// always present. `estimatedMinutes` lets the total render as
// "actual / estimate" when the task has an estimate.
const props = defineProps<{
  taskId: string
  estimatedMinutes: number | null
}>()

// Starting a timer can flip the task to in_progress server-side — the
// parent listens to refetch the task so the status select stays true.
const emit = defineEmits<{ started: []; completed: [] }>()

const {
  entries,
  runningEntry,
  entriesError,
  loading,
  mutating,
  mutationError,
  start,
  stop,
  updateEntry,
  removeEntry,
} = useTaskTimer(toRef(props, 'taskId'))

const runningHere = computed(() => runningEntry.value?.task_id === props.taskId)
const runningElsewhere = computed(
  () => runningEntry.value !== null && !runningHere.value,
)

// 1s ticker drives the live total while a timer runs on this task; paused
// otherwise so an idle View page does no work.
const now = ref(new Date())
let ticker: ReturnType<typeof setInterval> | undefined
watch(
  runningHere,
  (running) => {
    if (running && !ticker) {
      ticker = setInterval(() => (now.value = new Date()), 1000)
    } else if (!running && ticker) {
      clearInterval(ticker)
      ticker = undefined
    }
  },
  { immediate: true },
)
onUnmounted(() => {
  if (ticker) clearInterval(ticker)
})

const trackedMs = computed(() => totalTrackedMs(entries.value ?? [], now.value))

// Elapsed time of just the currently-running session on this task (the open
// entry's started_at → now). Zero when no timer is running here — the
// template only surfaces this counter while running, so it never renders 0.
const sessionMs = computed(() => {
  const entry = runningEntry.value
  if (!entry || entry.task_id !== props.taskId) return 0
  return totalTrackedMs([entry], now.value)
})

// "1h 30m 5s" (seconds shown while a timer is ticking or for sub-minute
// totals, so a short session isn't rendered as a confusing "0m"), "1h 30m"
// otherwise.
function formatTracked(ms: number, withSeconds: boolean): string {
  const totalSeconds = Math.floor(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  if (withSeconds || minutes === 0) {
    return minutes === 0
      ? `${seconds}s`
      : `${formatEstimatedMinutes(minutes)} ${seconds}s`
  }
  return formatEstimatedMinutes(minutes)
}

const trackedLabel = computed(() =>
  formatTracked(trackedMs.value, runningHere.value),
)
// The session counter only shows while running, so it always ticks seconds.
const sessionLabel = computed(() => formatTracked(sessionMs.value, true))

// When the running entry is the only entry, Total would duplicate "This
// session" tick-for-tick — hide it, and move the estimate note (if any)
// under the session counter so it doesn't vanish during a first session.
const showTotal = computed(
  () => !(runningHere.value && entries.value?.length === 1),
)

async function onStart(): Promise<void> {
  if (await start()) emit('started')
}

async function onStopAndComplete(): Promise<void> {
  await stop()
  if (!mutationError.value) emit('completed')
}

// --- Sessions disclosure: a collapsed per-entry list under the buttons ---
const sessionsOpen = ref(false)
const sessionsLabel = computed(() => {
  const count = entries.value?.length ?? 0
  return count === 1 ? '1 session' : `${count} sessions`
})

// "Jan 5 · 8:00 AM – 9:30 AM" — the end date is prefixed too when the
// session spans midnight, and a running entry's end reads "now".
function entryRangeLabel(entry: TimeEntrySummary): string {
  const start = new Date(entry.started_at)
  const startDate = formatEntryDate(start)
  const startTime = formatEntryTime(start)
  if (entry.ended_at === null) return `${startDate} · ${startTime} – now`
  const end = new Date(entry.ended_at)
  const endDate = formatEntryDate(end)
  const endTime = formatEntryTime(end)
  return endDate === startDate
    ? `${startDate} · ${startTime} – ${endTime}`
    : `${startDate} · ${startTime} – ${endDate} · ${endTime}`
}

function formatEntryDate(date: Date): string {
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

function formatEntryTime(date: Date): string {
  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  })
}

// A running entry's duration ticks with the shared 1s `now` (which only
// runs while a timer runs here — the only time a running row exists).
function entryDurationLabel(entry: TimeEntrySummary): string {
  const running = entry.ended_at === null
  return formatTracked(totalTrackedMs([entry], now.value), running)
}

// --- Inline session editing (one row at a time; explicit Save/Cancel per
// the tags-editing convention — four compact date/time fields combined via
// combineDateAndTime rather than two heavyweight inline v-date-pickers) ---
const editingEntryId = ref<string | null>(null)
const editStartDate = ref('')
const editStartTime = ref('')
const editEndDate = ref('')
const editEndTime = ref('')
const editError = ref<string | null>(null)

function startEditingEntry(entry: TimeEntrySummary): void {
  // Only closed entries are editable — the running entry has no edit button,
  // and the service guard backstops a stale click.
  if (entry.ended_at === null) return
  const start = new Date(entry.started_at)
  const end = new Date(entry.ended_at)
  editStartDate.value = toLocalDateString(start)
  editStartTime.value = formatTimeForInput(start)
  editEndDate.value = toLocalDateString(end)
  editEndTime.value = formatTimeForInput(end)
  editError.value = null
  editingEntryId.value = entry.id
}

function onEditCancel(): void {
  editingEntryId.value = null
  editError.value = null
}

async function onEditSave(): Promise<void> {
  const entryId = editingEntryId.value
  if (!entryId) return
  // Client-side range check with an inline message — the DB's
  // `ended_at > started_at` constraint backstops it, but a raised
  // constraint error reads far worse than this.
  editError.value = null
  const start = editStartDate.value
    ? combineDateAndTime(
        parseLocalDateString(editStartDate.value),
        editStartTime.value,
      )
    : null
  const end = editEndDate.value
    ? combineDateAndTime(
        parseLocalDateString(editEndDate.value),
        editEndTime.value,
      )
    : null
  if (!start || !end) {
    editError.value = 'Enter a start and end date and time.'
    return
  }
  if (end.getTime() <= start.getTime()) {
    editError.value = 'End time must be after the start time.'
    return
  }
  if (await updateEntry(entryId, start.toISOString(), end.toISOString())) {
    editingEntryId.value = null
  }
}

// --- Session delete (confirm dialog, mirroring the task-delete pattern) ---
const confirmingDeleteEntry = ref<TimeEntrySummary | null>(null)

const deleteDurationLabel = computed(() => {
  const entry = confirmingDeleteEntry.value
  return entry ? formatTracked(totalTrackedMs([entry], now.value), false) : ''
})

async function performDeleteEntry(): Promise<void> {
  const entry = confirmingDeleteEntry.value
  if (!entry) return
  // Close the dialog either way — a failure's message shows in the
  // mutationError alert at the top of the card.
  await removeEntry(entry.id)
  confirmingDeleteEntry.value = null
}
</script>

<template>
  <div>
    <p class="cc-eyebrow mb-2">Time tracked</p>

    <v-alert
      v-if="entriesError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ entriesError }}
    </v-alert>

    <v-alert
      v-if="mutationError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ mutationError }}
    </v-alert>

    <div v-if="entries === null && loading" class="py-2">
      <v-progress-circular indeterminate size="24" color="primary" />
    </div>

    <template v-else-if="entries">
      <div class="cc-timer-readout mb-3">
        <div v-if="runningHere" class="cc-timer-stat">
          <span class="cc-eyebrow">This session</span>
          <span class="cc-timer-time cc-timer-time--running">
            {{ sessionLabel }}
          </span>
          <span
            v-if="!showTotal && estimatedMinutes !== null"
            class="text-body-2 text-medium-emphasis"
          >
            of {{ formatEstimatedMinutes(estimatedMinutes) }} estimated
          </span>
        </div>
        <div v-if="showTotal" class="cc-timer-stat">
          <span class="cc-eyebrow">Total</span>
          <span
            class="cc-timer-time"
            :class="{ 'cc-timer-time--running': runningHere }"
          >
            <template v-if="trackedMs > 0 || runningHere">{{
              trackedLabel
            }}</template>
            <template v-else>0s</template>
          </span>
          <span
            v-if="estimatedMinutes !== null"
            class="text-body-2 text-medium-emphasis"
          >
            of {{ formatEstimatedMinutes(estimatedMinutes) }} estimated
          </span>
          <span
            v-else-if="trackedMs === 0 && !runningHere"
            class="text-body-2 text-medium-emphasis"
          >
            No time tracked yet.
          </span>
        </div>
      </div>

      <div class="cc-timer-actions">
        <template v-if="runningHere">
          <button
            type="button"
            class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--lg cc-timer-btn"
            :disabled="mutating"
            @click="stop"
          >
            <v-progress-circular
              v-if="mutating"
              indeterminate
              size="18"
              width="2"
            />
            <v-icon v-else icon="mdi-pause" size="20" />
            Pause
          </button>
          <button
            type="button"
            class="cc-pill-btn cc-pill-btn--success cc-pill-btn--lg cc-timer-btn"
            :disabled="mutating"
            @click="onStopAndComplete"
          >
            <v-progress-circular
              v-if="mutating"
              indeterminate
              size="18"
              width="2"
            />
            <v-icon v-else icon="mdi-check-circle-outline" size="20" />
            Complete task
          </button>
        </template>
        <button
          v-else
          type="button"
          class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg cc-timer-btn cc-pill-btn--full"
          :disabled="mutating"
          @click="onStart"
        >
          <v-progress-circular
            v-if="mutating"
            indeterminate
            size="18"
            width="2"
          />
          <v-icon v-else icon="mdi-play" size="20" />
          {{ trackedMs > 0 ? 'Resume timer' : 'Start timer' }}
        </button>
      </div>

      <div v-if="entries.length > 0" class="mt-3">
        <button
          type="button"
          class="cc-text-link cc-text-link--muted cc-timer-sessions-toggle"
          @click="sessionsOpen = !sessionsOpen"
        >
          {{ sessionsLabel }}
          <v-icon
            :icon="sessionsOpen ? 'mdi-chevron-up' : 'mdi-chevron-down'"
            size="18"
          />
        </button>

        <div v-if="sessionsOpen" class="mt-1">
          <div
            v-for="sessionEntry in entries"
            :key="sessionEntry.id"
            class="cc-timer-session"
          >
            <div
              v-if="editingEntryId === sessionEntry.id"
              class="cc-timer-session-edit"
            >
              <div class="cc-timer-session-edit__fields">
                <v-text-field
                  v-model="editStartDate"
                  type="date"
                  label="Start date"
                  density="compact"
                  variant="outlined"
                  hide-details
                  :disabled="mutating"
                />
                <v-text-field
                  v-model="editStartTime"
                  type="time"
                  label="Start time"
                  density="compact"
                  variant="outlined"
                  hide-details
                  :disabled="mutating"
                />
                <v-text-field
                  v-model="editEndDate"
                  type="date"
                  label="End date"
                  density="compact"
                  variant="outlined"
                  hide-details
                  :disabled="mutating"
                />
                <v-text-field
                  v-model="editEndTime"
                  type="time"
                  label="End time"
                  density="compact"
                  variant="outlined"
                  hide-details
                  :disabled="mutating"
                />
              </div>
              <p v-if="editError" class="text-caption text-error mt-1 mb-0">
                {{ editError }}
              </p>
              <div class="d-flex justify-end ga-2 mt-2">
                <v-btn size="small" :disabled="mutating" @click="onEditCancel">
                  Cancel
                </v-btn>
                <v-btn
                  size="small"
                  color="primary"
                  :loading="mutating"
                  @click="onEditSave"
                >
                  Save
                </v-btn>
              </div>
            </div>
            <template v-else>
              <div class="cc-timer-session__info">
                <span class="text-body-2">
                  {{ entryRangeLabel(sessionEntry) }}
                </span>
                <span class="text-caption text-medium-emphasis">
                  {{ entryDurationLabel(sessionEntry) }}
                </span>
                <span
                  v-if="sessionEntry.ended_at === null"
                  class="text-caption cc-timer-session__running"
                >
                  Running
                </span>
              </div>
              <div
                v-if="sessionEntry.ended_at !== null"
                class="cc-timer-session__actions"
              >
                <button
                  type="button"
                  class="cc-icon-btn cc-icon-btn--sm"
                  aria-label="Edit session"
                  title="Edit session"
                  :disabled="mutating"
                  @click="startEditingEntry(sessionEntry)"
                >
                  <v-icon icon="mdi-pencil-outline" size="18" />
                </button>
                <button
                  type="button"
                  class="cc-icon-btn cc-icon-btn--sm"
                  aria-label="Delete session"
                  title="Delete session"
                  :disabled="mutating"
                  @click="confirmingDeleteEntry = sessionEntry"
                >
                  <v-icon icon="mdi-delete-outline" size="18" />
                </button>
              </div>
            </template>
          </div>
        </div>
      </div>

      <v-dialog
        :model-value="confirmingDeleteEntry !== null"
        max-width="420"
        persistent
      >
        <v-card>
          <v-card-title>Delete session?</v-card-title>
          <v-card-text>
            Delete this session? Its {{ deleteDurationLabel }} of tracked time
            will be removed. This can't be undone.
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn
              size="large"
              :disabled="mutating"
              @click="confirmingDeleteEntry = null"
            >
              Cancel
            </v-btn>
            <v-btn
              color="error"
              size="large"
              :loading="mutating"
              @click="performDeleteEntry"
            >
              Delete
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </template>

    <p
      v-if="runningElsewhere"
      class="text-caption text-medium-emphasis mt-1 mb-0"
    >
      You have a timer running on another task — starting here will stop it.
    </p>
  </div>
</template>

<style scoped>
.cc-timer-readout {
  display: flex;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 12px 32px;
}

/* One labelled counter column ("This session" / "Total"): small eyebrow
   label stacked over the slab-serif time, with the estimate/empty note (if
   any) below. */
.cc-timer-stat {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cc-timer-time {
  font-family: var(--cc-font-slab);
  font-size: 1.75rem;
  font-weight: 700;
  line-height: 1;
  color: var(--cc-ink);
  font-variant-numeric: tabular-nums;
}

.cc-timer-time--running {
  color: var(--cc-accent);
}

.cc-timer-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.cc-timer-btn {
  flex: 1 1 140px;
}

/* Sessions disclosure: a quiet toggle over a simple divided list. */
.cc-timer-sessions-toggle {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: 0.875rem;
}

.cc-timer-session {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 0;
}

.cc-timer-session + .cc-timer-session {
  border-top: 1px solid var(--cc-border);
}

.cc-timer-session__info {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  column-gap: 8px;
}

.cc-timer-session__actions {
  display: flex;
  gap: 6px;
  flex: none;
}

.cc-timer-session__running {
  color: var(--cc-accent);
  font-weight: 600;
}

.cc-timer-session-edit {
  flex: 1;
  padding: 4px 0;
}

.cc-timer-session-edit__fields {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
</style>
