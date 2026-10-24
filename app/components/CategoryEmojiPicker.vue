<script setup lang="ts">
// Compact emoji picker for a category: a "None" chip plus a curated grid of
// farm-flavored suggestions, and a freeform field for anything not in the
// grid. v-model is the emoji string (null when unset). Deliberately small —
// categories only ever carry one optional decorative emoji.
import { recordRecentEmoji } from '~/utils/emoji-catalog'

const model = defineModel<string | null>({ default: null })

defineProps<{ disabled?: boolean }>()

// The full searchable catalog lives behind this dialog (a lazy chunk), opened
// from the "More…" tile so the common case stays a one-tap curated grid.
const showFullPicker = ref(false)

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
  if (model.value === emoji) {
    model.value = null
    return
  }
  model.value = emoji
  // Quick-row picks feed the same recents the full picker surfaces.
  recordRecentEmoji(emoji)
}

// The dialog records its own pick in recents before emitting; here we only
// mirror the chosen emoji into the model.
function onFullPick(emoji: string) {
  model.value = emoji
}

function onCustomInput(value: string) {
  const trimmed = value.trim()
  model.value = trimmed ? trimmed : null
}
</script>

<template>
  <div class="emoji-picker">
    <div class="emoji-picker__grid" role="group" aria-label="Suggested emoji">
      <button
        type="button"
        class="cc-icon-btn emoji-picker__option emoji-picker__option--muted"
        :class="{ 'cc-icon-btn--active': model === null }"
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
        class="cc-icon-btn emoji-picker__option"
        :class="{ 'cc-icon-btn--active': model === emoji }"
        :disabled="disabled"
        :aria-label="`Use ${emoji}`"
        :aria-pressed="model === emoji"
        @click="pick(emoji)"
      >
        {{ emoji }}
      </button>
      <button
        type="button"
        class="cc-icon-btn emoji-picker__option emoji-picker__option--muted"
        :disabled="disabled"
        aria-label="Browse all emoji"
        title="Browse all emoji"
        @click="showFullPicker = true"
      >
        <v-icon icon="mdi-dots-horizontal" size="18" />
      </button>
    </div>
    <EmojiPickerDialog
      v-model="showFullPicker"
      :selected="model"
      @select="onFullPick"
    />
    <v-text-field
      :model-value="custom"
      label="Or type your own emoji"
      :disabled="disabled"
      density="comfortable"
      variant="outlined"
      hide-details
      class="emoji-picker__custom mt-3"
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

/* cc-icon-btn supplies the round button; this just sizes the emoji glyph. */
.emoji-picker__option {
  font-size: 1.25rem;
  line-height: 1;
}

.emoji-picker__option--muted {
  color: var(--cc-ink-muted);
}

.emoji-picker__custom {
  max-width: 240px;
}
</style>
