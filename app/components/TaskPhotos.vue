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

// Fullscreen gallery: opened from a thumbnail, `activeIndex` tracks which
// photo the carousel is showing so the counter and keyboard nav stay in sync.
const lightboxOpen = ref(false)
const activeIndex = ref(0)

function openLightbox(index: number): void {
  activeIndex.value = index
  lightboxOpen.value = true
}

function onLightboxKeydown(event: KeyboardEvent): void {
  if (!photos.value || photos.value.length === 0) return
  if (event.key === 'ArrowRight') {
    activeIndex.value = (activeIndex.value + 1) % photos.value.length
  } else if (event.key === 'ArrowLeft') {
    activeIndex.value =
      (activeIndex.value - 1 + photos.value.length) % photos.value.length
  }
}

// v-dialog teleports its content, so a @keydown on the component itself
// won't reliably catch key events — listen on window instead, scoped to
// while the gallery is actually open.
watch(lightboxOpen, (open) => {
  if (open) window.addEventListener('keydown', onLightboxKeydown)
  else window.removeEventListener('keydown', onLightboxKeydown)
})
onUnmounted(() => window.removeEventListener('keydown', onLightboxKeydown))

// A photo deleted while the gallery is open (its own delete button is still
// reachable behind the dialog on some layouts) shouldn't leave the carousel
// pointed past the end, or open with nothing left to show.
watch(photos, (list) => {
  if (!list || list.length === 0) {
    lightboxOpen.value = false
    return
  }
  if (activeIndex.value > list.length - 1) activeIndex.value = list.length - 1
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
        :disabled="uploading"
        @click="cameraInput?.click()"
      >
        <v-icon icon="mdi-camera" size="16" />
        Take photo
      </button>
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm"
        :disabled="uploading"
        @click="galleryInput?.click()"
      >
        <v-icon icon="mdi-image-multiple" size="16" />
        Gallery
      </button>
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
      <div
        v-for="(photo, index) in photos"
        :key="photo.id"
        style="width: 140px"
      >
        <div class="position-relative">
          <v-img
            :src="photoUrls.get(photo.id)"
            width="140"
            height="140"
            cover
            class="photos-thumb cursor-pointer"
            @click="openLightbox(index)"
          />
          <button
            type="button"
            class="cc-icon-btn cc-icon-btn--sm photos-thumb__remove"
            :disabled="pendingDeletes.has(photo.id)"
            :aria-label="`Delete photo`"
            title="Delete photo"
            @click="onDelete(photo)"
          >
            <v-progress-circular
              v-if="pendingDeletes.has(photo.id)"
              indeterminate
              size="14"
              width="2"
            />
            <v-icon v-else icon="mdi-close" size="16" />
          </button>
        </div>
        <input
          v-model="captions[photo.id]"
          type="text"
          placeholder="Add a caption"
          class="cc-field photos-caption mt-2"
          @blur="onCaptionBlur(photo)"
        />
        <p class="text-caption text-medium-emphasis mb-0 mt-1">
          Added {{ formatTaken(photo.taken_at) }}
        </p>
      </div>
    </div>

    <v-dialog
      v-model="lightboxOpen"
      fullscreen
      transition="dialog-bottom-transition"
    >
      <v-card v-if="photos && photos.length > 0" color="black">
        <v-toolbar color="black" density="compact">
          <v-toolbar-title class="text-white text-body-2">
            {{ activeIndex + 1 }} / {{ photos.length }}
          </v-toolbar-title>
          <v-spacer />
          <v-btn
            icon="mdi-close"
            color="white"
            aria-label="Close gallery"
            @click="lightboxOpen = false"
          />
        </v-toolbar>
        <v-carousel
          v-model="activeIndex"
          height="calc(100vh - 48px)"
          hide-delimiters
          show-arrows="hover"
          color="white"
        >
          <v-carousel-item v-for="photo in photos" :key="photo.id">
            <div
              class="d-flex flex-column align-center justify-center fill-height pa-4"
            >
              <v-img
                :src="photoUrls.get(photo.id)"
                height="85%"
                width="100%"
                contain
              />
              <p
                v-if="photo.caption"
                class="text-white text-body-1 mt-3 text-center"
              >
                {{ photo.caption }}
              </p>
              <p class="text-white text-caption text-medium-emphasis mb-0">
                {{ formatTaken(photo.taken_at) }}
              </p>
            </div>
          </v-carousel-item>
        </v-carousel>
      </v-card>
    </v-dialog>
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

.photos-caption {
  height: 44px;
  padding: 0 12px;
}
</style>
