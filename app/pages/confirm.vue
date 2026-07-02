<script setup lang="ts">
definePageMeta({ layout: 'blank' })

const route = useRoute()
const user = useSupabaseUser()

// OAuth providers report failures (e.g. the user cancelled the consent
// screen) as query params on the callback URL rather than a session.
const oauthError = computed(() => {
  const description = route.query.error_description ?? route.query.error
  return typeof description === 'string' ? description : null
})

watchEffect(() => {
  if (user.value) navigateTo('/', { replace: true })
})

// If neither a session nor an error materializes, don't spin forever.
const timedOut = ref(false)
onMounted(() => {
  setTimeout(() => {
    timedOut.value = true
  }, 10_000)
})
</script>

<template>
  <v-container class="fill-height">
    <v-row justify="center" align="center">
      <v-col cols="12" sm="8" md="5" lg="4" class="text-center">
        <template v-if="oauthError || timedOut">
          <v-alert type="error" variant="tonal" class="mb-4 text-left">
            {{ oauthError ?? 'Sign-in is taking too long.' }}
          </v-alert>
          <v-btn color="primary" to="/login">Back to sign-in</v-btn>
        </template>
        <template v-else>
          <v-progress-circular indeterminate color="primary" class="mb-4" />
          <p class="text-body-1">Signing you in…</p>
        </template>
      </v-col>
    </v-row>
  </v-container>
</template>
