/**
 * Short, human display labels for farm members, replacing the raw email
 * addresses previously shown in completed-by pills, activity attribution,
 * and the member picker.
 *
 * The label ladder, applied against the full member set so labels are only
 * as long as they need to be to stay unambiguous within one farm:
 *
 *   1. First name alone ("Steve") when no other member shares it.
 *   2. First name + last initial ("Steve A.") when first names collide.
 *   3. Full display name when even first + initial collides (two Steve
 *      Adams… or a bare "Steve" colliding with another bare "Steve").
 *   4. Email (or, failing that, the user id) when the member has no display
 *      name at all, or when full names are outright identical.
 *
 * Comparisons are case-insensitive so "steve" and "Steve" collide.
 */

export interface MemberNameInfo {
  user_id: string
  display_name: string | null
  email: string | null
}

interface NameParts {
  member: MemberNameInfo
  full: string
  first: string
  // "First L." when there's a distinct last word to take an initial from;
  // otherwise the full (single-word) name, which serves the same "next rung
  // up from bare first name" role in the ladder.
  withInitial: string
}

function fallbackLabel(member: MemberNameInfo): string {
  return member.email ?? member.user_id
}

function splitName(member: MemberNameInfo): NameParts | null {
  const full = member.display_name?.trim() ?? ''
  if (full === '') return null
  const words = full.split(/\s+/)
  const first = words[0]!
  const last = words.length > 1 ? words[words.length - 1]! : null
  return {
    member,
    full,
    first,
    withInitial: last ? `${first} ${last[0]!.toUpperCase()}.` : full,
  }
}

/**
 * Resolve every member to its shortest unambiguous label (see the ladder
 * above), keyed by `user_id`. Pass the whole farm's member list — labels are
 * disambiguated against each other, so a subset would under-disambiguate.
 */
export function memberShortLabels(
  members: MemberNameInfo[],
): Map<string, string> {
  const labels = new Map<string, string>()
  const named: NameParts[] = []

  for (const member of members) {
    const parts = splitName(member)
    if (parts) named.push(parts)
    else labels.set(member.user_id, fallbackLabel(member))
  }

  const byFirst = countBy(named, (p) => p.first.toLowerCase())
  const byWithInitial = countBy(named, (p) => p.withInitial.toLowerCase())
  const byFull = countBy(named, (p) => p.full.toLowerCase())

  for (const parts of named) {
    let label: string
    if (byFirst.get(parts.first.toLowerCase()) === 1) {
      label = parts.first
    } else if (byWithInitial.get(parts.withInitial.toLowerCase()) === 1) {
      label = parts.withInitial
    } else if (byFull.get(parts.full.toLowerCase()) === 1) {
      label = parts.full
    } else {
      label = fallbackLabel(parts.member)
    }
    labels.set(parts.member.user_id, label)
  }

  return labels
}

function countBy<T>(items: T[], key: (item: T) => string): Map<string, number> {
  const counts = new Map<string, number>()
  for (const item of items) {
    const k = key(item)
    counts.set(k, (counts.get(k) ?? 0) + 1)
  }
  return counts
}
