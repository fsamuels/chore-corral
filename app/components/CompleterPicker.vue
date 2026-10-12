<script setup lang="ts">
// The "who completed this" fields: a farm-member multi-select plus a
// free-text combobox for people who aren't app users. Shared by the chore
// page's Completed-by menu and its mark-done dialog; the caller owns the
// drafts (via v-model:members / v-model:names) and turns them into a
// completer set on save.
export interface CompleterMemberItem {
  title: string
  value: string
  avatarUrl: string | null
}

defineProps<{
  memberItems: CompleterMemberItem[]
  disabled?: boolean
}>()

const members = defineModel<string[]>('members', { default: () => [] })
const names = defineModel<string[]>('names', { default: () => [] })
</script>

<template>
  <div>
    <v-select
      v-model="members"
      :items="memberItems"
      item-title="title"
      item-value="value"
      label="Farm members"
      multiple
      chips
      closable-chips
      density="comfortable"
      variant="outlined"
      hide-details
      :disabled="disabled"
    >
      <template #item="{ props: itemProps, item }">
        <v-list-item v-bind="itemProps">
          <template #prepend>
            <MemberAvatar :src="item.avatarUrl" :size="28" class="mr-3" />
          </template>
        </v-list-item>
      </template>
      <template #chip="{ props: chipProps, item }">
        <v-chip v-bind="chipProps">
          <template #prepend>
            <MemberAvatar :src="item.avatarUrl" :size="20" class="mr-1" />
          </template>
          {{ item.title }}
        </v-chip>
      </template>
    </v-select>
    <div class="text-caption text-medium-emphasis my-2">
      and/or others (type a name, press enter)
    </div>
    <v-combobox
      v-model="names"
      label="Other names"
      multiple
      chips
      closable-chips
      density="comfortable"
      variant="outlined"
      hide-details
      :disabled="disabled"
    />
  </div>
</template>
