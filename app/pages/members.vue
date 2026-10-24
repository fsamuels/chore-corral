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
const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()

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

async function loadMembers() {
  const farmId = activeFarmId.value
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
}
watch(activeFarmId, loadMembers, { immediate: true })

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
// The target outlives the open flag so the dialog body keeps its email
// while the close transition plays.
const toRevoke = ref<FarmInvite | null>(null)
const revokeOpen = ref(false)

function askRevoke(invite: FarmInvite) {
  toRevoke.value = invite
  revokeOpen.value = true
}

async function confirmRevoke() {
  if (!toRevoke.value) return
  await revoke(toRevoke.value)
  revokeOpen.value = false
}

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
  <div class="cc-page cc-page--narrow">
    <LoadErrorAlert
      v-if="farmsError"
      title="Couldn't load your farms"
      :message="farmsError"
      :retry="() => fetchFarms()"
    />
    <template v-else-if="activeFarm">
      <PageHeader title="Farm members">
        Everyone with access to <strong>{{ activeFarm.name }}</strong> — all
        members can create, edit, and complete chores.
      </PageHeader>

      <LoadErrorAlert
        v-if="loadError"
        title="Couldn't load members"
        :message="loadError"
        :retry="loadMembers"
      />

      <ListSkeleton v-else-if="loading" />

      <template v-else>
        <div class="cc-card cc-card--list mb-6">
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
                <span
                  v-if="member.user_id === myUserId"
                  class="cc-pill cc-pill--sm cc-pill--muted mr-2"
                >
                  You
                </span>
                <span
                  v-if="member.role === 'owner'"
                  class="cc-pill cc-pill--sm cc-pill--accent"
                >
                  Owner
                </span>
              </template>
            </v-list-item>
          </v-list>
        </div>

        <template v-if="isOwner">
          <h2 class="cc-section-title mb-1">Invite someone</h2>
          <p class="cc-muted mb-3">
            No email is sent — as soon as they sign in with Google using this
            address, they're added to the farm automatically.
          </p>

          <v-alert v-if="inviteError" type="error" variant="tonal" class="mb-3">
            {{ inviteError }}
          </v-alert>

          <v-form class="cc-add-row mb-6" @submit.prevent="addInvite">
            <v-text-field
              v-model="inviteEmail"
              label="Google account email"
              type="email"
              variant="outlined"
              density="comfortable"
              hide-details
            />
            <button
              type="submit"
              class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--sm"
              :disabled="inviting || inviteEmail.trim().length === 0"
            >
              <v-progress-circular
                v-if="inviting"
                indeterminate
                size="18"
                width="2"
              />
              Invite
            </button>
          </v-form>

          <h2 class="cc-section-title mb-3">Pending invites</h2>
          <div v-if="invites.length > 0" class="cc-card cc-card--list">
            <v-list>
              <v-list-item
                v-for="invite in invites"
                :key="invite.id"
                :title="invite.email"
                prepend-icon="mdi-email-outline"
              >
                <template #append>
                  <button
                    type="button"
                    class="cc-icon-btn cc-icon-btn--sm"
                    :disabled="revokingId === invite.id"
                    :aria-label="`Revoke invite for ${invite.email}`"
                    :title="`Revoke invite for ${invite.email}`"
                    @click="askRevoke(invite)"
                  >
                    <v-icon icon="mdi-close" size="18" />
                  </button>
                </template>
              </v-list-item>
            </v-list>
          </div>
          <p v-else class="cc-empty-inline">No pending invites.</p>
        </template>
        <p v-else class="cc-muted">Only farm owners can invite people.</p>
      </template>
    </template>

    <ConfirmDialog
      v-model="revokeOpen"
      title="Revoke invite?"
      confirm-label="Revoke"
      :busy="revokingId !== null"
      @confirm="confirmRevoke"
    >
      The invite for “{{ toRevoke?.email }}” will be revoked.
    </ConfirmDialog>
  </div>
</template>
