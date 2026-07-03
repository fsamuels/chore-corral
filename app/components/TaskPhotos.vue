<script setup lang="ts">
import type { PhotoSummary } from '~/services/photos'

// Only rendered once a task exists (parent guards with v-if="editing"), so a
// task id is always present — no null case to handle here.
const props = defineProps<{ taskId: string }>()

const {
  photos,
  photoUrls,
  photosError,
  loading,
  uploading,
  uploadError,
  upload,
  remove,
  updateCaption,
} = useTaskPhotos(toRef(props, 'taskId'))

// Two file inputs: one with `capture` to open the camera on mobile, one
// without so the OS offers the photo library instead.
const cameraInput = ref<HTMLInputElement | null>(null)
const galleryInput = ref<HTMLInputElement | null>(null)

async function onFileSelected(event: Event): Promise<void> {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  // Reset before awaiting so re-selecting the same file still fires `change`.
  input.value = ''
  if (file) await upload(file)
}

// Caption drafts are edited locally and committed on blur, seeded from each
// photo as it appears.
const captions = reactive<Record<string, string>>({})
watch(
  photos,
  (list) => {
    if (!list) return
    for (const photo of list) {
      if (!(photo.id in captions)) captions[photo.id] = photo.caption ?? ''
    }
  },
  { immediate: true },
)

function onCaptionBlur(photo: PhotoSummary): void {
  const draft = (captions[photo.id] ?? '').trim()
  if (draft === (photo.caption ?? '')) return
  updateCaption(photo, draft)
}

// Per-photo in-flight delete tracking so only the affected button disables.
const pendingDeletes = ref<Set<string>>(new Set())

async function onDelete(photo: PhotoSummary): Promise<void> {
  const next = new Set(pendingDeletes.value)
  next.add(photo.id)
  pendingDeletes.value = next
  try {
    await remove(photo)
  } finally {
    const done = new Set(pendingDeletes.value)
    done.delete(photo.id)
    pendingDeletes.value = done
  }
}

function formatTaken(takenAt: string): string {
  const date = new Date(takenAt)
  return Number.isNaN(date.getTime()) ? '' : date.toLocaleDateString()
}
</script>

<template>
  <div>
    <p class="text-body-2 mb-2">Photos</p>

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
        :loading="uploading"
        :disabled="uploading"
        @click="cameraInput?.click()"
      >
        Take photo
      </v-btn>
      <v-btn
        size="small"
        variant="tonal"
        prepend-icon="mdi-image-multiple"
        :loading="uploading"
        :disabled="uploading"
        @click="galleryInput?.click()"
      >
        Choose from gallery
      </v-btn>
    </div>

    <v-alert
      v-if="uploadError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ uploadError }}
    </v-alert>

    <v-alert
      v-if="photosError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ photosError }}
    </v-alert>

    <div v-if="photos === null && loading" class="py-2">
      <v-progress-circular indeterminate size="24" color="primary" />
    </div>

    <p
      v-else-if="photos && photos.length === 0"
      class="text-body-2 text-medium-emphasis"
    >
      No photos yet.
    </p>

    <div v-else-if="photos" class="d-flex flex-wrap ga-3">
      <div v-for="photo in photos" :key="photo.id" style="width: 140px">
        <div class="position-relative">
          <v-img
            :src="photoUrls.get(photo.id)"
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
            :loading="pendingDeletes.has(photo.id)"
            :disabled="pendingDeletes.has(photo.id)"
            :aria-label="`Delete photo`"
            title="Delete photo"
            @click="onDelete(photo)"
          />
        </div>
        <v-text-field
          v-model="captions[photo.id]"
          placeholder="Add a caption"
          density="compact"
          variant="underlined"
          hide-details
          class="mt-1"
          @blur="onCaptionBlur(photo)"
        />
        <p class="text-caption text-medium-emphasis mb-0">
          {{ formatTaken(photo.taken_at) }}
        </p>
      </div>
    </div>
  </div>
</template>
