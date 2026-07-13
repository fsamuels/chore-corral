<script setup lang="ts">
// Full, searchable emoji browser opened from CategoryEmojiPicker's "More…"
// affordance. Sized for a phone held around the farm: a compact dialog with a
// fixed search + group bar and a scrollable emoji grid. Only one group
// (or the search results) is mounted at a time — ~1,900 buttons all at once is
// needless work, and a single group is small enough that no virtualization is
// warranted.
import type { CatalogEmoji } from '~/utils/emoji-catalog'
import {
  loadRecentEmoji,
  recordRecentEmoji,
  searchCatalog,
} from '~/utils/emoji-catalog'

const open = defineModel<boolean>({ default: false })
const props = defineProps<{ selected?: string | null }>()
const emit = defineEmits<{ select: [emoji: string] }>()

const { catalog, groups, loading, error, ensureLoaded } = useEmojiCatalog()

const search = ref('')
const activeGroup = ref<number | null>(null)
const recents = ref<string[]>([])

// First open triggers the lazy chunk download and reads recents (both are
// client-only). Reset search each open so it starts clean.
watch(open, (isOpen) => {
  if (!isOpen) return
  search.value = ''
  recents.value = loadRecentEmoji()
  ensureLoaded()
})

// Default the active group once the catalog resolves — the dialog can open
// before the chunk finishes downloading.
watch(
  groups,
  (list) => {
    if (activeGroup.value === null && list[0]) {
      activeGroup.value = list[0].group
    }
  },
  { immediate: true },
)

const searching = computed(() => search.value.trim().length > 0)
const results = computed(() => searchCatalog(catalog.value, search.value))
const currentGroup = computed(
  () => groups.value.find((group) => group.group === activeGroup.value) ?? null,
)

// Recents are stored as bare emoji strings; resolve labels from the catalog
// for accessible names (fall back to the emoji itself if it's since dropped
// out of the catalog — e.g. after a version-cap change).
const labelByEmoji = computed(() => {
  const map = new Map<string, string>()
  for (const entry of catalog.value) map.set(entry.emoji, entry.label)
  return map
})

const recentEntries = computed<CatalogEmoji[]>(() =>
  recents.value.map((emoji) => ({
    emoji,
    label: labelByEmoji.value.get(emoji) ?? emoji,
    tags: [],
    group: -1,
    order: 0,
  })),
)

function choose(emoji: string) {
  // Record before emitting so the recents list reflects the pick if reopened.
  recents.value = recordRecentEmoji(emoji)
  emit('select', emoji)
  open.value = false
}
</script>

<template>
  <v-dialog v-model="open" max-width="520" scrollable>
    <v-card class="emoji-dialog">
      <div class="emoji-dialog__head">
        <div class="d-flex align-center justify-space-between mb-3">
          <span class="cc-eyebrow">Choose an emoji</span>
          <button
            type="button"
            class="cc-icon-btn cc-icon-btn--sm"
            aria-label="Close"
            title="Close"
            @click="open = false"
          >
            <v-icon icon="mdi-close" size="18" />
          </button>
        </div>
        <v-text-field
          v-model="search"
          autofocus
          placeholder="Search emoji"
          prepend-inner-icon="mdi-magnify"
          density="comfortable"
          variant="outlined"
          hide-details
          clearable
        />
        <v-chip-group
          v-if="!searching && groups.length"
          v-model="activeGroup"
          mandatory
          class="emoji-dialog__groups"
          selected-class="emoji-dialog__group--active"
        >
          <v-chip
            v-for="group in groups"
            :key="group.group"
            :value="group.group"
            size="small"
            variant="outlined"
          >
            {{ group.name }}
          </v-chip>
        </v-chip-group>
      </div>

      <v-card-text class="emoji-dialog__body">
        <div v-if="loading" class="emoji-dialog__state">
          <v-progress-circular indeterminate color="primary" />
        </div>

        <div v-else-if="error" class="emoji-dialog__state text-medium-emphasis">
          <v-icon icon="mdi-wifi-off" size="40" class="mb-2" />
          <p class="text-body-2">
            Couldn't load the emoji list. Check your connection and try
            reopening.
          </p>
        </div>

        <template v-else>
          <div v-if="searching">
            <p v-if="!results.length" class="text-medium-emphasis text-body-2">
              No emoji match “{{ search.trim() }}”.
            </p>
            <div v-else class="emoji-dialog__grid">
              <button
                v-for="entry in results"
                :key="entry.emoji"
                type="button"
                class="emoji-dialog__option"
                :class="{
                  'emoji-dialog__option--active':
                    entry.emoji === props.selected,
                }"
                :aria-label="entry.label"
                :aria-pressed="entry.emoji === props.selected"
                :title="entry.label"
                @click="choose(entry.emoji)"
              >
                {{ entry.emoji }}
              </button>
            </div>
          </div>

          <template v-else>
            <section v-if="recentEntries.length" class="emoji-dialog__section">
              <p class="cc-eyebrow mb-2">Recently used</p>
              <div class="emoji-dialog__grid">
                <button
                  v-for="entry in recentEntries"
                  :key="`recent-${entry.emoji}`"
                  type="button"
                  class="emoji-dialog__option"
                  :class="{
                    'emoji-dialog__option--active':
                      entry.emoji === props.selected,
                  }"
                  :aria-label="entry.label"
                  :aria-pressed="entry.emoji === props.selected"
                  :title="entry.label"
                  @click="choose(entry.emoji)"
                >
                  {{ entry.emoji }}
                </button>
              </div>
            </section>

            <section v-if="currentGroup" class="emoji-dialog__section">
              <p class="cc-eyebrow mb-2">{{ currentGroup.name }}</p>
              <div class="emoji-dialog__grid">
                <button
                  v-for="entry in currentGroup.emoji"
                  :key="entry.emoji"
                  type="button"
                  class="emoji-dialog__option"
                  :class="{
                    'emoji-dialog__option--active':
                      entry.emoji === props.selected,
                  }"
                  :aria-label="entry.label"
                  :aria-pressed="entry.emoji === props.selected"
                  :title="entry.label"
                  @click="choose(entry.emoji)"
                >
                  {{ entry.emoji }}
                </button>
              </div>
            </section>
          </template>
        </template>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<style scoped>
.emoji-dialog {
  display: flex;
  flex-direction: column;
  max-height: 80vh;
}

/* Search + group bar stays put while the grid below scrolls. */
.emoji-dialog__head {
  padding: 16px 16px 8px;
  border-bottom: 1px solid var(--cc-border);
}

.emoji-dialog__groups {
  margin-top: 4px;
}

.emoji-dialog__group--active {
  border-color: var(--cc-accent);
  color: var(--cc-accent);
}

.emoji-dialog__body {
  padding: 12px 16px 20px;
  overflow-y: auto;
}

.emoji-dialog__state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 40px 16px;
}

.emoji-dialog__section + .emoji-dialog__section {
  margin-top: 16px;
}

.emoji-dialog__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(44px, 1fr));
  gap: 6px;
}

.emoji-dialog__option {
  aspect-ratio: 1;
  min-width: 44px;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 1.4rem;
  line-height: 1;
  background: var(--cc-surface);
  border: 1px solid var(--cc-border);
  cursor: pointer;
  padding: 0;
}

.emoji-dialog__option:hover {
  border-color: var(--cc-accent);
}

.emoji-dialog__option--active {
  border-color: var(--cc-accent);
  box-shadow: 0 0 0 2px var(--cc-accent);
}
</style>
