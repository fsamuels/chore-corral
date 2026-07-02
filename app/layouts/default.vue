<script setup lang="ts">
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { resetFarms } = useFarms()

async function signOut() {
  await supabase.auth.signOut()
  resetFarms()
  await navigateTo('/login')
}
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
          icon="mdi-shape-outline"
          aria-label="Categories"
          title="Categories"
          to="/categories"
        />
        <v-btn
          icon="mdi-logout"
          aria-label="Sign out"
          title="Sign out"
          @click="signOut"
        />
      </template>
    </v-app-bar>
    <v-main>
      <slot />
    </v-main>
  </v-app>
</template>
