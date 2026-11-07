import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  initialQuickStartCategory,
  loadQuickStartCategory,
  quickStartTaskInput,
  saveQuickStartCategory,
} from '../app/utils/quick-start'

describe('quickStartTaskInput', () => {
  it('fixes priority to whenever and due date to the local today', () => {
    const input = quickStartTaskInput(
      { title: '  Fix gate  ', categoryId: 'cat-1', notes: '  latch bent ' },
      new Date(2026, 10, 7, 23, 30),
    )

    expect(input).toEqual({
      title: 'Fix gate',
      categoryId: 'cat-1',
      priority: 'whenever',
      dueDate: '2026-11-07',
      notes: 'latch bent',
    })
  })

  it('turns blank notes into null and keeps an uncategorized chore', () => {
    const input = quickStartTaskInput(
      { title: 'Feed', categoryId: null, notes: '   ' },
      new Date(2026, 0, 2),
    )

    expect(input.notes).toBeNull()
    expect(input.categoryId).toBeNull()
    expect(input.dueDate).toBe('2026-01-02')
  })
})

describe('initialQuickStartCategory', () => {
  it('uses the remembered category while it still exists', () => {
    expect(initialQuickStartCategory('b', ['a', 'b'])).toBe('b')
  })

  it('falls back to uncategorized when it was deleted or never set', () => {
    expect(initialQuickStartCategory('gone', ['a'])).toBeNull()
    expect(initialQuickStartCategory(null, ['a'])).toBeNull()
  })
})

describe('remembered quick-start category', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  function stubStorage() {
    const data = new Map<string, string>()
    vi.stubGlobal('localStorage', {
      getItem: (k: string) => data.get(k) ?? null,
      setItem: (k: string, v: string) => void data.set(k, v),
      removeItem: (k: string) => void data.delete(k),
    })
    return data
  }

  it('round-trips per farm and forgets on null', () => {
    stubStorage()
    saveQuickStartCategory('farm-1', 'cat-1')
    saveQuickStartCategory('farm-2', 'cat-2')

    expect(loadQuickStartCategory('farm-1')).toBe('cat-1')
    expect(loadQuickStartCategory('farm-2')).toBe('cat-2')

    saveQuickStartCategory('farm-1', null)
    expect(loadQuickStartCategory('farm-1')).toBeNull()
  })

  it('treats storage that throws as empty', () => {
    vi.stubGlobal('localStorage', {
      getItem: () => {
        throw new Error('blocked')
      },
      setItem: () => {
        throw new Error('blocked')
      },
      removeItem: () => {
        throw new Error('blocked')
      },
    })

    expect(() => saveQuickStartCategory('farm-1', 'cat-1')).not.toThrow()
    expect(loadQuickStartCategory('farm-1')).toBeNull()
  })
})
