<script setup lang="ts">
const user = useSupabaseUser()
const supabase = useSupabaseClient()
const { resetFarms, activeFarm } = useFarms()
const { applyTheme } = useThemePreference()
const { mobile } = useDisplay()

// Pages already call `fetchFarms()` on load, and `useFarms`' state is shared
// (`useState`), so the layout just reads `activeFarm` reactively rather than
// fetching itself — fetching here too would be redundant, and awaiting a
// fetch in the layout would block rendering the app bar when signed out.
const appBarTitle = computed(() =>
  activeFarm.value ? `Chore Corral - ${activeFarm.value.name}` : 'Chore Corral',
)

// Apply the saved theme during SSR and again when auth state changes (the
// signed-in user's metadata may carry a different preference than the cookie).
applyTheme()
watch(user, () => applyTheme())

const drawer = ref(false)

async function signOut() {
  drawer.value = false
  await supabase.auth.signOut()
  resetFarms()
  await navigateTo('/login')
}
</script>

<template>
  <v-app>
    <v-app-bar density="comfortable">
      <template v-if="user" #prepend>
        <v-app-bar-nav-icon aria-label="Menu" @click="drawer = !drawer" />
      </template>
      <v-app-bar-title>
        <NuxtLink to="/" class="text-decoration-none" style="color: inherit">
          {{ appBarTitle }}
        </NuxtLink>
      </v-app-bar-title>
      <template v-if="user && !mobile" #append>
        <v-btn icon="mdi-home-outline" aria-label="Home" title="Home" to="/" />
        <v-btn icon="mdi-map-outline" aria-label="Map" title="Map" to="/map" />
      </template>
    </v-app-bar>

    <v-navigation-drawer v-if="user" v-model="drawer" temporary>
      <v-list density="compact" nav>
        <v-list-item
          :title="user?.email ?? 'Account'"
          prepend-icon="mdi-account-circle"
        />
        <v-divider class="mb-1" />
        <v-list-item
          title="Tasks"
          prepend-icon="mdi-format-list-checks"
          to="/tasks"
          @click="drawer = false"
        />
        <v-list-item
          title="Categories"
          prepend-icon="mdi-shape-outline"
          to="/categories"
          @click="drawer = false"
        />
        <v-divider class="my-1" />
        <v-list-item
          title="Change farm"
          prepend-icon="mdi-barn"
          to="/farm"
          @click="drawer = false"
        />
        <v-list-item
          title="Settings"
          prepend-icon="mdi-cog-outline"
          to="/settings"
          @click="drawer = false"
        />
        <v-divider class="my-1" />
        <v-list-item
          title="Sign out"
          prepend-icon="mdi-logout"
          @click="signOut"
        />
      </v-list>
    </v-navigation-drawer>

    <v-main>
      <slot />
    </v-main>

    <v-bottom-navigation v-if="user && mobile" grow>
      <v-btn to="/">
        <v-icon icon="mdi-home-outline" />
        Home
      </v-btn>
      <v-btn to="/map">
        <v-icon icon="mdi-map-outline" />
        Map
      </v-btn>
    </v-bottom-navigation>

    <AppFooter />
  </v-app>
</template>
