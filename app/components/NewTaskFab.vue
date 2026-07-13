<script setup lang="ts">
// Floating "+ New task" pill, fixed bottom-right. Rendered once from the
// layout on every page; hides itself on the new-task page (no point linking
// to where you already are). Collapses to an icon-only circle while
// scrolling down so the list content underneath stays readable, and expands
// back on scroll-up or at the top — the extended-FAB pattern. Lifts above
// the mobile bottom nav (56px) so the two never overlap.
// `lifted` shifts the pill up by the running-timer dock bar's height so the
// two never overlap while a timer is running.
defineProps<{ lifted?: boolean }>()

const route = useRoute()
const { mobile } = useDisplay()

const isOnNewTaskPage = computed(() => route.path === '/tasks/new')

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
  <NuxtLink
    v-if="!isOnNewTaskPage"
    to="/tasks/new"
    class="new-task-fab"
    :class="{
      'new-task-fab--above-bottom-nav': mobile,
      'new-task-fab--collapsed': collapsed,
      'new-task-fab--lifted': lifted,
    }"
    aria-label="New task"
    title="New task"
  >
    <v-icon icon="mdi-plus" size="32" />
    <span class="new-task-fab__label">New task</span>
  </NuxtLink>
</template>

<style scoped>
.new-task-fab {
  position: fixed;
  right: 24px;
  /* Clear the home-indicator inset when installed to the home screen. */
  bottom: calc(24px + env(safe-area-inset-bottom, 0px));
  z-index: 10;
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
  box-shadow: 0 4px 12px rgba(43, 33, 24, 0.25);
  transition: transform 0.25s ease;
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
