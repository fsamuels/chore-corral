import { ref, type Ref } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useTasksChanged } from '../app/composables/useTasksChanged'

describe('useTasksChanged', () => {
  beforeEach(() => {
    const store = new Map<string, Ref<unknown>>()
    vi.stubGlobal('useState', (key: string, init: () => unknown) => {
      if (!store.has(key)) store.set(key, ref(init()))
      return store.get(key)
    })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('bumps both counters by default (a chore finished)', () => {
    const { version, doneVersion, notifyTasksChanged } = useTasksChanged()
    notifyTasksChanged()
    expect(version.value).toBe(1)
    expect(doneVersion.value).toBe(1)
  })

  it('leaves the Done counter alone for an open-list-only change', () => {
    const { version, doneVersion, notifyTasksChanged } = useTasksChanged()
    notifyTasksChanged({ done: false })
    expect(version.value).toBe(1)
    expect(doneVersion.value).toBe(0)
  })

  it('shares state across callers', () => {
    useTasksChanged().notifyTasksChanged({ done: false })
    expect(useTasksChanged().version.value).toBe(1)
  })
})
