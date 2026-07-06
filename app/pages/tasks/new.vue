<script setup lang="ts">
import type { Database } from '~/types/database.types'
import type { TaskPriority } from '~/services/tasks'
import { uploadTaskPhoto } from '~/services/photos'
import { compressImage } from '~/utils/photo-compression'
import type { StagedPhoto } from '~/components/StagedTaskPhotos.vue'

const supabase = useSupabaseClient<Database>()
const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
const { create } = useTasks()
const { categories, fetchCategories } = useCategories()
const { tags, fetchTags } = useTags()

await fetchFarms()
await fetchCategories()
await fetchTags()

const tagSuggestions = computed(() => (tags.value ?? []).map((t) => t.name))

const priorityItems: { title: string; value: TaskPriority }[] = [
  { title: 'Urgent', value: 'urgent' },
  { title: 'Soon', value: 'soon' },
  { title: 'Whenever', value: 'whenever' },
]

const categoryItems = computed(() => [
  { title: 'Uncategorized', value: null },
  ...(categories.value ?? []).map((category) => ({
    title: category.name,
    value: category.id,
  })),
])

// Mini-map starting point before a pin exists (SPEC: the farm's default map
// center, manually set at farm creation — may be unset).
const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

const title = ref('')
const categoryId = ref<string | null>(null)
const priority = ref<TaskPriority>('whenever')
const dueDate = ref('')
const notes = ref('')
const taskTags = ref<string[]>([])
const location = ref<{ lat: number; lng: number } | null>(null)
const stagedPhotos = ref<StagedPhoto[]>([])
const moreDetailsOpen = ref(false)

const creating = ref(false)
const createError = ref<string | null>(null)
const titleRules = [(v: string) => !!v.trim() || 'Title is required']

async function submit() {
  const trimmedTitle = title.value.trim()
  if (!trimmedTitle) return
  creating.value = true
  createError.value = null
  try {
    const created = await create({
      title: trimmedTitle,
      categoryId: categoryId.value,
      priority: priority.value,
      dueDate: dueDate.value || null,
      notes: notes.value || null,
      lat: location.value?.lat ?? null,
      lng: location.value?.lng ?? null,
      tagNames: taskTags.value,
    })

    // Photo uploads happen only after the task itself exists — sequential,
    // and a failed upload here doesn't undo the (already successful) task
    // creation. Failures are surfaced as a one-time warning on the view page
    // rather than blocking navigation.
    const farmId = activeFarmId.value
    let failedCount = 0
    if (farmId) {
      for (const photo of stagedPhotos.value) {
        try {
          const blob = await compressImage(photo.file)
          await uploadTaskPhoto(supabase, {
            farmId,
            taskId: created.id,
            blob,
            caption: photo.caption,
          })
        } catch {
          failedCount += 1
        }
      }
    }

    await navigateTo(
      failedCount > 0
        ? `/tasks/${created.id}?photoWarning=${failedCount}`
        : `/tasks/${created.id}`,
    )
  } catch (error) {
    createError.value =
      error instanceof Error ? error.message : 'Failed to create task'
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <v-container style="max-width: 640px">
    <v-alert
      v-if="farmsError"
      type="error"
      variant="tonal"
      title="Couldn't load your farms"
      class="mb-4"
    >
      {{ farmsError }} — try reloading; if this persists, the database may not
      be reachable.
    </v-alert>

    <template v-else-if="activeFarm">
      <v-btn
        variant="text"
        prepend-icon="mdi-arrow-left"
        to="/tasks"
        class="mb-2"
      >
        Back to tasks
      </v-btn>

      <h1 class="text-h4 mb-4">New task</h1>

      <v-form @submit.prevent="submit">
        <v-text-field
          v-model="title"
          label="Title"
          :rules="titleRules"
          :disabled="creating"
          density="comfortable"
          variant="outlined"
          hide-details="auto"
          class="mb-4"
          autofocus
        />
        <v-select
          v-model="categoryId"
          :items="categoryItems"
          label="Category"
          :disabled="creating"
          density="comfortable"
          variant="outlined"
          hide-details
          class="mb-4"
        />
        <v-select
          v-model="priority"
          :items="priorityItems"
          label="Priority"
          :disabled="creating"
          density="comfortable"
          variant="outlined"
          hide-details
          class="mb-2"
        />

        <v-btn
          variant="text"
          size="small"
          :append-icon="moreDetailsOpen ? 'mdi-chevron-up' : 'mdi-chevron-down'"
          class="mt-2 mb-2"
          @click="moreDetailsOpen = !moreDetailsOpen"
        >
          More details
        </v-btn>

        <div v-if="moreDetailsOpen">
          <v-textarea
            v-model="notes"
            label="Notes"
            rows="3"
            :disabled="creating"
            density="comfortable"
            variant="outlined"
            hide-details
            class="mb-4"
          />
          <v-combobox
            v-model="taskTags"
            :items="tagSuggestions"
            label="Tags"
            multiple
            chips
            closable-chips
            :disabled="creating"
            density="comfortable"
            variant="outlined"
            hide-details
            class="mb-4"
          />
          <v-text-field
            v-model="dueDate"
            label="Due date"
            type="date"
            :disabled="creating"
            density="comfortable"
            variant="outlined"
            hide-details
            class="mb-4"
          />
          <p class="text-body-2 mb-2">Location</p>
          <LocationPicker
            v-model="location"
            auto-capture
            :fallback-center="farmCenter"
            :disabled="creating"
            class="mb-4"
          />

          <v-divider class="my-4" />
          <StagedTaskPhotos v-model:staged="stagedPhotos" />
        </div>

        <v-alert
          v-if="createError"
          type="error"
          variant="tonal"
          density="compact"
          class="mt-4"
        >
          {{ createError }}
        </v-alert>

        <div class="d-flex justify-end ga-2 mt-6">
          <v-btn size="large" :disabled="creating" to="/tasks">Cancel</v-btn>
          <v-btn
            type="submit"
            color="primary"
            size="large"
            :loading="creating"
            :disabled="!title.trim()"
          >
            Add
          </v-btn>
        </div>
      </v-form>
    </template>
  </v-container>
</template>
