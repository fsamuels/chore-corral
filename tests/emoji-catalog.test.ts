import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  EMOJI_RECENTS_KEY,
  EMOJI_RECENTS_LIMIT,
  buildCatalog,
  groupCatalog,
  loadEmojiCatalog,
  loadRecentEmoji,
  recordRecentEmoji,
  searchCatalog,
  type RawEmoji,
} from '../app/utils/emoji-catalog'

// A small fixture standing in for emojibase-data — deliberately covers every
// filter case: normal grouped emoji, the components group (2), an ungrouped
// entry, and a version newer than fonts render. `order` is intentionally out
// of sequence so we can assert the sort.
const FIXTURE: RawEmoji[] = [
  {
    label: 'grinning face',
    hexcode: '1F600',
    emoji: '😀',
    tags: ['happy', 'smile'],
    order: 5,
    group: 0,
    subgroup: 0,
    version: 1,
  },
  {
    label: 'cow',
    hexcode: '1F404',
    emoji: '🐄',
    tags: ['cattle', 'farm'],
    order: 2,
    group: 3,
    subgroup: 5,
    version: 1,
  },
  {
    label: 'pizza',
    hexcode: '1F355',
    emoji: '🍕',
    tags: ['cheese', 'food'],
    order: 1,
    group: 4,
    subgroup: 9,
    version: 1,
  },
  {
    label: 'light skin tone',
    hexcode: '1F3FB',
    emoji: '🏻',
    tags: ['skin'],
    order: 3,
    group: 2,
    subgroup: 0,
    version: 1,
  },
  {
    label: 'regional indicator A',
    hexcode: '1F1E6',
    emoji: '🇦',
    order: 4,
    version: 0,
  },
  {
    label: 'future emoji',
    hexcode: 'FFFFF',
    emoji: '🆕',
    tags: ['new'],
    order: 0,
    group: 8,
    subgroup: 0,
    version: 17,
  },
]

describe('buildCatalog', () => {
  it('drops the components group, ungrouped entries, and version > 16', () => {
    const result = buildCatalog(FIXTURE)
    const emoji = result.map((entry) => entry.emoji)

    expect(emoji).not.toContain('🏻') // group 2 (components)
    expect(emoji).not.toContain('🇦') // no group
    expect(emoji).not.toContain('🆕') // version 17
    expect(emoji).toEqual(['🍕', '🐄', '😀']) // kept, sorted by order (1, 2, 5)
  })

  it('defaults missing tags to an empty array', () => {
    const result = buildCatalog([
      {
        label: 'gear',
        hexcode: '2699',
        emoji: '⚙️',
        order: 1,
        group: 7,
        subgroup: 0,
        version: 1,
      },
    ])
    expect(result[0]?.tags).toEqual([])
  })
})

describe('groupCatalog', () => {
  it('buckets entries by group with display names, ordered by group id', () => {
    const grouped = groupCatalog(buildCatalog(FIXTURE))

    expect(grouped.map((g) => g.group)).toEqual([0, 3, 4])
    expect(grouped.map((g) => g.name)).toEqual([
      'Smileys & Emotion',
      'Animals & Nature',
      'Food & Drink',
    ])
    expect(grouped[0]?.emoji.map((e) => e.emoji)).toEqual(['😀'])
  })
})

describe('searchCatalog', () => {
  const catalog = buildCatalog(FIXTURE)

  it('matches on label, case-insensitively', () => {
    expect(searchCatalog(catalog, 'COW').map((e) => e.emoji)).toEqual(['🐄'])
  })

  it('matches on tags', () => {
    expect(searchCatalog(catalog, 'cheese').map((e) => e.emoji)).toEqual(['🍕'])
  })

  it('returns the full list unchanged for a blank query', () => {
    expect(searchCatalog(catalog, '   ')).toBe(catalog)
  })

  it('returns an empty list when nothing matches', () => {
    expect(searchCatalog(catalog, 'zzzz')).toEqual([])
  })
})

describe('recents', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('returns an empty list when nothing is stored', () => {
    expect(loadRecentEmoji()).toEqual([])
  })

  it('records picks newest-first and persists them', () => {
    recordRecentEmoji('🐄')
    recordRecentEmoji('🍕')
    expect(loadRecentEmoji()).toEqual(['🍕', '🐄'])
    expect(
      JSON.parse(localStorage.getItem(EMOJI_RECENTS_KEY) as string),
    ).toEqual(['🍕', '🐄'])
  })

  it('dedupes, moving an existing pick back to the front', () => {
    recordRecentEmoji('🐄')
    recordRecentEmoji('🍕')
    recordRecentEmoji('🐄')
    expect(loadRecentEmoji()).toEqual(['🐄', '🍕'])
  })

  it('caps the list at the recents limit', () => {
    for (let i = 0; i < EMOJI_RECENTS_LIMIT + 5; i++) {
      recordRecentEmoji(`e${i}`)
    }
    const recents = loadRecentEmoji()
    expect(recents).toHaveLength(EMOJI_RECENTS_LIMIT)
    expect(recents[0]).toBe(`e${EMOJI_RECENTS_LIMIT + 4}`) // most recent
  })

  it('tolerates corrupt stored data', () => {
    localStorage.setItem(EMOJI_RECENTS_KEY, 'not json')
    expect(loadRecentEmoji()).toEqual([])
  })

  it('ignores non-string entries in stored data', () => {
    localStorage.setItem(EMOJI_RECENTS_KEY, JSON.stringify(['🐄', 42, null]))
    expect(loadRecentEmoji()).toEqual(['🐄'])
  })
})

// Mock the dynamic import so the loader is exercised against the fixture rather
// than downloading and parsing the real ~760 KB dataset.
vi.mock('emojibase-data/en/data.json', () => ({ default: FIXTURE }))

describe('loadEmojiCatalog', () => {
  it('imports the dataset, filters, and caches the built catalog', async () => {
    const first = await loadEmojiCatalog()
    expect(first.map((e) => e.emoji)).toEqual(['🍕', '🐄', '😀'])

    // Module-level cache: a second call resolves to the same array instance.
    const second = await loadEmojiCatalog()
    expect(second).toBe(first)
  })
})
