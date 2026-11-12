<script setup lang="ts">
import type { CompleterMemberItem } from '~/components/CompleterPicker.vue'
import type { TaskCompleter } from '~/services/completers'
import {
  completersFromDrafts,
  prefillCompleterDrafts,
} from '~/utils/completers'

// The "Mark chore as done?" dialog: an optional note plus who completed the
// chore. Shared by the chore page (its status menu and "Complete chore"
// button) and the running-timer dock's Finish button, so both behave alike.
// Presentational: the caller loads the farm's members and the chore's
// existing completers, and performs the status change on `confirm` — it
// reports progress back through `busy` / `error`, and closes the dialog
// itself on success (via v-model). The dialog stays open on error so the
// note and picks aren't lost.
//
// Drafts reset each time it opens, prefilled with the existing completers
// or, when nobody's credited yet, the signed-in member — the same default
// `changeTaskStatus` would auto-credit (see `prefillCompleterDrafts`).
const props = defineProps<{
  memberItems: CompleterMemberItem[]
  /** The chore's current completer set (usually empty before it's done). */
  existingCompleters: readonly TaskCompleter[]
  /** Signed-in member's id, the prefill when nobody's credited yet. */
  actorUserId?: string
  busy?: boolean
  error?: string | null
}>()

const open = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  confirm: [payload: { note: string; completers: TaskCompleter[] }]
}>()

const note = ref('')
const membersDraft = ref<string[]>([])
const namesDraft = ref<string[]>([])

watch(
  open,
  (isOpen) => {
    if (!isOpen) return
    note.value = ''
    const drafts = prefillCompleterDrafts(
      props.existingCompleters,
      props.actorUserId,
    )
    membersDraft.value = drafts.members
    namesDraft.value = drafts.names
  },
  { immediate: true },
)

function onConfirm() {
  emit('confirm', {
    note: note.value,
    completers: completersFromDrafts(membersDraft.value, namesDraft.value),
  })
}
</script>

<template>
  <!-- Persistent: a stray tap outside mustn't discard a half-written note. -->
  <v-dialog v-model="open" max-width="480" location="top" persistent>
    <v-card class="cc-dialog-card complete-dialog-card">
      <v-card-title>Mark chore as done?</v-card-title>
      <v-card-text>
        Add an optional note about how it went (or leave it blank).
        <v-textarea
          v-model="note"
          label="Note (optional)"
          variant="outlined"
          rows="3"
          auto-grow
          autofocus
          counter
          class="mt-3"
          :disabled="busy"
        />
        <div class="cc-eyebrow mb-2">Completed by</div>
        <CompleterPicker
          v-model:members="membersDraft"
          v-model:names="namesDraft"
          :member-items="memberItems"
          :disabled="busy"
          class="mb-3"
        />
        <v-alert v-if="error" type="error" variant="tonal" density="compact">
          {{ error }}
        </v-alert>
      </v-card-text>
      <div class="cc-dialog-actions">
        <button
          type="button"
          class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--lg"
          :disabled="busy"
          @click="open = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="cc-pill-btn cc-pill-btn--lg cc-pill-btn--success"
          :disabled="busy"
          @click="onConfirm"
        >
          <v-progress-circular v-if="busy" indeterminate size="18" width="2" />
          <template v-else>Mark done</template>
        </button>
      </div>
    </v-card>
  </v-dialog>
</template>

<style scoped>
/* The dialog is pinned to the top so the keyboard doesn't cover it, which on
   a phone put it under the front camera / status bar. Push it down past the
   safe-area inset plus some breathing room. */
.complete-dialog-card {
  margin-top: calc(env(safe-area-inset-top, 0px) + 40px);
}
</style>
