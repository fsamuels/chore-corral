<script setup lang="ts">
// Floating "+ New chore" pill, fixed bottom-right, with a smaller "Start
// chore" circle beside it that opens the quick-start dialog (emitted as
// `quick-start`; the layout owns the dialog). Rendered once from the
// layout on every page; hides itself on the new-task page (no point linking
// to where you already are) and on the map page (the pins already cover most
// of the screen, and adding a chore isn't this page's job). Collapses to an
// icon-only circle while
// scrolling down so the list content underneath stays readable, and expands
// back on scroll-up or at the top — the extended-FAB pattern. Lifts above
// the mobile bottom nav (56px) so the two never overlap.
// `lifted` shifts the pill up by the running-timer dock bar's height so the
// two never overlap while a timer is running.
defineProps<{ lifted?: boolean }>()
defineEmits<{ 'quick-start': [] }>()

const route = useRoute()
const { mobile } = useDisplay()

const HIDDEN_ROUTES = new Set(['/tasks/new', '/map'])
const isHidden = computed(() => HIDDEN_ROUTES.has(route.path))

const collapsed = ref(false)

// Ignore sub-threshold scroll deltas so momentum/bounce jitter doesn't
// flicker the label; near the top the label always shows.
const NEAR_TOP_PX = 8
const MIN_DELTA_PX = 4
let lastScrollY = 0

function onScroll() {
  const y = window.scrollY
  if (y <= NEAR_TOP_PX) {
    collapsed.value = false
  } else if (y > lastScrollY + MIN_DELTA_PX) {
    collapsed.value = true
  } else if (y < lastScrollY - MIN_DELTA_PX) {
    collapsed.value = false
  }
  lastScrollY = y
}

onMounted(() => {
  lastScrollY = window.scrollY
  window.addEventListener('scroll', onScroll, { passive: true })
})
onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
})

// The layout keeps this component mounted across navigations, so start each
// page expanded rather than carrying over the previous page's scroll state.
watch(
  () => route.path,
  () => {
    collapsed.value = false
    lastScrollY = window.scrollY
  },
)
</script>

<template>
  <div
    v-if="!isHidden"
    class="new-task-fab"
    :class="{
      'new-task-fab--above-bottom-nav': mobile,
      'new-task-fab--collapsed': collapsed,
      'new-task-fab--lifted': lifted,
    }"
  >
    <button
      type="button"
      class="new-task-fab__quick"
      aria-label="Start chore now"
      title="Start chore now"
      @click="$emit('quick-start')"
    >
      <v-icon icon="mdi-lightning-bolt" size="28" />
    </button>
    <NuxtLink
      to="/tasks/new"
      class="new-task-fab__main"
      aria-label="New chore"
      title="New chore"
    >
      <v-icon icon="mdi-plus" size="32" />
      <span class="new-task-fab__label">New chore</span>
    </NuxtLink>
  </div>
</template>

<style scoped>
.new-task-fab {
  position: fixed;
  right: calc(24px + env(safe-area-inset-right, 0px));
  /* Clear the home-indicator inset when installed to the home screen. */
  bottom: calc(24px + env(safe-area-inset-bottom, 0px));
  z-index: 10;
  display: flex;
  align-items: center;
  gap: 12px;
  transition: transform 0.25s ease;
}

/* Secondary to "New chore": smaller, and outlined in the accent rather than
   filled, so the two never read as the same action. */
.new-task-fab__quick {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 999px;
  background: var(--cc-surface);
  color: var(--cc-accent);
  border: 2px solid var(--cc-accent);
  cursor: pointer;
  box-shadow: 0 4px 12px color-mix(in srgb, var(--cc-ink) 25%, transparent);
}

.new-task-fab__main {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 64px;
  /* 16px padding + 32px icon + 16px padding = a 64px circle when the label
     is collapsed away; the pill just grows rightward from that. */
  padding: 0 16px;
  background: var(--cc-accent);
  color: var(--cc-accent-contrast);
  border-radius: 999px;
  font-weight: 600;
  font-size: 0.9375rem;
  text-decoration: none;
  box-shadow: 0 4px 12px color-mix(in srgb, var(--cc-ink) 25%, transparent);
}

.new-task-fab--above-bottom-nav {
  bottom: calc(80px + env(safe-area-inset-bottom, 0px));
}

/* Lift via transform rather than a second bottom value so it composes with
   the above-bottom-nav offset, and animates in step with the dock bar's
   slide-up. */
.new-task-fab--lifted {
  transform: translateY(calc(-1 * var(--cc-timer-bar-h)));
}

/* Collapse by animating the label's width/margin to zero (width: auto can't
   transition), leaving the icon centered in the 64px circle. */
.new-task-fab__label {
  max-width: 120px;
  margin-left: 6px;
  margin-right: 4px;
  opacity: 1;
  overflow: hidden;
  white-space: nowrap;
  transition:
    max-width 0.2s ease,
    margin 0.2s ease,
    opacity 0.15s ease;
}

.new-task-fab--collapsed .new-task-fab__label {
  max-width: 0;
  margin-left: 0;
  margin-right: 0;
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .new-task-fab,
  .new-task-fab__label {
    transition: none;
  }
}
</style>
