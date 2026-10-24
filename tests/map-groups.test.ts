import { describe, expect, it } from 'vitest'
import {
  countUnlocated,
  groupTasksByPlace,
  highestPriority,
} from '../app/utils/map-groups'

describe('highestPriority', () => {
  it('picks the most pressing priority', () => {
    expect(
      highestPriority([{ priority: 'whenever' }, { priority: 'urgent' }]),
    ).toBe('urgent')
    expect(
      highestPriority([{ priority: 'whenever' }, { priority: 'soon' }]),
    ).toBe('soon')
    expect(highestPriority([{ priority: 'whenever' }])).toBe('whenever')
  })

  it('defaults to whenever when empty', () => {
    expect(highestPriority([])).toBe('whenever')
  })
})

type Chore = Parameters<typeof groupTasksByPlace>[0][number] & { id: string }
function chore(overrides: Partial<Chore> = {}): Chore {
  return {
    id: 'a',
    title: 'Chore',
    priority: 'soon',
    lat: null,
    lng: null,
    location_id: null,
    ...overrides,
  }
}

const locations = [
  { id: 'l-shop', name: 'Shop' },
  { id: 'l-barn', name: 'Barn' },
]

describe('groupTasksByPlace', () => {
  it('orders locations alphabetically, then custom pins, then no location', () => {
    const groups = groupTasksByPlace(
      [
        chore({ id: '1' }),
        chore({ id: '2', lat: 1, lng: 1 }),
        chore({ id: '3', location_id: 'l-shop' }),
        chore({ id: '4', location_id: 'l-barn' }),
      ],
      locations,
    )
    expect(groups.map((g) => g.title)).toEqual([
      'Barn',
      'Shop',
      'Custom pins',
      'No location',
    ])
    expect(groups.map((g) => g.key)).toEqual([
      'location-l-barn',
      'location-l-shop',
      'custom',
      'none',
    ])
  })

  it('omits empty groups and treats unknown location ids as no location', () => {
    const groups = groupTasksByPlace(
      [chore({ location_id: 'gone' })],
      locations,
    )
    expect(groups.map((g) => g.title)).toEqual(['No location'])
  })

  it('sorts within a group by priority then title', () => {
    const groups = groupTasksByPlace(
      [
        chore({
          id: 'a',
          title: 'B',
          priority: 'whenever',
          location_id: 'l-shop',
        }),
        chore({
          id: 'b',
          title: 'Z',
          priority: 'urgent',
          location_id: 'l-shop',
        }),
        chore({
          id: 'c',
          title: 'A',
          priority: 'whenever',
          location_id: 'l-shop',
        }),
      ],
      locations,
    )
    expect(groups[0]!.tasks.map((x) => x.id)).toEqual(['b', 'c', 'a'])
  })

  it('returns no groups for no chores', () => {
    expect(groupTasksByPlace([], locations)).toEqual([])
  })
})

describe('countUnlocated', () => {
  it('counts chores with neither a pin nor a known location', () => {
    const tasks = [
      chore({ lat: 1, lng: 2 }),
      chore({ location_id: 'l-shop' }),
      chore({ location_id: 'gone' }),
      chore(),
    ]
    expect(countUnlocated(tasks, locations)).toBe(2)
  })

  it('is zero for no chores', () => {
    expect(countUnlocated([], locations)).toBe(0)
  })
})
