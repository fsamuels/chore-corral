<script setup lang="ts">
import type { Database } from '~/types/database.types'
import { getPublicTaskCount } from '~/services/stats'

definePageMeta({ layout: 'blank' })

// SEO: the only page in the app meant to be publicly indexed (see
// public/robots.txt, which disallows everything else). Title/description
// lean on the long-tail phrasing this page targets — property maintenance,
// priority-sorted chores, farms/ranches/homesteads — rather than the bare
// "Chore Corral" title every other (auth-gated, unindexed) page gets from
// app.vue.
useSeoMeta({
  title: 'Chore Corral — Priority-Sorted Chore & Property Maintenance Tracker',
  description:
    'A shared chore and maintenance tracker for farms, ranches, homesteads, and any property with more fix-it tasks than hours in the day — sorted urgent to someday, with photos and map pins.',
  ogTitle:
    'Chore Corral — Priority-Sorted Chore & Property Maintenance Tracker',
  ogDescription:
    'For farms, ranches, homesteads, and any property with a long list of fix-it and upkeep tasks — sorted from urgent to someday, shared with your whole team.',
  ogImage: 'https://chore-corral.vercel.app/pwa-512x512.png',
  ogType: 'website',
  twitterCard: 'summary',
})
useHead({
  link: [{ rel: 'canonical', href: 'https://chore-corral.vercel.app/landing' }],
})

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()

// A signed-in visitor lands here from a shared link, not the login page —
// send them straight into the app instead of showing marketing copy.
watchEffect(() => {
  if (user.value) navigateTo('/')
})

// Purely decorative social proof — a failed fetch just hides the stat
// instead of surfacing an error on a public page.
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

const features = [
  {
    icon: 'mdi-fire',
    title: 'Urgent, soon, or someday',
    body: 'Every chore gets a priority tier, so the long tail of fix-it and maybe-later tasks never buries what actually needs doing today.',
  },
  {
    icon: 'mdi-camera-outline',
    title: 'Snap a photo, drop a pin',
    body: 'Log a chore right where it needs doing, with a picture, so nobody has to guess what "fix the west fence" means.',
  },
  {
    icon: 'mdi-account-group-outline',
    title: 'One shared list',
    body: "Everyone working the property sees the same chores, who's on them, and what's overdue — no more texting to ask if anyone dealt with the trough.",
  },
  {
    icon: 'mdi-timer-outline',
    title: 'Track what it actually takes',
    body: 'Optional timers and time estimates, so you know how long the real work takes — not just how long you guessed.',
  },
]

const honestNotes = [
  'Google sign-in only — no separate password, no other providers yet.',
  "Mobile-web only for now — works great from your phone's browser, but there's no app-store download or offline mode yet.",
  "Small-team tested — it runs daily on a couple of real properties, but hasn't been battle-tested at scale, so you might hit a rough edge.",
  'Actively changing — features and design are still shifting fast based on real use.',
]
</script>

<template>
  <div class="cc-landing">
    <section class="cc-landing__hero">
      <div class="cc-landing__sun" />

      <div class="cc-landing__hero-content">
        <div class="cc-landing__brand">
          <img src="/icon.svg" alt="" class="cc-landing__logo" />
          <p class="cc-landing__wordmark">Chore Corral</p>
        </div>

        <span class="cc-pill cc-landing__badge">Early access</span>

        <h1 class="cc-landing__headline">
          Every chore has a priority. Your list should show it.
        </h1>
        <p class="cc-landing__subhead">
          For farms, ranches, homesteads, and any property with more to fix than
          hours in the day — sorted urgent to someday, with photos and map pins,
          shared with your team.
        </p>

        <v-alert
          v-if="errorMessage"
          type="error"
          variant="tonal"
          class="mt-4 mb-0 text-left cc-landing__alert"
        >
          Sign-in failed: {{ errorMessage }}
        </v-alert>

        <button
          type="button"
          class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg cc-landing__cta"
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
            <span class="cc-landing__google-icon">
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
            Sign in with Google — it's free
          </template>
        </button>
        <p class="cc-landing__helper">
          Takes about 10 seconds. No credit card.
        </p>
      </div>

      <div class="cc-landing__hill" />
    </section>

    <section class="cc-landing__section">
      <h2 class="cc-landing__section-title">What it does</h2>
      <div class="cc-landing__features">
        <div v-for="f in features" :key="f.title" class="cc-landing__feature">
          <v-icon :icon="f.icon" size="28" color="#b5541e" />
          <h3 class="cc-landing__feature-title">{{ f.title }}</h3>
          <p class="cc-landing__feature-body">{{ f.body }}</p>
        </div>
      </div>
    </section>

    <section class="cc-landing__section cc-landing__section--honest">
      <h2 class="cc-landing__section-title">The honest version</h2>
      <p class="cc-landing__section-intro">
        Chore Corral is early — built by one person, running daily on a couple
        of real properties, and still getting sanded down. A few things worth
        knowing before you dive in:
      </p>
      <ul class="cc-landing__honest-list">
        <li v-for="note in honestNotes" :key="note">{{ note }}</li>
      </ul>
    </section>

    <section class="cc-landing__section cc-landing__cta-repeat">
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg cc-landing__cta"
        :disabled="signingIn"
        @click="signInWithGoogle"
      >
        Try Chore Corral — sign in with Google
      </button>
      <div v-if="taskCount !== null" class="cc-landing__stat">
        <span class="cc-landing__stat-number">{{
          taskCount.toLocaleString()
        }}</span>
        <span class="cc-landing__stat-label">chores tracked and counting</span>
      </div>
    </section>

    <footer class="cc-landing__footer">
      Chore Corral — a priority-sorted chore and maintenance tracker for farms,
      ranches, homesteads, and every property with more to fix than hours in the
      day.
    </footer>
  </div>
</template>
