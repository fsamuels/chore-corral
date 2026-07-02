<script setup lang="ts">
definePageMeta({ layout: 'blank' })

const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { farms, resetFarms } = useFarms()

// A user who does have farms (e.g. added while this page was open, or
// navigated here directly) doesn't belong on the no-access page.
watchEffect(() => {
  if (farms.value && farms.value.length > 0) navigateTo('/')
})

async function signOut() {
  await supabase.auth.signOut()
  resetFarms()
  await navigateTo('/login')
}
</script>

<template>
  <v-container class="fill-height">
    <v-row justify="center" align="center">
      <v-col cols="12" sm="8" md="6">
        <v-card class="text-center pa-4">
          <v-card-text>
            <v-icon icon="mdi-account-off" size="64" color="warning" />
            <h1 class="text-h5 mt-4 mb-2">No farm access</h1>
            <p class="text-body-1 mb-2">
              Your account isn't linked to any farm yet — contact the farm owner
              to be added.
            </p>
            <p v-if="user?.email" class="text-body-2 text-medium-emphasis">
              You're signed in as <strong>{{ user.email }}</strong
              >. Share this address with the farm owner so they can add the
              right account.
            </p>
          </v-card-text>
          <v-card-actions class="justify-center">
            <v-btn color="primary" variant="tonal" @click="signOut">
              Sign out
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>
