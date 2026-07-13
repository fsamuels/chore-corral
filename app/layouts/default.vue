<script setup lang="ts">
const user = useSupabaseUser()
const supabase = useSupabaseClient()
const { resetFarms, activeFarm } = useFarms()
const { mobile } = useDisplay()

// Pages already call `fetchFarms()` on load, and `useFarms`' state is shared
// (`useState`), so the layout just reads `activeFarm` reactively rather than
// fetching itself — fetching here too would be redundant, and awaiting a
// fetch in the layout would block rendering the header when signed out.
const farmName = computed(() => activeFarm.value?.name ?? 'Chore Corral')

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
    <v-navigation-drawer v-if="user" v-model="drawer" location="end" temporary>
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
        <v-list-item
          title="Locations"
          prepend-icon="mdi-map-marker-multiple"
          to="/locations"
          @click="drawer = false"
        />
        <v-list-item
          title="Tags"
          prepend-icon="mdi-tag-multiple-outline"
          to="/tags"
          @click="drawer = false"
        />
        <v-divider class="my-1" />
        <v-list-item
          title="Change farm"
          prepend-icon="mdi-barn"
          to="/farm"
          @click="drawer = false"
        />
        <v-divider class="my-1" />
        <v-list-item
          title="UI components demo"
          prepend-icon="mdi-view-grid-outline"
          to="/components-demo"
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
      <header class="app-header">
        <div class="app-header__text">
          <NuxtLink to="/" class="app-header__link">
            <div class="cc-eyebrow">Chore Corral</div>
            <h1 class="app-header__farm">{{ farmName }}</h1>
          </NuxtLink>
        </div>
        <div v-if="user" class="app-header__actions">
          <template v-if="!mobile">
            <NuxtLink
              to="/"
              class="app-header__nav-btn"
              aria-label="Home"
              title="Home"
            >
              <v-icon icon="mdi-home-outline" size="22" />
            </NuxtLink>
            <NuxtLink
              to="/progress"
              class="app-header__nav-btn"
              aria-label="Progress"
              title="Progress"
            >
              <v-icon icon="mdi-progress-check" size="22" />
            </NuxtLink>
            <NuxtLink
              to="/map"
              class="app-header__nav-btn"
              aria-label="Map"
              title="Map"
            >
              <v-icon icon="mdi-map-outline" size="22" />
            </NuxtLink>
          </template>
          <button
            type="button"
            class="app-header__nav-btn"
            aria-label="Menu"
            title="Menu"
            @click="drawer = !drawer"
          >
            <v-icon icon="mdi-menu" size="22" />
          </button>
        </div>
      </header>
      <slot />
    </v-main>

    <FloatingTimerButton v-if="user" />
    <NewTaskFab v-if="user" />

    <v-bottom-navigation
      v-if="user && mobile"
      grow
      class="app-bottom-nav"
      bg-color="background"
      color="primary"
    >
      <v-btn to="/">
        <v-icon icon="mdi-home-outline" />
        <span>Home</span>
      </v-btn>
      <v-btn to="/progress">
        <v-icon icon="mdi-progress-check" />
        <span>Progress</span>
      </v-btn>
      <v-btn to="/map">
        <v-icon icon="mdi-map-outline" />
        <span>Map</span>
      </v-btn>
    </v-bottom-navigation>
  </v-app>
</template>

<style scoped>
.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  /* Add the notch/safe-area insets so the header clears the status bar when
     installed to the home screen (viewport-fit=cover). env() is 0 in a normal
     browser tab, so this is a no-op there. */
  padding: calc(20px + env(safe-area-inset-top, 0px))
    calc(16px + env(safe-area-inset-right, 0px)) 4px
    calc(16px + env(safe-area-inset-left, 0px));
  max-width: 900px;
  margin: 0 auto;
}

.app-header__link {
  text-decoration: none;
  color: inherit;
}

.app-header__farm {
  font-family: var(--cc-font-slab);
  font-size: 1.75rem;
  font-weight: 700;
  line-height: 1.15;
  color: var(--cc-ink);
  margin: 2px 0 0;
}

.app-header__actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Circular white-bordered icon buttons (hamburger + desktop nav). */
.app-header__nav-btn {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--cc-surface);
  border: 2px solid #ffffff;
  box-shadow: var(--cc-shadow);
  color: var(--cc-ink);
  cursor: pointer;
  padding: 0;
  text-decoration: none;
}

/* Cream bottom nav; active item in the burnt-orange accent (via color=primary).
   Vuetify's layout system doesn't hand this nav its left/width inline styles
   (no app bar registered anymore), so pin it to the full viewport width. */
.app-bottom-nav {
  border-top: 1px solid var(--cc-border);
  left: 0 !important;
  right: 0 !important;
  width: 100% !important;
  /* Grow the bar by the home-indicator inset so the tab row sits above it
     when installed to the home screen. No-op in a normal browser tab. */
  height: calc(56px + env(safe-area-inset-bottom, 0px)) !important;
  padding-bottom: env(safe-area-inset-bottom, 0px);
}

.app-bottom-nav .v-btn {
  font-family: var(--cc-font-sans);
  text-transform: none;
  letter-spacing: normal;
  font-size: 0.75rem;
  background: transparent;
}
</style>
