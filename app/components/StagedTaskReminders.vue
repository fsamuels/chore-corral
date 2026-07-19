<script setup lang="ts">
// Reminders staged during task *creation*, before a task id exists — same
// reasoning as StagedTaskPhotos: `task_reminders` rows need a real task_id,
// so this just holds plain in-memory `{ localId, remindAtIso }` entries and
// the create page schedules them via `addReminder` after the task insert
// succeeds.
import { parseLocalDateString } from '~/services/tasks'
import { assertValidReminderTime } from '~/services/reminders'

export interface StagedReminder {
  localId: string
  remindAtIso: string
}

const staged = defineModel<StagedReminder[]>('staged', { default: () => [] })

// "Jan 5, 8:00 AM" — same shape as the View page's reminder list.
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
const addError = ref<string | null>(null)

function onAdd(): void {
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
  const remindAtIso = combined.toISOString()
  try {
    // Same guard `addReminder` applies server-side — checked here too so a
    // staged reminder never silently fails once the chore is actually
    // created (by which point this form is gone).
    assertValidReminderTime(remindAtIso)
  } catch (error) {
    addError.value =
      error instanceof Error ? error.message : 'Invalid reminder time'
    return
  }
  staged.value = [
    ...staged.value,
    { localId: crypto.randomUUID(), remindAtIso },
  ]
  newDate.value = ''
  newTime.value = ''
}

function onRemove(reminder: StagedReminder): void {
  staged.value = staged.value.filter((r) => r.localId !== reminder.localId)
}
</script>

<template>
  <div>
    <p class="cc-eyebrow mb-2">Reminders</p>

    <p v-if="staged.length === 0" class="text-body-2 text-medium-emphasis">
      No reminders yet — added reminders will be scheduled once the chore is
      created.
    </p>

    <div v-else class="mb-2">
      <div
        v-for="reminder in staged"
        :key="reminder.localId"
        class="d-flex align-center justify-space-between ga-2 py-1"
      >
        <span class="text-body-2">{{
          formatReminder(reminder.remindAtIso)
        }}</span>
        <button
          type="button"
          class="cc-icon-btn cc-icon-btn--sm"
          aria-label="Remove reminder"
          title="Remove reminder"
          @click="onRemove(reminder)"
        >
          <v-icon icon="mdi-close" size="16" />
        </button>
      </div>
    </div>

    <div class="reminder-add-row mt-2">
      <v-text-field
        v-model="newDate"
        type="date"
        label="Date"
        density="comfortable"
        variant="outlined"
        hide-details
      />
      <v-text-field
        v-model="newTime"
        type="time"
        label="Time"
        density="comfortable"
        variant="outlined"
        hide-details
      />
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
        :disabled="!newDate || !newTime"
        @click="onAdd"
      >
        <v-icon icon="mdi-plus" size="16" />
        Add
      </button>
    </div>

    <p v-if="addError" class="text-caption text-error mt-1 mb-0">
      {{ addError }}
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
</style>
