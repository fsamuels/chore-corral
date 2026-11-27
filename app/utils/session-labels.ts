import type { TimeEntrySummary } from '../services/time-entries'

/** Most labels one session can carry (the DB check backstops this). */
export const MAX_SESSION_LABELS = 8
/** Longest a single label can be, after trimming. */
export const MAX_SESSION_LABEL_LENGTH = 40

const labelKey = (label: string) => label.toLocaleLowerCase()

/**
 * Clean up labels before saving: trim and collapse inner whitespace, cut each
 * to `MAX_SESSION_LABEL_LENGTH`, drop blanks, drop case-insensitive duplicates
 * (the first spelling wins), and keep at most `MAX_SESSION_LABELS`.
 */
export function normalizeLabels(labels: readonly string[]): string[] {
  const seen = new Set<string>()
  const result: string[] = []
  for (const raw of labels) {
    const label = raw
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, MAX_SESSION_LABEL_LENGTH)
      .trim()
    if (!label) continue
    const key = labelKey(label)
    if (seen.has(key)) continue
    seen.add(key)
    result.push(label)
    if (result.length === MAX_SESSION_LABELS) break
  }
  return result
}

/**
 * Normalize labels, then reuse the spelling of a known label that matches
 * case-insensitively, so typing "aaron helped" on a chore that already has
 * "Aaron helped" doesn't start a second label that splits the breakdown.
 */
export function canonicalizeLabels(
  labels: readonly string[],
  known: readonly string[],
): string[] {
  const byKey = new Map<string, string>()
  for (const label of known) {
    const key = labelKey(label)
    if (!byKey.has(key)) byKey.set(key, label)
  }
  return normalizeLabels(
    normalizeLabels(labels).map((label) => byKey.get(labelKey(label)) ?? label),
  )
}

/**
 * Labels used on a chore's sessions, for autocomplete: one per
 * case-insensitive spelling (the most recent session's spelling), most
 * recently used first. Ties keep the order the labels were entered in.
 */
export function labelSuggestions(
  entries: readonly Pick<TimeEntrySummary, 'started_at' | 'labels'>[],
): string[] {
  const latest = new Map<string, { label: string; at: number; order: number }>()
  let order = 0
  for (const entry of entries) {
    const at = Date.parse(entry.started_at)
    const time = Number.isNaN(at) ? Number.NEGATIVE_INFINITY : at
    for (const label of entry.labels ?? []) {
      const key = labelKey(label)
      const prev = latest.get(key)
      if (!prev || time > prev.at) {
        latest.set(key, { label, at: time, order: prev?.order ?? order++ })
      }
    }
  }
  return [...latest.values()]
    .sort((a, b) => b.at - a.at || a.order - b.order)
    .map((item) => item.label)
}

export interface LabelComboStats {
  /**
   * The combination's labels, most common across the chore's sessions
   * first, so a row with one extra label ("Aaron helped") reads as the row
   * above it plus that label.
   */
  labels: string[]
  /** Finished sessions with exactly this set of labels. */
  count: number
  averageMs: number
  totalMs: number
}

/**
 * Average session length per label combination, over a chore's finished,
 * labelled sessions. Sessions match when their label sets are equal
 * case-insensitively (order doesn't matter), so "morning feeding" +
 * "mucking" and "morning feeding" + "mucking" + "Aaron helped" are separate
 * rows that can be compared. The running session, unlabelled sessions and
 * ones with unparseable or non-positive spans are left out. Most-used
 * combinations first, then shortest average, then by label text.
 */
export function labelBreakdown(
  entries: readonly Pick<
    TimeEntrySummary,
    'started_at' | 'ended_at' | 'labels'
  >[],
): LabelComboStats[] {
  const sessions: { labels: string[]; ms: number }[] = []
  const frequency = new Map<string, number>()
  for (const entry of entries) {
    if (entry.ended_at === null) continue
    const labels = normalizeLabels(entry.labels ?? [])
    if (labels.length === 0) continue
    const ms = Date.parse(entry.ended_at) - Date.parse(entry.started_at)
    if (!(ms > 0)) continue
    sessions.push({ labels, ms })
    for (const label of labels) {
      const key = labelKey(label)
      frequency.set(key, (frequency.get(key) ?? 0) + 1)
    }
  }

  const groups = new Map<
    string,
    { labels: string[]; count: number; totalMs: number }
  >()
  for (const { labels, ms } of sessions) {
    const sorted = [...labels].sort(
      (a, b) =>
        (frequency.get(labelKey(b)) ?? 0) - (frequency.get(labelKey(a)) ?? 0) ||
        labelKey(a).localeCompare(labelKey(b)),
    )
    const key = [...sorted.map(labelKey)].sort().join('\u0000')
    const group = groups.get(key)
    if (group) {
      group.count++
      group.totalMs += ms
    } else {
      groups.set(key, { labels: sorted, count: 1, totalMs: ms })
    }
  }
  return [...groups.values()]
    .map((group) => ({ ...group, averageMs: group.totalMs / group.count }))
    .sort(
      (a, b) =>
        b.count - a.count ||
        a.averageMs - b.averageMs ||
        a.labels.join(' ').localeCompare(b.labels.join(' ')),
    )
}

/** Two label lists hold the same labels in the same order. */
export function sameLabels(
  a: readonly string[] | undefined,
  b: readonly string[] | undefined,
): boolean {
  const left = a ?? []
  const right = b ?? []
  return (
    left.length === right.length && left.every((label, i) => label === right[i])
  )
}
