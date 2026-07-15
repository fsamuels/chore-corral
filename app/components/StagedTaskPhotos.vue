<script setup lang="ts">
// Photos staged during task *creation*, before a task id exists. Genuinely
// different from `TaskPhotos.vue`/`useTaskPhotos`, which are keyed on an
// existing task id (the storage path and `task_photos` row both need one) —
// rather than thread a "staged" branch through every function there, this
// component holds plain in-memory Files with local object-URL previews and
// does no compression/upload at all until the parent (the create page)
// submits and has a real task id to upload against.
import { MAX_UPLOAD_BYTES } from '~/utils/photo-compression'

export interface StagedPhoto {
  localId: string
  file: File
  previewUrl: string
  caption: string
}

const staged = defineModel<StagedPhoto[]>('staged', { default: () => [] })

const sizeError = ref<string | null>(null)

const cameraInput = ref<HTMLInputElement | null>(null)
const galleryInput = ref<HTMLInputElement | null>(null)

function onFileSelected(event: Event): void {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  // Reset before handling so re-selecting the same file still fires `change`.
  input.value = ''
  if (!file) return

  sizeError.value = null
  if (file.size > MAX_UPLOAD_BYTES) {
    sizeError.value = 'Photo is too large — the maximum is 10MB.'
    return
  }

  staged.value = [
    ...staged.value,
    {
      localId: crypto.randomUUID(),
      file,
      previewUrl: URL.createObjectURL(file),
      caption: '',
    },
  ]
}

function onRemove(photo: StagedPhoto): void {
  URL.revokeObjectURL(photo.previewUrl)
  staged.value = staged.value.filter((p) => p.localId !== photo.localId)
}

// A staged photo not submitted (navigated away) still leaks its object URL
// otherwise — revoke whatever's left on unmount.
onUnmounted(() => {
  for (const photo of staged.value) URL.revokeObjectURL(photo.previewUrl)
})
</script>

<template>
  <div>
    <p class="cc-eyebrow mb-2">Photos</p>

    <input
      ref="cameraInput"
      type="file"
      accept="image/*"
      capture="environment"
      class="d-none"
      @change="onFileSelected"
    />
    <input
      ref="galleryInput"
      type="file"
      accept="image/*"
      class="d-none"
      @change="onFileSelected"
    />

    <div class="photos-actions mb-2">
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm"
        @click="cameraInput?.click()"
      >
        <v-icon icon="mdi-camera" size="16" />
        Take photo
      </button>
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm"
        @click="galleryInput?.click()"
      >
        <v-icon icon="mdi-image-multiple" size="16" />
        Gallery
      </button>
    </div>

    <v-alert
      v-if="sizeError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ sizeError }}
    </v-alert>

    <p v-if="staged.length === 0" class="text-body-2 text-medium-emphasis">
      No photos yet — added photos will upload once the task is created.
    </p>

    <div v-else class="d-flex flex-wrap ga-3">
      <div v-for="photo in staged" :key="photo.localId" style="width: 140px">
        <div class="position-relative">
          <v-img
            :src="photo.previewUrl"
            width="140"
            height="140"
            cover
            class="photos-thumb"
          />
          <button
            type="button"
            class="cc-icon-btn cc-icon-btn--sm photos-thumb__remove"
            aria-label="Remove photo"
            title="Remove photo"
            @click="onRemove(photo)"
          >
            <v-icon icon="mdi-close" size="16" />
          </button>
        </div>
        <v-text-field
          v-model="photo.caption"
          placeholder="Add a caption"
          density="compact"
          variant="underlined"
          hide-details
          class="mt-1"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Two equal-width outlined pills side by side on mobile widths. */
.photos-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.photos-thumb {
  border-radius: var(--cc-radius);
}

/* Remove (x) button overlapping the thumbnail's top-right corner. */
.photos-thumb__remove {
  position: absolute;
  top: -8px;
  right: -8px;
}
</style>
