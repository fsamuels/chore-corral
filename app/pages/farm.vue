<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { createFarm, FARM_NAME_MAX_LENGTH } from '~/services/farms'

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

const showNewFarmForm = ref(false)
const newFarmName = ref('')
const creating = ref(false)
const createError = ref<string | null>(null)

async function createNewFarm() {
  if (creating.value) return
  creating.value = true
  createError.value = null
  try {
    const farmId = await createFarm(supabase, newFarmName.value)
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
  <v-container max-width="600">
    <h1 class="text-h4 mb-1">Change farm</h1>
    <p class="text-body-2 text-medium-emphasis mb-4">
      Everything in the app — chores, categories, the map — is scoped to the
      selected farm.
    </p>

    <v-alert
      v-if="farmsError"
      type="error"
      variant="tonal"
      title="Couldn't load your farms"
    >
      {{ farmsError }} — try reloading; if this persists, the database may not
      be reachable.
    </v-alert>

    <div v-else class="cc-card pa-0" style="overflow: hidden">
      <v-list>
        <v-list-item
          v-for="farm in farms ?? []"
          :key="farm.id"
          :title="farm.name"
          :active="farm.id === activeFarmId"
          prepend-icon="mdi-barn"
          @click="selectFarm(farm.id)"
        >
          <template #append>
            <v-icon
              v-if="farm.id === activeFarmId"
              icon="mdi-check"
              size="small"
            />
          </template>
        </v-list-item>
      </v-list>
      <p
        v-if="(farms?.length ?? 0) === 1"
        class="text-body-2 text-medium-emphasis px-4 pb-4"
      >
        You belong to one farm, so there's nothing to switch — you're all set.
      </p>
    </div>

    <div class="mt-6">
      <v-btn
        v-if="!showNewFarmForm"
        variant="tonal"
        color="primary"
        prepend-icon="mdi-plus"
        @click="showNewFarmForm = true"
      >
        New farm
      </v-btn>

      <template v-else>
        <h2 class="text-h6 mb-2">New farm</h2>
        <v-alert v-if="createError" type="error" variant="tonal" class="mb-3">
          {{ createError }}
        </v-alert>
        <v-form class="d-flex ga-2" @submit.prevent="createNewFarm">
          <v-text-field
            v-model="newFarmName"
            label="Farm name"
            density="comfortable"
            :maxlength="FARM_NAME_MAX_LENGTH"
            hide-details
            autofocus
          />
          <v-btn
            type="submit"
            color="primary"
            height="48"
            :loading="creating"
            :disabled="newFarmName.trim().length === 0"
          >
            Create
          </v-btn>
        </v-form>
        <p class="text-body-2 text-medium-emphasis mt-2 mb-0">
          You'll be the new farm's owner, and it becomes your active farm.
        </p>
      </template>
    </div>
  </v-container>
</template>
