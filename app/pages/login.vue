<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { getPublicTaskCount } from '~/services/stats'

definePageMeta({ layout: 'blank' })

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()

// The module's auth middleware only guards protected pages; an already
// signed-in user landing here should go home instead of seeing the button.
watchEffect(() => {
  if (user.value) navigateTo('/')
})

// Purely decorative social proof — a failed fetch just hides the stat
// instead of surfacing an error on the sign-in page.
const taskCount = ref<number | null>(null)
try {
  taskCount.value = await getPublicTaskCount(supabase)
} catch {
  taskCount.value = null
}

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

// Email/password sign-in for manually-created accounts (e.g. via the
// Supabase dashboard) — no self-serve signup form here, since Google OAuth
// already covers that per SPEC. Kept behind a toggle so the primary Google
// button stays the default path.
const showEmailForm = ref(false)
const email = ref('')
const password = ref('')

async function signInWithPassword() {
  signingIn.value = true
  errorMessage.value = null
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value.trim(),
    password: password.value,
  })
  signingIn.value = false
  if (error) {
    errorMessage.value = error.message
    return
  }
  navigateTo('/')
}
</script>

<template>
  <div class="cc-login">
    <div class="cc-login__sun" />
    <div class="cc-login__hill" />
    <div class="cc-login__brand">
      <img src="/icon.svg" alt="" class="cc-login__logo" />
      <p class="cc-login__wordmark">Chore Corral</p>
    </div>

    <div class="cc-login__card">
      <h1 class="cc-login__headline">Every chore,<br />one place.</h1>
      <p class="cc-login__subhead">
        One shared list, synced for the whole team.
      </p>

      <v-alert
        v-if="errorMessage"
        type="error"
        variant="tonal"
        class="mt-4 mb-0 text-left"
        style="width: 100%"
      >
        Sign-in failed: {{ errorMessage }}
      </v-alert>

      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg cc-pill-btn--full cc-login__google-btn"
        :disabled="signingIn"
        @click="signInWithGoogle"
      >
        <v-progress-circular
          v-if="signingIn"
          indeterminate
          size="18"
          width="2"
          color="white"
        />
        <template v-else>
          <span class="cc-login__google-icon">
            <svg width="12" height="12" viewBox="0 0 18 18">
              <path
                fill="#4285F4"
                d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.9c1.7-1.57 2.7-3.87 2.7-6.62z"
              />
              <path
                fill="#34A853"
                d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.9-2.26c-.8.54-1.84.86-3.06.86-2.35 0-4.34-1.59-5.05-3.72H.98v2.33A9 9 0 0 0 9 18z"
              />
              <path
                fill="#FBBC05"
                d="M3.95 10.7A5.4 5.4 0 0 1 3.67 9c0-.59.1-1.17.28-1.7V4.97H.98A9 9 0 0 0 0 9c0 1.45.35 2.83.98 4.03z"
              />
              <path
                fill="#EA4335"
                d="M9 3.58c1.32 0 2.51.46 3.44 1.35l2.58-2.58C13.46.89 11.43 0 9 0A9 9 0 0 0 .98 4.97L3.95 7.3C4.66 5.17 6.65 3.58 9 3.58z"
              />
            </svg>
          </span>
          Sign in with Google
        </template>
      </button>

      <button
        v-if="!showEmailForm"
        type="button"
        class="cc-login__email-toggle"
        @click="showEmailForm = true"
      >
        Sign in with email instead
      </button>

      <v-form
        v-else
        class="cc-login__email-form"
        @submit.prevent="signInWithPassword"
      >
        <v-text-field
          v-model="email"
          label="Email"
          type="email"
          autocomplete="email"
          :disabled="signingIn"
          density="comfortable"
          variant="outlined"
          hide-details
          class="mb-3"
          autofocus
        />
        <v-text-field
          v-model="password"
          label="Password"
          type="password"
          autocomplete="current-password"
          :disabled="signingIn"
          density="comfortable"
          variant="outlined"
          hide-details
          class="mb-3"
        />
        <button
          type="submit"
          class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg cc-pill-btn--full"
          :disabled="signingIn || !email || !password"
        >
          <v-progress-circular
            v-if="signingIn"
            indeterminate
            size="18"
            width="2"
            color="white"
          />
          <template v-else>Sign in</template>
        </button>
      </v-form>

      <p class="cc-login__helper">
        New here? Sign in and create your first farm.
      </p>

      <div v-if="taskCount !== null" class="cc-login__stat">
        <span class="cc-login__stat-number">{{
          taskCount.toLocaleString()
        }}</span>
        <span class="cc-login__stat-label">chores tracked and counting</span>
      </div>
    </div>
  </div>
</template>
