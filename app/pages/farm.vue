<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { createFarmOnce, FARM_NAME_MAX_LENGTH } from '~/services/farms'

const supabase = useSupabaseClient<Database>()
const {
  farms,
  farmsError,
  fetchFarms,
  refreshFarms,
  activeFarmId,
  setActiveFarm,
} = useFarms()

await fetchFarms()

async function selectFarm(farmId: string) {
  if (farmId === activeFarmId.value) return
  setActiveFarm(farmId)
  await navigateTo('/')
}

const createFarm = createFarmOnce(supabase)
const showNewFarmForm = ref(false)
const newFarmName = ref('')
const creating = ref(false)
const createError = ref<string | null>(null)

function cancelNewFarm() {
  showNewFarmForm.value = false
  newFarmName.value = ''
  createError.value = null
}

async function createNewFarm() {
  if (creating.value) return
  creating.value = true
  createError.value = null
  try {
    const farmId = await createFarm(newFarmName.value)
    setActiveFarm(farmId)
    await refreshFarms()
    await navigateTo('/')
  } catch (error) {
    createError.value =
      error instanceof Error ? error.message : 'Something went wrong.'
  } finally {
    creating.value = false
  }
}
</script>

<template>
  <div class="cc-page cc-page--narrow">
    <PageHeader title="Change farm">
      Everything in the app — chores, categories, the map — is scoped to the
      selected farm.
    </PageHeader>

    <LoadErrorAlert
      v-if="farmsError"
      title="Couldn't load your farms"
      :message="farmsError"
    />

    <EmptyState v-else-if="(farms?.length ?? 0) === 0" icon="mdi-barn">
      You don't belong to any farms yet.
    </EmptyState>

    <div v-else class="cc-card cc-card--list">
      <v-list>
        <v-list-item
          v-for="farm in farms"
          :key="farm.id"
          :title="farm.name"
          :active="farm.id === activeFarmId"
          :aria-current="farm.id === activeFarmId ? 'true' : undefined"
          prepend-icon="mdi-barn"
          @click="selectFarm(farm.id)"
        >
          <template #append>
            <v-icon
              v-if="farm.id === activeFarmId"
              icon="mdi-check"
              size="small"
              aria-label="Current farm"
            />
          </template>
        </v-list-item>
      </v-list>
      <p v-if="farms?.length === 1" class="cc-muted px-4 pb-4">
        You belong to one farm, so there's nothing to switch — you're all set.
      </p>
    </div>

    <div class="mt-6">
      <button
        v-if="!showNewFarmForm"
        type="button"
        class="cc-pill-btn cc-pill-btn--ghost cc-pill-btn--sm"
        @click="showNewFarmForm = true"
      >
        <v-icon icon="mdi-plus" size="18" />
        New farm
      </button>

      <template v-else>
        <h2 class="cc-section-title mb-2">New farm</h2>
        <v-alert v-if="createError" type="error" variant="tonal" class="mb-3">
          {{ createError }}
        </v-alert>
        <v-form @submit.prevent="createNewFarm">
          <v-text-field
            v-model="newFarmName"
            label="Farm name"
            variant="outlined"
            density="comfortable"
            :maxlength="FARM_NAME_MAX_LENGTH"
            hide-details
            autofocus
          />
          <div class="cc-actions">
            <button
              type="button"
              class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm"
              :disabled="creating"
              @click="cancelNewFarm"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
              :disabled="creating || newFarmName.trim().length === 0"
            >
              <v-progress-circular
                v-if="creating"
                indeterminate
                size="18"
                width="2"
              />
              Create
            </button>
          </div>
        </v-form>
        <p class="cc-muted mt-2 mb-0">
          You'll be the new farm's owner, and it becomes your active farm.
        </p>
      </template>
    </div>
  </div>
</template>
