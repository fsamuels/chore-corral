<script setup lang="ts">
const user = useSupabaseUser()
const { preference, setBrand, setDark } = useThemePreference()
</script>

<template>
  <v-container max-width="600">
    <h1 class="text-h4 mb-1">Settings</h1>
    <p class="text-body-2 text-medium-emphasis mb-4">
      Signed in as {{ user?.email }}
    </p>

    <v-card>
      <v-list>
        <v-list-subheader>Theme</v-list-subheader>
        <v-list-item
          v-for="brand in THEME_BRANDS"
          :key="brand.id"
          :title="brand.label"
          :active="preference.brand === brand.id"
          @click="setBrand(brand.id)"
        >
          <template #prepend>
            <v-avatar :color="brand.swatch" size="20" />
          </template>
          <template #append>
            <v-icon
              v-if="preference.brand === brand.id"
              icon="mdi-check"
              size="small"
            />
          </template>
        </v-list-item>
        <v-divider />
        <v-list-item
          :title="preference.dark ? 'Dark mode' : 'Light mode'"
          @click="setDark(!preference.dark)"
        >
          <template #prepend>
            <v-icon
              :icon="
                preference.dark
                  ? 'mdi-weather-night'
                  : 'mdi-white-balance-sunny'
              "
            />
          </template>
          <template #append>
            <v-switch
              :model-value="preference.dark"
              density="compact"
              hide-details
              @update:model-value="setDark($event === true)"
              @click.stop
            />
          </template>
        </v-list-item>
      </v-list>
    </v-card>
  </v-container>
</template>
