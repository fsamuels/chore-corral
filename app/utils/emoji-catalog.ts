// Emoji catalog: filtering, grouping, search, and recents, plus a lazily
// loaded, module-cached copy of the emojibase dataset. Kept framework-free so
// the pure logic is unit-testable without Nuxt's auto-imports; the reactive
// wrapper lives in useEmojiCatalog.

/** One raw entry from `emojibase-data/en/data.json`. */
export interface RawEmoji {
  label: string
  hexcode: string
  tags?: string[]
  emoji: string
  order?: number
  group?: number
  subgroup?: number
  version: number
}

/** A displayable catalog entry, trimmed to what the picker renders. */
export interface CatalogEmoji {
  emoji: string
  label: string
  tags: string[]
  group: number
  order: number
}

/** A group of catalog entries with its display name. */
export interface EmojiGroup {
  group: number
  name: string
  emoji: CatalogEmoji[]
}

// Display-cased group names for emojibase group ids 0–9. Hardcoded rather than
// also shipping messages.json (which we'd otherwise pull in only for these ten
// strings). Group 2 ("Components") is filtered out before display but named
// here for completeness.
export const EMOJI_GROUP_NAMES: Record<number, string> = {
  0: 'Smileys & Emotion',
  1: 'People & Body',
  2: 'Components',
  3: 'Animals & Nature',
  4: 'Food & Drink',
  5: 'Travel & Places',
  6: 'Activities',
  7: 'Objects',
  8: 'Symbols',
  9: 'Flags',
}

// Group 2 is skin-tone/hair swatches — modifiers, not standalone emoji.
const COMPONENTS_GROUP = 2
// Emoji fonts on older phones don't yet render Unicode 17 (version 17+)
// glyphs, so they'd show as tofu. Cap at the highest widely-rendered version.
const MAX_SUPPORTED_VERSION = 16

/**
 * Filter the raw dataset to displayable entries (must have a group, excluding
 * the components group and anything newer than fonts reliably render), map to
 * the trimmed shape, and sort by emojibase `order`.
 */
export function buildCatalog(raw: RawEmoji[]): CatalogEmoji[] {
  return raw
    .filter(
      (entry) =>
        entry.group !== undefined &&
        entry.group !== COMPONENTS_GROUP &&
        entry.version <= MAX_SUPPORTED_VERSION,
    )
    .map((entry) => ({
      emoji: entry.emoji,
      label: entry.label,
      tags: entry.tags ?? [],
      group: entry.group as number,
      order: entry.order ?? 0,
    }))
    .sort((a, b) => a.order - b.order)
}

/** Bucket catalog entries by group, ordered by group id. */
export function groupCatalog(entries: CatalogEmoji[]): EmojiGroup[] {
  const byGroup = new Map<number, CatalogEmoji[]>()
  for (const entry of entries) {
    const bucket = byGroup.get(entry.group)
    if (bucket) bucket.push(entry)
    else byGroup.set(entry.group, [entry])
  }
  return [...byGroup.keys()]
    .sort((a, b) => a - b)
    .map((group) => ({
      group,
      name: EMOJI_GROUP_NAMES[group] ?? `Group ${group}`,
      emoji: byGroup.get(group) as CatalogEmoji[],
    }))
}

/**
 * Case-insensitive substring search over label and tags. An empty/blank query
 * returns the full list unchanged.
 */
export function searchCatalog(
  entries: CatalogEmoji[],
  query: string,
): CatalogEmoji[] {
  const needle = query.trim().toLowerCase()
  if (!needle) return entries
  return entries.filter(
    (entry) =>
      entry.label.toLowerCase().includes(needle) ||
      entry.tags.some((tag) => tag.toLowerCase().includes(needle)),
  )
}

export const EMOJI_RECENTS_KEY = 'cc:emoji-recents'
export const EMOJI_RECENTS_LIMIT = 24

// localStorage is absent during SSR and can throw (private mode / quota /
// blocked storage). Every access is guarded and failures are swallowed —
// recents are a convenience, never load-bearing.
function safeLocalStorage(): Storage | null {
  try {
    return typeof localStorage === 'undefined' ? null : localStorage
  } catch {
    return null
  }
}

/** Most-recently-picked emoji, newest first (empty when unavailable). */
export function loadRecentEmoji(): string[] {
  const store = safeLocalStorage()
  if (!store) return []
  try {
    const raw = store.getItem(EMOJI_RECENTS_KEY)
    if (!raw) return []
    const parsed: unknown = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return parsed
      .filter((value): value is string => typeof value === 'string')
      .slice(0, EMOJI_RECENTS_LIMIT)
  } catch {
    return []
  }
}

/**
 * Record a pick at the front of the recents list (deduped, capped) and persist
 * it. Returns the updated list so callers can reflect it without a re-read.
 */
export function recordRecentEmoji(emoji: string): string[] {
  const next = [emoji, ...loadRecentEmoji().filter((e) => e !== emoji)].slice(
    0,
    EMOJI_RECENTS_LIMIT,
  )
  const store = safeLocalStorage()
  if (store) {
    try {
      store.setItem(EMOJI_RECENTS_KEY, JSON.stringify(next))
    } catch {
      // Quota or security error — keep the in-memory result, drop persistence.
    }
  }
  return next
}

// Module-level promise cache: the 760 KB JSON downloads as its own async chunk
// on first open and stays parsed for the session, so reopening is instant. On
// failure the cache is cleared so a later open (e.g. back online) can retry.
let catalogPromise: Promise<CatalogEmoji[]> | null = null

export function loadEmojiCatalog(): Promise<CatalogEmoji[]> {
  if (!catalogPromise) {
    catalogPromise = import('emojibase-data/en/data.json')
      .then((mod) =>
        buildCatalog((mod.default ?? mod) as unknown as RawEmoji[]),
      )
      .catch((error) => {
        catalogPromise = null
        throw error
      })
  }
  return catalogPromise
}
