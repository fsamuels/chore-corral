<script setup lang="ts">
import type { VForm } from 'vuetify/components'
import type { LocationSummary } from '~/services/locations'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const {
  locations,
  locationsError,
  loading,
  fetchLocations,
  create,
  update,
  remove,
} = useLocations()

// Fetch farms first so the active farm resolves during SSR, then load its
// locations (the composable's watch covers later farm switches).
await fetchFarms()
await fetchLocations()

// LocationPicker's fallback center, same call as the task location editor:
// center the map on the farm's default point until a pin is placed.
const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

function formatCoords(location: LocationSummary): string {
  return `${location.lat.toFixed(5)}, ${location.lng.toFixed(5)}`
}

// --- Create ---
const newName = ref('')
const newPin = ref<{ lat: number; lng: number } | null>(null)
const creating = ref(false)
const createError = ref<string | null>(null)
const nameRules = [(v: string) => !!v.trim() || 'Name is required']
const createForm = ref<VForm | null>(null)

async function submitCreate() {
  const name = newName.value.trim()
  if (!name || !newPin.value) return
  creating.value = true
  createError.value = null
  try {
    await create(name, newPin.value.lat, newPin.value.lng)
    newName.value = ''
    newPin.value = null
    // Clearing the field re-triggers `nameRules` against the now-empty
    // string, which would otherwise flash a spurious "Name is required"
    // right after a successful create. VTextField validates its new value
    // on the next tick, so resetValidation must run after that, not before.
    await nextTick()
    createForm.value?.resetValidation()
  } catch (error) {
    createError.value =
      error instanceof Error ? error.message : 'Failed to create location'
  } finally {
    creating.value = false
  }
}

// --- Edit: explicit edit mode with Save/Cancel, like the task location
// editor — a map's click/drag interactions rule out blur-commit, and
// LocationPicker itself provides GPS capture, manual placement, and pin
// removal. No auto-capture on open (editing must never overwrite an
// existing pin with wherever the editor happens to be standing).
const editingId = ref<string | null>(null)
const editName = ref('')
const editPin = ref<{ lat: number; lng: number } | null>(null)
const saving = ref(false)
const saveError = ref<string | null>(null)

function startEditing(location: LocationSummary) {
  editingId.value = location.id
  editName.value = location.name
  editPin.value = { lat: location.lat, lng: location.lng }
  saveError.value = null
}

function cancelEditing() {
  editingId.value = null
  saveError.value = null
}

async function saveEditing() {
  const id = editingId.value
  const name = editName.value.trim()
  if (!id || !name || !editPin.value) return
  saving.value = true
  saveError.value = null
  try {
    await update(id, name, editPin.value.lat, editPin.value.lng)
    editingId.value = null
  } catch (error) {
    saveError.value =
      error instanceof Error ? error.message : 'Failed to save location'
  } finally {
    saving.value = false
  }
}

// --- Delete confirmation dialog state ---
const toDelete = ref<LocationSummary | null>(null)
const deleting = ref(false)
const deleteError = ref<string | null>(null)
const blockedMessage = ref<string | null>(null)
const showBlocked = ref(false)

function confirmDelete(location: LocationSummary) {
  toDelete.value = location
  deleteError.value = null
}

function cancelDelete() {
  toDelete.value = null
}

async function performDelete() {
  if (!toDelete.value) return
  deleting.value = true
  deleteError.value = null
  try {
    const result = await remove(toDelete.value.id)
    if (!result.deleted) {
      const n = result.activeTaskCount
      blockedMessage.value = `Can't delete — ${n} active task${
        n === 1 ? '' : 's'
      } still use${n === 1 ? 's' : ''} this location.`
      showBlocked.value = true
    }
    toDelete.value = null
  } catch (error) {
    deleteError.value =
      error instanceof Error ? error.message : 'Failed to delete location'
  } finally {
    deleting.value = false
  }
}
</script>

<template>
  <v-container>
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
      <h1 class="text-h4 mb-1">Locations</h1>
      <p class="cc-eyebrow mb-6">{{ activeFarm.name }}</p>

      <v-form
        ref="createForm"
        class="cc-card mb-6"
        @submit.prevent="submitCreate"
      >
        <v-text-field
          v-model="newName"
          label="New location"
          :rules="nameRules"
          :disabled="creating"
          density="comfortable"
          variant="outlined"
          hide-details="auto"
          class="mb-3"
        />
        <LocationPicker
          v-model="newPin"
          :fallback-center="farmCenter"
          :disabled="creating"
        />
        <div class="d-flex justify-end mt-3">
          <v-btn
            type="submit"
            color="primary"
            :loading="creating"
            :disabled="!newName.trim() || !newPin"
          >
            Add
          </v-btn>
        </div>
        <v-alert
          v-if="createError"
          type="error"
          variant="tonal"
          density="compact"
          class="mt-2"
        >
          {{ createError }}
        </v-alert>
      </v-form>

      <v-alert
        v-if="locationsError"
        type="error"
        variant="tonal"
        title="Couldn't load locations"
        class="mb-4"
      >
        {{ locationsError }} — try reloading; if this persists, the database may
        not be reachable.
      </v-alert>

      <div v-else-if="loading && locations === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="!locations || locations.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-map-marker-multiple-outline" size="64" class="mb-4" />
        <p class="text-body-1">
          No locations yet. Add one above to start pinning tasks to named
          places.
        </p>
      </div>

      <div v-else class="cc-card pa-0" style="overflow: hidden">
        <v-list lines="two">
          <template v-for="location in locations" :key="location.id">
            <div v-if="editingId === location.id" class="pa-4">
              <v-text-field
                v-model="editName"
                label="Name"
                :rules="nameRules"
                :disabled="saving"
                density="comfortable"
                variant="outlined"
                hide-details="auto"
                class="mb-3"
              />
              <LocationPicker
                v-model="editPin"
                :fallback-center="farmCenter"
                :disabled="saving"
              />
              <v-alert
                v-if="saveError"
                type="error"
                variant="tonal"
                density="compact"
                class="mt-2"
              >
                {{ saveError }}
              </v-alert>
              <div class="d-flex justify-end ga-2 mt-3">
                <v-btn size="small" :disabled="saving" @click="cancelEditing">
                  Cancel
                </v-btn>
                <v-btn
                  size="small"
                  color="primary"
                  :loading="saving"
                  :disabled="!editName.trim() || !editPin"
                  @click="saveEditing"
                >
                  Save
                </v-btn>
              </div>
            </div>
            <v-list-item
              v-else
              :title="location.name"
              :subtitle="formatCoords(location)"
            >
              <template #append>
                <div class="d-flex ga-2">
                  <button
                    type="button"
                    class="cc-icon-btn cc-icon-btn--sm"
                    :aria-label="`Edit ${location.name}`"
                    :title="`Edit ${location.name}`"
                    @click="startEditing(location)"
                  >
                    <v-icon icon="mdi-pencil-outline" size="18" />
                  </button>
                  <button
                    type="button"
                    class="cc-icon-btn cc-icon-btn--sm"
                    :aria-label="`Delete ${location.name}`"
                    :title="`Delete ${location.name}`"
                    @click="confirmDelete(location)"
                  >
                    <v-icon icon="mdi-delete-outline" size="18" />
                  </button>
                </div>
              </template>
            </v-list-item>
            <v-divider />
          </template>
        </v-list>
      </div>
    </template>

    <v-dialog :model-value="toDelete !== null" max-width="420" persistent>
      <v-card>
        <v-card-title>Delete location?</v-card-title>
        <v-card-text>
          Delete “{{ toDelete?.name }}”? This can't be undone.
          <v-alert
            v-if="deleteError"
            type="error"
            variant="tonal"
            density="compact"
            class="mt-3"
          >
            {{ deleteError }}
          </v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn :disabled="deleting" @click="cancelDelete">Cancel</v-btn>
          <v-btn color="error" :loading="deleting" @click="performDelete">
            Delete
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="showBlocked" color="warning" :timeout="6000">
      {{ blockedMessage }}
    </v-snackbar>
  </v-container>
</template>
