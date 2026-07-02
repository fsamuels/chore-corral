<script setup lang="ts">
const user = useSupabaseUser()
const { fetchFarms, activeFarm, farmsError } = useFarms()

await fetchFarms()
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
      <h1 class="text-h4 mb-1">{{ activeFarm.name }}</h1>
      <p class="text-body-2 text-medium-emphasis mb-6">
        Signed in as {{ user?.email }}
      </p>
      <v-card variant="tonal">
        <v-card-text>
          Tasks will show up here once task tracking lands (M5). Use the farm
          name in the top bar to switch farms.
        </v-card-text>
      </v-card>
    </template>
  </v-container>
</template>
