<script setup lang="ts">
// Floating "+ New task" pill, fixed bottom-right. Shared by the home and
// tasks pages; lifts above the mobile bottom nav (56px) so the two never
// overlap.
const { mobile } = useDisplay()
</script>

<template>
  <NuxtLink
    to="/tasks/new"
    class="new-task-fab"
    :class="{ 'new-task-fab--above-bottom-nav': mobile }"
    aria-label="New task"
    title="New task"
  >
    <v-icon icon="mdi-plus" size="20" />
    <span>New task</span>
  </NuxtLink>
</template>

<style scoped>
.new-task-fab {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 10;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: var(--cc-accent);
  color: var(--cc-accent-contrast);
  border-radius: 999px;
  padding: 14px 22px;
  font-weight: 600;
  font-size: 0.9375rem;
  text-decoration: none;
  box-shadow: 0 4px 12px rgba(43, 33, 24, 0.25);
}

.new-task-fab--above-bottom-nav {
  bottom: 80px;
}
</style>
