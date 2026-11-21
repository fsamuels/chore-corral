<script setup lang="ts">
// "Start chore" quick add, with a Now / Tomorrow toggle (always opens on
// Now). Collects only a title, category and note; the rest is fixed
// (priority Whenever, due today or tomorrow — see `quickStartTaskInput`).
// Now: saving creates the chore in the active farm, starts the signed-in
// user's timer on it (which flips it to In progress and stops any other
// running timer, service-side), then goes to Home, where the chore leads
// "Jump back in". Tomorrow: saving creates the chore due tomorrow, starts no
// timer, and stays on the current page with a toast. Rendered once from the
// default layout and opened by the "Start chore" button in `NewTaskFab`.
import type { Database } from '~/types/database.types'
import { createTask } from '~/services/tasks'
import { startTimer } from '~/services/time-entries'
import {
  initialQuickStartCategory,
  loadQuickStartCategory,
  quickStartTaskInput,
  saveQuickStartCategory,
  type QuickStartWhen,
} from '~/utils/quick-start'

const open = defineModel<boolean>({ required: true })

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { activeFarmId } = useFarms()
const { categories, fetchCategories } = useCategories()
const { refresh: refreshRunningTimer } = useRunningTimer()
const { showToast } = useToast()
const { notifyTasksChanged } = useTasksChanged()

const when = ref<QuickStartWhen>('now')
const title = ref('')
const titleField = ref<{ focus: () => void } | null>(null)
const categoryId = ref<string | null>(null)
const notes = ref('')
const saving = ref(false)
const saveError = ref<string | null>(null)

const whenOptions: { value: QuickStartWhen; label: string; icon: string }[] = [
  { value: 'now', label: 'Now', icon: 'mdi-lightning-bolt' },
  { value: 'tomorrow', label: 'Tomorrow', icon: 'mdi-calendar-arrow-right' },
]

// Keep typing flowing: tapping a toggle option would otherwise take focus
// off the title field.
function setWhen(value: QuickStartWhen) {
  when.value = value
  titleField.value?.focus()
}

const hint = computed(() =>
  when.value === 'now'
    ? 'Due today, priority Whenever. The timer starts when you save.'
    : 'Due tomorrow, priority Whenever. No timer.',
)

const categoryItems = computed(() => [
  { title: '❓ Uncategorized', value: null },
  ...(categories.value ?? []).map((category) => ({
    title: `${category.emoji ?? '🏷️'} ${category.name}`,
    value: category.id,
  })),
])

// Reset on every open, and load the farm's categories fresh (they may have
// changed since the last open) before preselecting the remembered one.
watch(open, async (isOpen) => {
  if (!isOpen) return
  when.value = 'now'
  title.value = ''
  notes.value = ''
  saveError.value = null
  categoryId.value = null
  await fetchCategories()
  const farmId = activeFarmId.value
  if (!farmId || !open.value) return
  categoryId.value = initialQuickStartCategory(
    loadQuickStartCategory(farmId),
    (categories.value ?? []).map((c) => c.id),
  )
})

async function submit() {
  const farmId = activeFarmId.value
  const actorUserId = getActorUserId(user.value)
  if (!title.value.trim() || saving.value) return
  if (!farmId || !actorUserId) {
    saveError.value = 'No farm selected'
    return
  }
  saving.value = true
  saveError.value = null

  let created: { id: string; title: string }
  try {
    created = await createTask(supabase, {
      ...quickStartTaskInput({
        title: title.value,
        categoryId: categoryId.value,
        notes: notes.value,
        when: when.value,
      }),
      farmId,
      actorUserId,
    })
  } catch (error) {
    saveError.value =
      error instanceof Error ? error.message : 'Failed to create chore'
    saving.value = false
    return
  }

  saveQuickStartCategory(farmId, categoryId.value)

  if (when.value === 'tomorrow') {
    // No timer and no navigation, so a list page that's open (Home, /tasks)
    // won't otherwise see the new chore.
    notifyTasksChanged({ done: false })
    showToast(`Added “${created.title}” for tomorrow`)
    saving.value = false
    open.value = false
    return
  }

  // The chore exists from here on, so a timer failure doesn't keep the
  // dialog open (saving again would duplicate the chore) — it goes Home
  // either way and says what happened.
  try {
    await startTimer(supabase, { farmId, taskId: created.id, actorUserId })
    showToast(`Timer started for “${created.title}”`)
  } catch {
    showToast(`Created “${created.title}”, but the timer didn't start`, {
      tone: 'error',
      timeout: 6000,
    })
  }
  await refreshRunningTimer()

  saving.value = false
  open.value = false
  await navigateTo('/')
}
</script>

<template>
  <v-dialog v-model="open" max-width="440" :persistent="saving">
    <v-card class="cc-dialog-card">
      <v-card-title>{{
        when === 'now' ? 'Start a chore' : 'Add a chore for tomorrow'
      }}</v-card-title>
      <v-form @submit.prevent="submit">
        <v-card-text>
          <div class="cc-segmented mb-3" role="group" aria-label="When">
            <button
              v-for="option in whenOptions"
              :key="option.value"
              type="button"
              class="cc-segmented__option"
              :class="{ 'cc-segmented__option--active': when === option.value }"
              :aria-pressed="when === option.value"
              :disabled="saving"
              @click="setWhen(option.value)"
            >
              <v-icon :icon="option.icon" size="18" />
              {{ option.label }}
            </button>
          </div>
          <p class="quick-start__hint">{{ hint }}</p>
          <v-text-field
            ref="titleField"
            v-model="title"
            label="Title"
            :disabled="saving"
            density="comfortable"
            variant="outlined"
            hide-details
            class="mb-4"
            autofocus
          />
          <v-select
            v-model="categoryId"
            :items="categoryItems"
            label="Category"
            :disabled="saving"
            density="comfortable"
            variant="outlined"
            hide-details
            class="mb-4"
          />
          <v-textarea
            v-model="notes"
            label="Notes"
            rows="2"
            auto-grow
            :disabled="saving"
            density="comfortable"
            variant="outlined"
            hide-details
          />
          <v-alert
            v-if="saveError"
            type="error"
            variant="tonal"
            density="compact"
            class="mt-3"
          >
            {{ saveError }}
          </v-alert>
        </v-card-text>
        <div class="cc-dialog-actions">
          <button
            type="button"
            class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--lg"
            :disabled="saving"
            @click="open = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg"
            :disabled="saving || !title.trim()"
          >
            <v-progress-circular
              v-if="saving"
              indeterminate
              size="18"
              width="2"
            />
            <template v-else>{{ when === 'now' ? 'Start' : 'Add' }}</template>
          </button>
        </div>
      </v-form>
    </v-card>
  </v-dialog>
</template>

<style scoped>
.quick-start__hint {
  margin: 0 0 16px;
  font-size: 0.875rem;
  color: var(--cc-ink-muted);
}
</style>
