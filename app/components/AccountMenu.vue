<script setup lang="ts">
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { resetFarms } = useFarms()
const { preference, setBrand, setDark } = useThemePreference()

async function signOut() {
  await supabase.auth.signOut()
  resetFarms()
  await navigateTo('/login')
}
</script>

<template>
  <v-menu location="bottom end" :close-on-content-click="false">
    <template #activator="{ props }">
      <v-btn
        icon="mdi-account-circle"
        aria-label="Account"
        title="Account"
        v-bind="props"
      />
    </template>
    <v-card min-width="260">
      <v-list density="compact">
        <v-list-item
          :title="user?.email ?? 'Account'"
          prepend-icon="mdi-account-circle"
        />
        <v-divider />
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
        <v-divider />
        <v-list-item
          title="Sign out"
          prepend-icon="mdi-logout"
          @click="signOut"
        />
      </v-list>
    </v-card>
  </v-menu>
</template>
