import type { TaskCompleter } from '../services/completers'
import { memberShortLabels, type MemberNameInfo } from './member-display'

// Pure helpers behind the "Completed by" pickers (the chore page's
// Completed-by menu and the mark-done dialog, `CompleteChoreDialog.vue`).
// The pickers edit two flat drafts (member ids, free-text names); these
// convert between those drafts and the stored completer set.

/**
 * Picker drafts → a completer set: members as-is, names trimmed, blanks
 * dropped and de-duplicated.
 */
export function completersFromDrafts(
  memberIds: readonly string[],
  rawNames: readonly string[],
): TaskCompleter[] {
  const names = [
    ...new Set(rawNames.map((name) => name.trim()).filter(Boolean)),
  ]
  return [
    ...memberIds.map((userId) => ({ user_id: userId, completer_name: null })),
    ...names.map((name) => ({ user_id: null, completer_name: name })),
  ]
}

/** A completer set → the two picker drafts (the inverse of the above). */
export function draftsFromCompleters(completers: readonly TaskCompleter[]): {
  members: string[]
  names: string[]
} {
  return {
    members: completers
      .filter((completer) => completer.user_id !== null)
      .map((completer) => completer.user_id!),
    names: completers
      .filter((completer) => completer.completer_name !== null)
      .map((completer) => completer.completer_name!),
  }
}

/**
 * The mark-done dialog's starting drafts: the task's existing completers, or,
 * when nobody's credited yet, the signed-in member — the same default
 * `changeTaskStatus` would auto-credit. Confirming sends this set explicitly.
 */
export function prefillCompleterDrafts(
  existing: readonly TaskCompleter[],
  actorUserId: string | undefined,
): { members: string[]; names: string[] } {
  if (existing.length > 0) return draftsFromCompleters(existing)
  return { members: actorUserId ? [actorUserId] : [], names: [] }
}

/** Farm members → the picker's items, with disambiguated short labels. */
export function completerMemberItems(
  members: readonly (MemberNameInfo & { avatar_url: string | null })[],
): { title: string; value: string; avatarUrl: string | null }[] {
  const labels = memberShortLabels([...members])
  return members.map((member) => ({
    title: labels.get(member.user_id) ?? member.user_id,
    value: member.user_id,
    avatarUrl: member.avatar_url,
  }))
}
