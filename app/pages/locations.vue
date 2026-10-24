<script setup lang="ts">
import type { VForm } from 'vuetify/components'
import type {
  LocationSummary,
  LocationSummaryWithCount,
} from '~/services/locations'
import { TASK_STATUSES } from '~/services/tags'
import { STATUS_DISPLAY } from '~/utils/task-display'

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
const { locations: locationSummaries, fetchLocations: fetchLocationSummaries } =
  useLocationSummaries()

// Fetch farms first so the active farm resolves during SSR, then load its
// locations (the composable's watch covers later farm switches).
await fetchFarms()
await Promise.all([fetchLocations(), fetchLocationSummaries()])

function summaryFor(
  location: LocationSummary,
): LocationSummaryWithCount | undefined {
  return locationSummaries.value?.find((summary) => summary.id === location.id)
}

// Deep-link into the tasks page filtered by this location (and optionally a
// status). Mirrors `tags.vue`'s `tasksLink`/`categories.vue`'s, but by id.
function tasksLink(location: LocationSummary, status?: string): string {
  const params = new URLSearchParams({ location: location.id })
  if (status) params.set('status', status)
  return `/tasks?${params.toString()}`
}

function statusEntries(location: LocationSummary) {
  const summary = summaryFor(location)
  return TASK_STATUSES.map((status) => ({
    status,
    label: STATUS_DISPLAY[status].label,
    icon: STATUS_DISPLAY[status].icon,
    count: summary?.statusCounts[status] ?? 0,
    to: tasksLink(location, status),
  }))
}

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
    await fetchLocationSummaries()
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
    await fetchLocationSummaries()
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

// ConfirmDialog drives its own open state; closing (Cancel) clears the target.
const deleteOpen = computed({
  get: () => toDelete.value !== null,
  set: (open: boolean) => {
    if (!open) toDelete.value = null
  },
})

async function performDelete() {
  if (!toDelete.value) return
  deleting.value = true
  deleteError.value = null
  try {
    const result = await remove(toDelete.value.id)
    if (!result.deleted) {
      const n = result.activeTaskCount
      blockedMessage.value = `Can't delete — ${n} active chore${
        n === 1 ? '' : 's'
      } still use${n === 1 ? 's' : ''} this location.`
      showBlocked.value = true
    } else {
      await fetchLocationSummaries()
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
  <div class="cc-page">
    <LoadErrorAlert
      v-if="farmsError"
      title="Couldn't load your farms"
      :message="farmsError"
      :retry="() => fetchFarms()"
    />
    <template v-else-if="activeFarm">
      <PageHeader title="Locations" />

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
        <v-alert
          v-if="createError"
          type="error"
          variant="tonal"
          density="compact"
          class="mt-2"
        >
          {{ createError }}
        </v-alert>
        <div class="cc-actions">
          <button
            type="submit"
            class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
            :disabled="creating || !newName.trim() || !newPin"
          >
            <v-progress-circular
              v-if="creating"
              indeterminate
              size="18"
              width="2"
            />
            Add location
          </button>
        </div>
      </v-form>

      <LoadErrorAlert
        v-if="locationsError"
        title="Couldn't load locations"
        :message="locationsError"
        :retry="() => fetchLocations()"
      />

      <ListSkeleton v-else-if="loading && locations === null" />

      <EmptyState
        v-else-if="!locations || locations.length === 0"
        icon="mdi-map-marker-multiple-outline"
      >
        No locations yet. Add one above to start pinning chores to named places.
      </EmptyState>

      <div v-else class="cc-card cc-card--list">
        <v-list lines="three">
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
              <div class="cc-actions">
                <button
                  type="button"
                  class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm"
                  :disabled="saving"
                  @click="cancelEditing"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
                  :disabled="saving || !editName.trim() || !editPin"
                  @click="saveEditing"
                >
                  <v-progress-circular
                    v-if="saving"
                    indeterminate
                    size="18"
                    width="2"
                  />
                  Save
                </button>
              </div>
            </div>
            <v-list-item v-else lines="three">
              <template #title>
                <NuxtLink :to="tasksLink(location)" class="entity-row__title">
                  <span>{{ location.name }}</span>
                  <span class="cc-pill cc-pill--muted entity-row__total">
                    {{ summaryFor(location)?.taskCount ?? 0 }} chore{{
                      (summaryFor(location)?.taskCount ?? 0) === 1 ? '' : 's'
                    }}
                  </span>
                </NuxtLink>
              </template>
              <template #subtitle>
                <div>{{ formatCoords(location) }}</div>
                <div class="entity-row__statuses">
                  <template
                    v-for="entry in statusEntries(location)"
                    :key="entry.status"
                  >
                    <NuxtLink
                      v-if="entry.count > 0"
                      :to="entry.to"
                      class="cc-status-chip cc-status-chip--link"
                    >
                      <v-icon :icon="entry.icon" size="14" />
                      <span
                        >{{ entry.count }} {{ entry.label.toLowerCase() }}</span
                      >
                    </NuxtLink>
                    <span v-else class="cc-status-chip cc-status-chip--empty">
                      <v-icon :icon="entry.icon" size="14" />
                      <span>0 {{ entry.label.toLowerCase() }}</span>
                    </span>
                  </template>
                </div>
              </template>
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

    <ConfirmDialog
      v-model="deleteOpen"
      title="Delete location?"
      confirm-label="Delete"
      :busy="deleting"
      :error="deleteError"
      @confirm="performDelete"
    >
      “{{ toDelete?.name }}” will be permanently deleted.
    </ConfirmDialog>

    <v-snackbar v-model="showBlocked" color="warning" :timeout="6000">
      {{ blockedMessage }}
    </v-snackbar>
  </div>
</template>

<style scoped>
.entity-row__title {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: var(--cc-ink);
}

.entity-row__total {
  flex-shrink: 0;
}

.entity-row__statuses {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 6px;
  white-space: normal;
}
</style>
