<script setup lang="ts">
import type { Database } from '~/types/database.types'
import {
  listFarmMemberProfiles,
  type FarmMemberProfile,
} from '~/services/members'
import {
  createInvite,
  listPendingInvites,
  revokeInvite,
  type FarmInvite,
} from '~/services/invites'

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { fetchFarms, activeFarm, activeFarmId } = useFarms()

await fetchFarms()

const members = ref<FarmMemberProfile[]>([])
const invites = ref<FarmInvite[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)

const myUserId = computed(() => getActorUserId(user.value))
const isOwner = computed(() =>
  members.value.some(
    (member) => member.user_id === myUserId.value && member.role === 'owner',
  ),
)

watch(
  activeFarmId,
  async (farmId) => {
    if (!farmId) return
    loading.value = true
    loadError.value = null
    try {
      members.value = await listFarmMemberProfiles(supabase, farmId)
      // Invites are owner-only (RLS would return nothing anyway — don't
      // bother asking unless the members list says we're an owner).
      invites.value = isOwner.value
        ? await listPendingInvites(supabase, farmId)
        : []
    } catch (error) {
      loadError.value =
        error instanceof Error ? error.message : 'Something went wrong.'
    } finally {
      loading.value = false
    }
  },
  { immediate: true },
)

const inviteEmail = ref('')
const inviting = ref(false)
const inviteError = ref<string | null>(null)

async function addInvite() {
  if (inviting.value || !activeFarmId.value || !myUserId.value) return
  inviting.value = true
  inviteError.value = null
  try {
    const invite = await createInvite(
      supabase,
      activeFarmId.value,
      inviteEmail.value,
      myUserId.value,
    )
    invites.value = [...invites.value, invite]
    inviteEmail.value = ''
  } catch (error) {
    inviteError.value =
      error instanceof Error ? error.message : 'Something went wrong.'
  } finally {
    inviting.value = false
  }
}

const revokingId = ref<string | null>(null)

async function revoke(invite: FarmInvite) {
  if (revokingId.value) return
  revokingId.value = invite.id
  inviteError.value = null
  try {
    await revokeInvite(supabase, invite.id)
    invites.value = invites.value.filter((i) => i.id !== invite.id)
  } catch (error) {
    inviteError.value =
      error instanceof Error ? error.message : 'Something went wrong.'
  } finally {
    revokingId.value = null
  }
}
</script>

<template>
  <v-container max-width="600">
    <h1 class="text-h4 mb-1">Farm members</h1>
    <p class="text-body-2 text-medium-emphasis mb-4">
      Everyone with access to
      <strong>{{ activeFarm?.name ?? 'this farm' }}</strong> — all members can
      create, edit, and complete chores.
    </p>

    <v-alert v-if="loadError" type="error" variant="tonal" class="mb-4">
      {{ loadError }}
    </v-alert>

    <div v-if="loading" class="text-center py-8">
      <v-progress-circular indeterminate color="primary" />
    </div>

    <template v-else>
      <div class="cc-card pa-0 mb-6" style="overflow: hidden">
        <v-list>
          <v-list-item
            v-for="member in members"
            :key="member.user_id"
            :title="member.display_name ?? member.email ?? member.user_id"
            :subtitle="
              member.display_name ? (member.email ?? undefined) : undefined
            "
          >
            <template #prepend>
              <MemberAvatar :src="member.avatar_url" class="mr-3" />
            </template>
            <template #append>
              <v-chip
                v-if="member.user_id === myUserId"
                size="small"
                variant="tonal"
                class="mr-2"
              >
                you
              </v-chip>
              <v-chip
                v-if="member.role === 'owner'"
                size="small"
                color="primary"
                variant="tonal"
              >
                owner
              </v-chip>
            </template>
          </v-list-item>
        </v-list>
      </div>

      <template v-if="isOwner">
        <h2 class="text-h6 mb-1">Invite someone</h2>
        <p class="text-body-2 text-medium-emphasis mb-3">
          No email is sent — as soon as they sign in with Google using this
          address, they're added to the farm automatically.
        </p>

        <v-alert v-if="inviteError" type="error" variant="tonal" class="mb-3">
          {{ inviteError }}
        </v-alert>

        <v-form class="d-flex ga-2 mb-6" @submit.prevent="addInvite">
          <v-text-field
            v-model="inviteEmail"
            label="Google account email"
            type="email"
            density="comfortable"
            hide-details
          />
          <v-btn
            type="submit"
            color="primary"
            height="48"
            :loading="inviting"
            :disabled="inviteEmail.trim().length === 0"
          >
            Invite
          </v-btn>
        </v-form>

        <template v-if="invites.length > 0">
          <h2 class="text-h6 mb-2">Pending invites</h2>
          <div class="cc-card pa-0" style="overflow: hidden">
            <v-list>
              <v-list-item
                v-for="invite in invites"
                :key="invite.id"
                :title="invite.email"
                prepend-icon="mdi-email-outline"
              >
                <template #append>
                  <v-btn
                    icon="mdi-close"
                    size="small"
                    variant="text"
                    :loading="revokingId === invite.id"
                    :aria-label="`Revoke invite for ${invite.email}`"
                    @click="revoke(invite)"
                  />
                </template>
              </v-list-item>
            </v-list>
          </div>
        </template>
      </template>
    </template>
  </v-container>
</template>
