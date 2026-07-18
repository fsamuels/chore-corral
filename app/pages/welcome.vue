<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { createFarm, FARM_NAME_MAX_LENGTH } from '~/services/farms'

definePageMeta({ layout: 'blank' })

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { farms, refreshFarms, resetFarms, setActiveFarm } = useFarms()

// A user who does have farms (e.g. their invite was swept while this page
// was open, or they navigated here directly) doesn't belong on the welcome
// page.
watchEffect(() => {
  if (farms.value && farms.value.length > 0) navigateTo('/')
})

const farmName = ref('')
const farmAddress = ref('')
const creating = ref(false)
const errorMessage = ref<string | null>(null)

async function createFirstFarm() {
  if (creating.value) return
  creating.value = true
  errorMessage.value = null
  try {
    const farmId = await createFarm(supabase, farmName.value, farmAddress.value)
    setActiveFarm(farmId)
    await refreshFarms()
    await navigateTo('/')
  } catch (error) {
    errorMessage.value =
      error instanceof Error ? error.message : 'Something went wrong.'
  } finally {
    creating.value = false
  }
}

async function signOut() {
  await supabase.auth.signOut()
  resetFarms()
  await navigateTo('/login')
}
</script>

<template>
  <v-container class="fill-height">
    <v-row justify="center" align="center">
      <v-col cols="12" sm="8" md="6" lg="5">
        <div class="cc-card">
          <p class="cc-eyebrow mb-1 text-center">Chore Corral</p>
          <h1 class="cc-slab mb-4 text-center" style="font-size: 1.75rem">
            Welcome!
          </h1>
          <p class="text-body-1 mb-2">
            Your account isn't part of a farm yet. Set up your own below —
            you'll be its owner and can invite others from the members page.
          </p>
          <p v-if="user?.email" class="text-body-2 text-medium-emphasis mb-4">
            Waiting on an invite instead? You're signed in as
            <strong>{{ user.email }}</strong
            >. As soon as a farm owner invites that address, signing in brings
            you straight to their farm — share it with them if they don't have
            it.
          </p>

          <v-alert
            v-if="errorMessage"
            type="error"
            variant="tonal"
            class="mb-4"
          >
            {{ errorMessage }}
          </v-alert>

          <v-form @submit.prevent="createFirstFarm">
            <v-text-field
              v-model="farmName"
              label="Farm name"
              placeholder="e.g. Reign Cloud Ranch"
              :maxlength="FARM_NAME_MAX_LENGTH"
              autofocus
            />
            <v-text-field
              v-model="farmAddress"
              label="Address (optional)"
              class="mt-2"
            />
            <v-btn
              type="submit"
              color="primary"
              size="large"
              block
              class="mt-4"
              :loading="creating"
              :disabled="farmName.trim().length === 0"
            >
              Create my farm
            </v-btn>
          </v-form>

          <div class="text-center mt-4">
            <v-btn variant="text" size="small" @click="signOut">
              Sign out
            </v-btn>
          </div>
        </div>
      </v-col>
    </v-row>
  </v-container>
</template>
