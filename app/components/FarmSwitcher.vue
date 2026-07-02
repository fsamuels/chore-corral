<script setup lang="ts">
const { farms, fetchFarms, activeFarm, activeFarmId, setActiveFarm } =
  useFarms()

// Usually warm already (the membership middleware fetches on protected
// pages); fire-and-forget covers any path that skipped it.
onMounted(() => {
  fetchFarms()
})
</script>

<template>
  <v-menu>
    <template #activator="{ props }">
      <v-btn v-bind="props" variant="text" append-icon="mdi-chevron-down">
        {{ activeFarm?.name ?? 'Select farm' }}
      </v-btn>
    </template>
    <v-list density="compact">
      <v-list-item
        v-for="farm in farms ?? []"
        :key="farm.id"
        :active="farm.id === activeFarmId"
        @click="setActiveFarm(farm.id)"
      >
        <v-list-item-title>{{ farm.name }}</v-list-item-title>
      </v-list-item>
    </v-list>
  </v-menu>
</template>
