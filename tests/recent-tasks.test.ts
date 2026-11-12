import { describe, expect, it } from 'vitest'
import { splitJumpBackIn } from '../app/utils/recent-tasks'

const t = (id: string) => ({ id })

describe('splitJumpBackIn', () => {
  it('takes recent tasks in recency order and removes them from the rest', () => {
    const tasks = [t('a'), t('b'), t('c'), t('d')]

    const { recent, rest } = splitJumpBackIn(tasks, ['c', 'a'])

    expect(recent.map((x) => x.id)).toEqual(['c', 'a'])
    expect(rest.map((x) => x.id)).toEqual(['b', 'd'])
  })

  it('skips ids not in the list (done, other farm, filtered by search)', () => {
    const { recent } = splitJumpBackIn([t('a'), t('b')], ['gone', 'b'])

    expect(recent.map((x) => x.id)).toEqual(['b'])
  })

  it('caps the strip at the limit, leaving the overflow in the rest', () => {
    const tasks = [t('a'), t('b'), t('c'), t('d')]

    const { recent, rest } = splitJumpBackIn(tasks, ['d', 'c', 'b', 'a'], 3)

    expect(recent.map((x) => x.id)).toEqual(['d', 'c', 'b'])
    expect(rest.map((x) => x.id)).toEqual(['a'])
  })

  it('leaves everything in the rest when nothing was timed', () => {
    const { recent, rest } = splitJumpBackIn([t('a')], [])

    expect(recent).toEqual([])
    expect(rest.map((x) => x.id)).toEqual(['a'])
  })
})
