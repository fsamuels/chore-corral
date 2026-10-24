<script setup lang="ts">
// Shared confirm dialog (delete category/location/chore/session, revoke
// invite): slab title, body slot, inline error, and a full-width
// Cancel / confirm pill pair. The confirm pill is filled danger red by
// default; pass `tone="accent"` for a non-destructive confirm.
const open = defineModel<boolean>({ required: true })

withDefaults(
  defineProps<{
    title: string
    confirmLabel: string
    tone?: 'danger' | 'accent'
    busy?: boolean
    error?: string | null
  }>(),
  { tone: 'danger', busy: false, error: null },
)

defineEmits<{ confirm: [] }>()
</script>

<template>
  <v-dialog v-model="open" max-width="440" persistent>
    <v-card class="cc-dialog-card">
      <v-card-title>{{ title }}</v-card-title>
      <v-card-text>
        <slot />
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
          @click="open = false"
        >
          Cancel
        </button>
        <button
          type="button"
          :class="[
            'cc-pill-btn cc-pill-btn--lg',
            tone === 'danger'
              ? 'cc-pill-btn--danger-solid'
              : 'cc-pill-btn--accent',
          ]"
          :disabled="busy"
          @click="$emit('confirm')"
        >
          <v-progress-circular v-if="busy" indeterminate size="18" width="2" />
          <template v-else>{{ confirmLabel }}</template>
        </button>
      </div>
    </v-card>
  </v-dialog>
</template>
