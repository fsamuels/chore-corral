<script setup lang="ts">
import type { CompleterMemberItem } from '~/components/CompleterPicker.vue'
import type { TaskCompleter } from '~/services/completers'
import { shouldOfferLastTimerStop } from '~/services/time-entries'
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
  /**
   * End of the chore's most recent stopped timer, when the caller has one and
   * no timer is still running on it. Offered as the completion time, for a
   * chore closed out well after the work stopped. Omit (or null) to hide.
   */
  lastStopAt?: string | null
  busy?: boolean
  error?: string | null
}>()

const open = defineModel<boolean>({ required: true })

const emit = defineEmits<{
  confirm: [
    payload: {
      note: string
      completers: TaskCompleter[]
      completedAt: string | null
    },
  ]
}>()

const note = ref('')
const membersDraft = ref<string[]>([])
const namesDraft = ref<string[]>([])
// Whether to offer (and apply) the last timer stop as the completion time.
// Offered only when it falls in a different minute than now — otherwise it
// would change nothing. Decided when the dialog opens so it doesn't flicker.
// The stop is snapshotted on open so the label and the saved time can't
// drift from what was offered if the prop changes while the dialog is open.
const offeredStop = ref<string | null>(null)
const useLastStop = ref(false)
const lastStopLabel = computed(() =>
  offeredStop.value ? formatShortDateTime(offeredStop.value) : '',
)

watch(
  open,
  (isOpen) => {
    if (!isOpen) return
    note.value = ''
    useLastStop.value = false
    const stop = props.lastStopAt ?? null
    offeredStop.value = shouldOfferLastTimerStop(stop, new Date().toISOString())
      ? stop
      : null
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
    completedAt: useLastStop.value ? offeredStop.value : null,
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
        <v-checkbox
          v-if="offeredStop"
          v-model="useLastStop"
          density="compact"
          hide-details
          class="mb-3"
          :disabled="busy"
          :label="`Completed at last timer stop (${lastStopLabel})`"
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
