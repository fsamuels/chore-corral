<script setup lang="ts">
import { parseLocalDateString } from '~/services/tasks'
import type { ReminderSummary } from '~/services/reminders'
import { SNOOZE_OPTIONS, type SnoozeMinutes } from '~/utils/reminder-snooze'

// Only rendered once a task exists (parent guards with v-if="task"), so a
// task id is always present.
const props = defineProps<{ taskId: string }>()

const {
  reminders,
  remindersError,
  loading,
  adding,
  mutationError,
  add,
  remove,
  snooze,
} = useTaskReminders(toRef(props, 'taskId'))

// "Jan 5, 8:00 AM" — same shape as the View page's completed-at label.
function formatReminder(iso: string): string {
  return new Date(iso).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

const newDate = ref('')
const newTime = ref('')
// Pre-service validation only (missing/malformed inputs); a past-time
// rejection comes back through `mutationError` from `assertValidReminderTime`.
const addError = ref<string | null>(null)
const displayError = computed(() => addError.value ?? mutationError.value)

async function onAdd(): Promise<void> {
  addError.value = null
  if (!newDate.value || !newTime.value) {
    addError.value = 'Enter a date and time.'
    return
  }
  const combined = combineDateAndTime(
    parseLocalDateString(newDate.value),
    newTime.value,
  )
  if (!combined) {
    addError.value = 'Enter a valid date and time.'
    return
  }
  if (await add(combined.toISOString())) {
    newDate.value = ''
    newTime.value = ''
  }
}

// Per-reminder in-flight tracking so only the affected row's buttons disable
// (matches TaskShoppingList/TaskTools) — shared between delete and snooze
// since only one action per row makes sense at a time.
const pendingIds = ref<Set<string>>(new Set())

// Removal is undoable: the row is hidden right away and the real delete only
// runs once the Undo toast times out. `remove` reports failure via
// `mutationError` rather than throwing, so surface that as a failed commit
// (which restores the row).
const hiddenIds = ref<Set<string>>(new Set())
const visibleReminders = computed(
  () => reminders.value?.filter((r) => !hiddenIds.value.has(r.id)) ?? null,
)

function setHidden(id: string, hidden: boolean): void {
  const next = new Set(hiddenIds.value)
  if (hidden) next.add(id)
  else next.delete(id)
  hiddenIds.value = next
}

const { removeWithUndo } = useUndoableRemove()

function onRemove(reminder: ReminderSummary): void {
  removeWithUndo({
    hide: () => setHidden(reminder.id, true),
    restore: () => setHidden(reminder.id, false),
    commit: async () => {
      await remove(reminder)
      if (mutationError.value) throw new Error(mutationError.value)
      setHidden(reminder.id, false)
    },
    message: 'Reminder removed',
  })
}

async function onSnooze(
  reminder: ReminderSummary,
  minutes: SnoozeMinutes,
): Promise<void> {
  const next = new Set(pendingIds.value)
  next.add(reminder.id)
  pendingIds.value = next
  try {
    await snooze(reminder.id, minutes)
  } finally {
    const done = new Set(pendingIds.value)
    done.delete(reminder.id)
    pendingIds.value = done
  }
}
</script>

<template>
  <div>
    <p class="cc-eyebrow mb-2">Reminders</p>

    <v-alert
      v-if="remindersError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ remindersError }}
    </v-alert>

    <div v-if="reminders === null && loading" class="py-2">
      <v-progress-circular indeterminate size="24" color="primary" />
    </div>

    <p
      v-else-if="visibleReminders && visibleReminders.length === 0"
      class="cc-empty-inline"
    >
      No reminders yet.
    </p>

    <div v-else-if="visibleReminders">
      <div
        v-for="reminder in visibleReminders"
        :key="reminder.id"
        class="d-flex align-center justify-space-between ga-2 py-1 flex-wrap"
      >
        <span
          class="text-body-2"
          :class="{ 'cc-muted': reminder.sent_at !== null }"
        >
          {{ formatReminder(reminder.remind_at) }}
          <span v-if="reminder.sent_at !== null" class="text-caption">
            (sent)
          </span>
        </span>
        <div class="d-flex align-center ga-1 reminder-actions">
          <!-- Already-sent reminders can be snoozed back to upcoming — the
               in-app twin of the notification's own Snooze action buttons
               (see public/sw.js), and the only surface iOS gets since iOS
               web push doesn't render notification actions at all. -->
          <template v-if="reminder.sent_at !== null">
            <button
              v-for="option in SNOOZE_OPTIONS"
              :key="option.minutes"
              type="button"
              class="cc-pill-btn cc-pill-btn--outline reminder-snooze-btn"
              :disabled="pendingIds.has(reminder.id)"
              @click="onSnooze(reminder, option.minutes)"
            >
              {{ option.label }}
            </button>
          </template>
          <button
            type="button"
            class="cc-icon-btn cc-icon-btn--sm"
            aria-label="Remove reminder"
            title="Remove reminder"
            :disabled="pendingIds.has(reminder.id)"
            @click="onRemove(reminder)"
          >
            <v-progress-circular
              v-if="pendingIds.has(reminder.id)"
              indeterminate
              size="16"
              width="2"
            />
            <v-icon v-else icon="mdi-close" size="18" />
          </button>
        </div>
      </div>
    </div>

    <div class="cc-add-row reminder-add-row mt-3">
      <v-text-field
        v-model="newDate"
        type="date"
        label="Date"
        density="comfortable"
        variant="outlined"
        hide-details
        :disabled="adding"
      />
      <v-text-field
        v-model="newTime"
        type="time"
        label="Time"
        density="comfortable"
        variant="outlined"
        hide-details
        :disabled="adding"
      />
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
        :disabled="adding || !newDate || !newTime"
        @click="onAdd"
      >
        <v-progress-circular v-if="adding" indeterminate size="16" width="2" />
        <template v-else>
          <v-icon icon="mdi-plus" size="16" />
          Add
        </template>
      </button>
    </div>

    <v-alert
      v-if="displayError"
      type="error"
      variant="tonal"
      density="compact"
      class="mt-2"
    >
      {{ displayError }}
    </v-alert>
  </div>
</template>

<style scoped>
/* cc-add-row, but wrapping so date + time + Add stack on narrow phones. */
.reminder-add-row {
  flex-wrap: wrap;
}

.reminder-add-row > .v-input {
  flex: 1 1 130px;
}

.reminder-actions {
  flex-wrap: wrap;
  justify-content: flex-end;
}

/* Compact padding/type, but the full 44px touch target. */
.reminder-snooze-btn {
  min-height: 44px;
  padding: 0 12px;
  font-size: 0.8125rem;
}
</style>
