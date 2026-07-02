<script setup lang="ts">
definePageMeta({ layout: 'blank' })

const supabase = useSupabaseClient()
const user = useSupabaseUser()

// The module's auth middleware only guards protected pages; an already
// signed-in user landing here should go home instead of seeing the button.
watchEffect(() => {
  if (user.value) navigateTo('/')
})

const signingIn = ref(false)
const errorMessage = ref<string | null>(null)

async function signInWithGoogle() {
  signingIn.value = true
  errorMessage.value = null
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: `${window.location.origin}/confirm` },
  })
  // On success the browser navigates away to Google; only errors return here.
  if (error) {
    errorMessage.value = error.message
    signingIn.value = false
  }
}
</script>

<template>
  <v-container class="fill-height">
    <v-row justify="center" align="center">
      <v-col cols="12" sm="8" md="5" lg="4">
        <v-card class="text-center pa-4">
          <v-card-title class="text-h4">Chore Corral</v-card-title>
          <v-card-subtitle>Farm task tracking</v-card-subtitle>
          <v-card-text>
            <v-alert
              v-if="errorMessage"
              type="error"
              variant="tonal"
              class="mb-4 text-left"
            >
              Sign-in failed: {{ errorMessage }}
            </v-alert>
            <v-btn
              color="primary"
              size="large"
              prepend-icon="mdi-google"
              :loading="signingIn"
              @click="signInWithGoogle"
            >
              Sign in with Google
            </v-btn>
            <p class="text-body-2 text-medium-emphasis mt-4 mb-0">
              Access is invite-only — sign in with the Google account your farm
              owner added.
            </p>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>
