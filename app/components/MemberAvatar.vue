<script setup lang="ts">
// A member's profile picture (Google account photo via
// `farm_member_profiles.avatar_url`, or the signed-in user's own
// `user_metadata`), falling back to the generic account glyph when the
// member has no photo or the image fails to load (Google avatar URLs can
// expire or be blocked). The fallback keeps the same footprint so lists
// mixing photo/no-photo members stay aligned.
const props = defineProps<{
  src: string | null
  size?: number
}>()

const failed = ref(false)
watch(
  () => props.src,
  () => {
    failed.value = false
  },
)

const showImage = computed(() => props.src !== null && !failed.value)
</script>

<template>
  <v-avatar :size="size ?? 32" class="member-avatar">
    <v-img v-if="showImage" :src="src!" alt="" @error="failed = true" />
    <v-icon v-else icon="mdi-account-circle-outline" :size="size ?? 32" />
  </v-avatar>
</template>

<style scoped>
/* surface-variant isn't in the Vuetify theme; use the app tokens. */
.member-avatar {
  background: var(--cc-track);
  color: var(--cc-ink-muted);
}
</style>
