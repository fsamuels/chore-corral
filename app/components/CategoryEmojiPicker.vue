<script setup lang="ts">
// Compact emoji picker for a category: a "None" chip plus a curated grid of
// farm-flavored suggestions, and a freeform field for anything not in the
// grid. v-model is the emoji string (null when unset). Deliberately small —
// categories only ever carry one optional decorative emoji.
const model = defineModel<string | null>({ default: null })

defineProps<{ disabled?: boolean }>()

// Curated, farm-leaning suggestions. Not exhaustive — the freeform field
// below covers anything else.
const SUGGESTIONS = [
  '🐄',
  '🐖',
  '🐔',
  '🐐',
  '🐑',
  '🐎',
  '🐕',
  '🐈',
  '🥚',
  '🌾',
  '🌱',
  '🥕',
  '🍎',
  '🚜',
  '🧹',
  '🔧',
  '🔨',
  '🪵',
  '🚰',
  '🏠',
]

const custom = ref('')

// A grid tap sets the model directly; the freeform field mirrors whatever is
// set but only when it isn't one of the suggestions (so the input isn't
// cluttered by a value already visible as a highlighted chip).
watch(
  model,
  (value) => {
    custom.value = value && !SUGGESTIONS.includes(value) ? value : ''
  },
  { immediate: true },
)

function pick(emoji: string) {
  model.value = model.value === emoji ? null : emoji
}

function onCustomInput(value: string) {
  const trimmed = value.trim()
  model.value = trimmed ? trimmed : null
}
</script>

<template>
  <div class="emoji-picker">
    <div class="emoji-picker__grid">
      <button
        type="button"
        class="emoji-picker__option emoji-picker__option--none"
        :class="{ 'emoji-picker__option--active': model === null }"
        :disabled="disabled"
        aria-label="No emoji"
        title="No emoji"
        @click="model = null"
      >
        <v-icon icon="mdi-cancel" size="18" />
      </button>
      <button
        v-for="emoji in SUGGESTIONS"
        :key="emoji"
        type="button"
        class="emoji-picker__option"
        :class="{ 'emoji-picker__option--active': model === emoji }"
        :disabled="disabled"
        :aria-label="`Use ${emoji}`"
        :aria-pressed="model === emoji"
        @click="pick(emoji)"
      >
        {{ emoji }}
      </button>
    </div>
    <v-text-field
      :model-value="custom"
      label="Or type your own emoji"
      :disabled="disabled"
      density="comfortable"
      variant="outlined"
      hide-details
      class="mt-3"
      style="max-width: 240px"
      @update:model-value="onCustomInput"
    />
  </div>
</template>

<style scoped>
.emoji-picker__grid {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.emoji-picker__option {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 1.25rem;
  line-height: 1;
  background: var(--cc-surface);
  border: 1px solid var(--cc-border);
  box-shadow: var(--cc-shadow);
  cursor: pointer;
  padding: 0;
}

.emoji-picker__option--none {
  color: var(--cc-ink-muted);
}

.emoji-picker__option--active {
  border-color: var(--cc-accent);
  box-shadow: 0 0 0 2px var(--cc-accent);
}

.emoji-picker__option:disabled {
  opacity: 0.6;
  cursor: default;
}
</style>
