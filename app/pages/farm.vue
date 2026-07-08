<script setup lang="ts">
const { farms, farmsError, fetchFarms, activeFarmId, setActiveFarm } =
  useFarms()

await fetchFarms()

async function selectFarm(farmId: string) {
  if (farmId === activeFarmId.value) return
  setActiveFarm(farmId)
  await navigateTo('/')
}
</script>

<template>
  <v-container max-width="600">
    <h1 class="text-h4 mb-1">Change farm</h1>
    <p class="text-body-2 text-medium-emphasis mb-4">
      Everything in the app — tasks, categories, the map — is scoped to the
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

    <v-card v-else>
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
      <v-card-text
        v-if="(farms?.length ?? 0) === 1"
        class="text-body-2 text-medium-emphasis pt-0"
      >
        You belong to one farm, so there's nothing to switch — you're all set.
      </v-card-text>
    </v-card>
  </v-container>
</template>
