<script setup lang="ts">
// "Start chore" quick add: for a chore you're about to work on right now.
// Collects only a title, category and note; the rest is fixed (priority
// Whenever, due today — see `quickStartTaskInput`). Saving creates the chore
// in the active farm, starts the signed-in user's timer on it (which flips it
// to In progress and stops any other running timer, service-side), then
// goes to Home, where the chore leads "Jump back in". Rendered once from the
// default layout and opened by the "Start chore" button in `NewTaskFab`.
import type { Database } from '~/types/database.types'
import { createTask } from '~/services/tasks'
import { startTimer } from '~/services/time-entries'
import {
  initialQuickStartCategory,
  loadQuickStartCategory,
  quickStartTaskInput,
  saveQuickStartCategory,
} from '~/utils/quick-start'

const open = defineModel<boolean>({ required: true })

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { activeFarmId } = useFarms()
const { categories, fetchCategories } = useCategories()
const { refresh: refreshRunningTimer } = useRunningTimer()
const { showToast } = useToast()

const title = ref('')
const categoryId = ref<string | null>(null)
const notes = ref('')
const saving = ref(false)
const saveError = ref<string | null>(null)

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
      <v-card-title>Start a chore</v-card-title>
      <v-form @submit.prevent="submit">
        <v-card-text>
          <p class="quick-start__hint">
            Due today, priority Whenever. The timer starts when you save.
          </p>
          <v-text-field
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
            <template v-else>Start</template>
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
