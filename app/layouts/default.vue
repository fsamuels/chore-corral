<script setup lang="ts">
const user = useSupabaseUser()
const { applyTheme } = useThemePreference()

// Apply the saved theme during SSR and again when auth state changes (the
// signed-in user's metadata may carry a different preference than the cookie).
applyTheme()
watch(user, () => applyTheme())
</script>

<template>
  <v-app>
    <v-app-bar density="comfortable">
      <v-app-bar-title>
        <NuxtLink to="/" class="text-decoration-none" style="color: inherit">
          Chore Corral
        </NuxtLink>
      </v-app-bar-title>
      <template v-if="user" #append>
        <FarmSwitcher />
        <v-btn
          icon="mdi-format-list-checks"
          aria-label="Tasks"
          title="Tasks"
          to="/tasks"
        />
        <v-btn icon="mdi-map-outline" aria-label="Map" title="Map" to="/map" />
        <v-btn
          icon="mdi-shape-outline"
          aria-label="Categories"
          title="Categories"
          to="/categories"
        />
        <AccountMenu />
      </template>
    </v-app-bar>
    <v-main>
      <slot />
    </v-main>
    <AppFooter />
  </v-app>
</template>
