<script setup lang="ts">
// Floating "+" new-task button, fixed bottom-right. Rendered once from the
// layout on every page; hides itself on the new-task page (no point linking
// to where you already are). Icon-only so it covers less of the content
// scrolling underneath it; lifts above the mobile bottom nav (56px) so the
// two never overlap.
const route = useRoute()
const { mobile } = useDisplay()

const isOnNewTaskPage = computed(() => route.path === '/tasks/new')
</script>

<template>
  <NuxtLink
    v-if="!isOnNewTaskPage"
    to="/tasks/new"
    class="new-task-fab"
    :class="{ 'new-task-fab--above-bottom-nav': mobile }"
    aria-label="New task"
    title="New task"
  >
    <v-icon icon="mdi-plus" size="32" />
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
  width: 64px;
  height: 64px;
  background: var(--cc-accent);
  color: var(--cc-accent-contrast);
  border-radius: 50%;
  text-decoration: none;
  box-shadow: 0 4px 12px rgba(43, 33, 24, 0.25);
}

.new-task-fab--above-bottom-nav {
  bottom: calc(80px + env(safe-area-inset-bottom, 0px));
}
</style>
