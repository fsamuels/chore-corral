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

async function onRemove(reminder: ReminderSummary): Promise<void> {
  const next = new Set(pendingIds.value)
  next.add(reminder.id)
  pendingIds.value = next
  try {
    await remove(reminder)
  } finally {
    const done = new Set(pendingIds.value)
    done.delete(reminder.id)
    pendingIds.value = done
  }
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
      v-else-if="reminders && reminders.length === 0"
      class="text-body-2 text-medium-emphasis"
    >
      No reminders set.
    </p>

    <div v-else-if="reminders">
      <div
        v-for="reminder in reminders"
        :key="reminder.id"
        class="d-flex align-center justify-space-between ga-2 py-1 flex-wrap"
      >
        <span
          class="text-body-2"
          :class="{ 'text-medium-emphasis': reminder.sent_at !== null }"
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
            <v-icon v-else icon="mdi-delete-outline" size="18" />
          </button>
        </div>
      </div>
    </div>

    <div class="reminder-add-row mt-3">
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

    <p v-if="displayError" class="text-caption text-error mt-1 mb-0">
      {{ displayError }}
    </p>
  </div>
</template>

<style scoped>
.reminder-add-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.reminder-add-row > .v-input {
  flex: 1 1 130px;
}

.reminder-actions {
  flex-wrap: wrap;
  justify-content: flex-end;
}

/* Shrunk below cc-pill-btn's standard 44px touch target — these sit two-up
   next to the delete button on an already-sent reminder's row, and at full
   size they'd blow up the row on mobile. */
.reminder-snooze-btn {
  height: 32px;
  padding: 0 12px;
  font-size: 0.8125rem;
}
</style>
