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

    <div class="d-flex align-center flex-wrap ga-2 mb-2">
      <v-btn
        size="small"
        variant="tonal"
        prepend-icon="mdi-camera"
        @click="cameraInput?.click()"
      >
        Take photo
      </v-btn>
      <v-btn
        size="small"
        variant="tonal"
        prepend-icon="mdi-image-multiple"
        @click="galleryInput?.click()"
      >
        Choose from gallery
      </v-btn>
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
            class="rounded"
          />
          <v-btn
            icon="mdi-close"
            size="x-small"
            variant="flat"
            color="surface"
            class="position-absolute"
            style="top: 4px; right: 4px"
            aria-label="Remove photo"
            title="Remove photo"
            @click="onRemove(photo)"
          />
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
