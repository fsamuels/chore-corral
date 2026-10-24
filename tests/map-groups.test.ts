import { describe, expect, it } from 'vitest'
import { highestPriority } from '../app/utils/map-groups'

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
