import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  createRemovalController,
  UNDO_TIMEOUT_MS,
  type Removal,
} from '../app/utils/undoable-removal'

function setup() {
  const undos: Array<() => void> = []
  const onPending = vi.fn((_message: string, undo: () => void) => {
    undos.push(undo)
  })
  const onCommitError = vi.fn()
  const controller = createRemovalController({ onPending, onCommitError })
  return { controller, onPending, onCommitError, undos }
}

function makeRemoval(overrides: Partial<Removal> = {}) {
  return {
    hide: vi.fn(),
    restore: vi.fn(),
    commit: vi.fn(async () => {}),
    message: 'Item removed',
    ...overrides,
  }
}

describe('createRemovalController', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  it('hides immediately, announces Undo, and does not commit yet', () => {
    const { controller, onPending } = setup()
    const removal = makeRemoval()
    controller.start(removal)
    expect(removal.hide).toHaveBeenCalledOnce()
    expect(onPending).toHaveBeenCalledWith('Item removed', expect.any(Function))
    expect(removal.commit).not.toHaveBeenCalled()
    expect(controller.hasPending).toBe(true)
  })

  it('commits once the undo window closes', async () => {
    const { controller } = setup()
    const removal = makeRemoval()
    controller.start(removal)
    await vi.advanceTimersByTimeAsync(UNDO_TIMEOUT_MS - 1)
    expect(removal.commit).not.toHaveBeenCalled()
    await vi.advanceTimersByTimeAsync(1)
    expect(removal.commit).toHaveBeenCalledOnce()
    expect(removal.restore).not.toHaveBeenCalled()
    expect(controller.hasPending).toBe(false)
  })

  it('undo restores and cancels the commit', async () => {
    const { controller, undos } = setup()
    const removal = makeRemoval()
    controller.start(removal)
    undos[0]!()
    expect(removal.restore).toHaveBeenCalledOnce()
    await vi.advanceTimersByTimeAsync(UNDO_TIMEOUT_MS * 2)
    expect(removal.commit).not.toHaveBeenCalled()
    expect(controller.hasPending).toBe(false)
  })

  it('ignores a stale undo after the commit has happened', async () => {
    const { controller, undos } = setup()
    const removal = makeRemoval()
    controller.start(removal)
    await vi.advanceTimersByTimeAsync(UNDO_TIMEOUT_MS)
    undos[0]!()
    expect(removal.restore).not.toHaveBeenCalled()
  })

  it('restores and reports when the commit fails', async () => {
    const { controller, onCommitError } = setup()
    const error = new Error('nope')
    const removal = makeRemoval({
      commit: vi.fn(async () => {
        throw error
      }),
    })
    controller.start(removal)
    await vi.advanceTimersByTimeAsync(UNDO_TIMEOUT_MS)
    expect(removal.restore).toHaveBeenCalledOnce()
    expect(onCommitError).toHaveBeenCalledWith(error, removal)
  })

  it('commits the pending removal immediately when a second starts', async () => {
    const { controller, undos } = setup()
    const first = makeRemoval({ message: 'first' })
    const second = makeRemoval({ message: 'second' })
    controller.start(first)
    controller.start(second)
    expect(first.commit).toHaveBeenCalledOnce()
    expect(second.hide).toHaveBeenCalledOnce()
    expect(second.commit).not.toHaveBeenCalled()

    // First's timer must not fire a second commit; the stale undo is a no-op.
    undos[0]!()
    expect(first.restore).not.toHaveBeenCalled()
    await vi.advanceTimersByTimeAsync(UNDO_TIMEOUT_MS)
    expect(first.commit).toHaveBeenCalledOnce()
    expect(second.commit).toHaveBeenCalledOnce()
  })

  it('flush commits the pending removal now and clears its timer', async () => {
    const { controller } = setup()
    const removal = makeRemoval()
    controller.start(removal)
    await controller.flush()
    expect(removal.commit).toHaveBeenCalledOnce()
    await vi.advanceTimersByTimeAsync(UNDO_TIMEOUT_MS * 2)
    expect(removal.commit).toHaveBeenCalledOnce()
  })

  it('flush with nothing pending is a no-op', async () => {
    const { controller } = setup()
    await expect(controller.flush()).resolves.toBeUndefined()
  })
})
