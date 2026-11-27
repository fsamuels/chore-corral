<script setup lang="ts">
import { canonicalizeLabels, MAX_SESSION_LABELS } from '~/utils/session-labels'

// The session-labels dialog, rendered once from the default layout and
// driven by `useSessionLabelsPrompt`: the stop prompt ("Stop timer" with
// optional labels) and the add/edit-labels dialog for one session. The
// chore's earlier labels show as one-tap chips under the input, so a
// repeat label ("morning feeding") doesn't need the keyboard.
const prompt = useSessionLabelsPrompt()
const { open, mode, entry, suggestions, busy, error } = prompt

const labels = ref<string[]>([])
const search = ref('')

// Start from the session's current labels each time the dialog opens.
watch(open, (isOpen) => {
  if (!isOpen) return
  labels.value = [...(entry.value?.labels ?? [])]
  search.value = ''
})

// Typing a comma commits the label before it, as Enter does.
watch(search, (text) => {
  if (!text?.includes(',')) return
  const parts = text.split(',')
  const rest = parts.pop() ?? ''
  commit(parts)
  search.value = rest
})

function commit(added: string[]): void {
  labels.value = canonicalizeLabels(
    [...labels.value, ...added],
    suggestions.value,
  )
}

// The combobox emits whatever was typed; keep the list clean and reuse a
// known label's spelling as soon as one is added.
function onLabelsUpdate(next: string[]): void {
  labels.value = canonicalizeLabels(next, suggestions.value)
}

const unusedSuggestions = computed(() => {
  const chosen = new Set(labels.value.map((l) => l.toLocaleLowerCase()))
  return suggestions.value
    .filter((s) => !chosen.has(s.toLocaleLowerCase()))
    .slice(0, 12)
})

const full = computed(() => labels.value.length >= MAX_SESSION_LABELS)

const title = computed(() =>
  mode.value === 'stop' ? 'Stop timer' : 'Session labels',
)
const confirmLabel = computed(() =>
  mode.value === 'stop' ? 'Stop timer' : 'Save',
)

function onConfirm(): void {
  // Text typed but not yet committed with Enter still counts.
  const pending = search.value?.trim()
  if (pending) commit([pending])
  search.value = ''
  prompt.confirm(labels.value)
}

const dialogOpen = computed({
  get: () => open.value,
  set: (value) => {
    if (!value) prompt.cancel()
  },
})
</script>

<template>
  <v-dialog v-model="dialogOpen" max-width="440">
    <v-card class="cc-dialog-card">
      <v-card-title>{{ title }}</v-card-title>
      <v-card-text>
        <p class="text-body-2 cc-muted mb-3">
          What did this session cover? Optional, e.g. morning feeding, mucking,
          Aaron helped.
        </p>
        <v-combobox
          v-model:search="search"
          :model-value="labels"
          :items="suggestions"
          label="Labels"
          multiple
          chips
          closable-chips
          hide-no-data
          density="comfortable"
          variant="outlined"
          :hint="
            full ? `Up to ${MAX_SESSION_LABELS} labels` : 'Press Enter to add'
          "
          persistent-hint
          :disabled="busy"
          @update:model-value="onLabelsUpdate"
        />
        <div
          v-if="unusedSuggestions.length > 0 && !full"
          class="session-labels-suggestions"
          aria-label="Earlier labels on this chore"
          role="group"
        >
          <button
            v-for="suggestion in unusedSuggestions"
            :key="suggestion"
            type="button"
            class="session-labels-suggestion"
            :disabled="busy"
            @click="commit([suggestion])"
          >
            <v-icon icon="mdi-plus" size="14" />
            {{ suggestion }}
          </button>
        </div>
        <v-alert
          v-if="error"
          type="error"
          variant="tonal"
          density="compact"
          class="mt-3"
        >
          {{ error }}
        </v-alert>
      </v-card-text>
      <div class="cc-dialog-actions">
        <button
          type="button"
          class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--lg"
          :disabled="busy"
          @click="prompt.cancel()"
        >
          Cancel
        </button>
        <button
          type="button"
          class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg"
          :disabled="busy"
          @click="onConfirm"
        >
          <v-progress-circular v-if="busy" indeterminate size="18" width="2" />
          <template v-else>
            <v-icon v-if="mode === 'stop'" icon="mdi-stop" size="20" />
            {{ confirmLabel }}
          </template>
        </button>
      </div>
    </v-card>
  </v-dialog>
</template>

<style scoped>
.session-labels-suggestions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}

/* One-tap earlier labels: dashed outline pills, so they read as "add this"
   rather than as labels already on the session. */
.session-labels-suggestion {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  min-height: 36px;
  padding: 4px 12px;
  border: 1px dashed color-mix(in srgb, var(--cc-ink) 35%, transparent);
  border-radius: 999px;
  background: transparent;
  color: var(--cc-ink);
  font-size: 0.875rem;
  cursor: pointer;
}

.session-labels-suggestion:hover:not(:disabled) {
  border-style: solid;
  background: color-mix(in srgb, var(--cc-accent) 8%, transparent);
}

.session-labels-suggestion:disabled {
  opacity: 0.5;
  cursor: default;
}
</style>
