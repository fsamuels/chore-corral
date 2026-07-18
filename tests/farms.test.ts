import { describe, expect, it } from 'vitest'
import {
  acceptPendingInvites,
  createFarm,
  FARM_NAME_MAX_LENGTH,
} from '../app/services/farms'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'

describe('createFarm', () => {
  it('calls the create_farm RPC with trimmed inputs and returns the farm id', async () => {
    const fake = new FakeSupabaseClient()
    fake.onRpc('create_farm', () => ({ data: 'farm-9' }))

    const result = await createFarm(
      asSupabaseClient(fake),
      '  Reign Cloud Ranch  ',
      '  1 Ranch Rd  ',
    )

    expect(result).toBe('farm-9')
    expect(fake.getRpcCalls()).toEqual([
      {
        fn: 'create_farm',
        args: { farm_name: 'Reign Cloud Ranch', farm_address: '1 Ranch Rd' },
      },
    ])
  })

  it('sends null for a blank address', async () => {
    const fake = new FakeSupabaseClient()
    fake.onRpc('create_farm', () => ({ data: 'farm-9' }))

    await createFarm(asSupabaseClient(fake), 'Clarkson’s Farm', '   ')

    expect(fake.getRpcCalls()[0]?.args).toEqual({
      farm_name: 'Clarkson’s Farm',
      farm_address: null,
    })
  })

  it('rejects a blank name without calling the RPC', async () => {
    const fake = new FakeSupabaseClient()

    await expect(createFarm(asSupabaseClient(fake), '   ')).rejects.toThrow(
      'Farm name is required.',
    )
    expect(fake.getRpcCalls()).toEqual([])
  })

  it('rejects a name over the length cap', async () => {
    const fake = new FakeSupabaseClient()

    await expect(
      createFarm(asSupabaseClient(fake), 'x'.repeat(FARM_NAME_MAX_LENGTH + 1)),
    ).rejects.toThrow(`${FARM_NAME_MAX_LENGTH} characters or fewer`)
    expect(fake.getRpcCalls()).toEqual([])
  })

  it('surfaces RPC errors', async () => {
    const fake = new FakeSupabaseClient()
    fake.onRpc('create_farm', () => ({
      error: { message: 'permission denied' },
    }))

    await expect(
      createFarm(asSupabaseClient(fake), 'Schrute Farms'),
    ).rejects.toThrow('permission denied')
  })
})

describe('acceptPendingInvites', () => {
  it('returns the farm ids joined', async () => {
    const fake = new FakeSupabaseClient()
    fake.onRpc('accept_farm_invites', () => ({ data: ['farm-1', 'farm-2'] }))

    const result = await acceptPendingInvites(asSupabaseClient(fake))

    expect(result).toEqual(['farm-1', 'farm-2'])
    expect(fake.getRpcCalls()).toEqual([
      { fn: 'accept_farm_invites', args: undefined },
    ])
  })

  it('returns an empty list when the RPC returns no rows', async () => {
    const fake = new FakeSupabaseClient()
    fake.onRpc('accept_farm_invites', () => ({ data: null }))

    expect(await acceptPendingInvites(asSupabaseClient(fake))).toEqual([])
  })

  it('surfaces RPC errors', async () => {
    const fake = new FakeSupabaseClient()
    fake.onRpc('accept_farm_invites', () => ({
      error: { message: 'function does not exist' },
    }))

    await expect(acceptPendingInvites(asSupabaseClient(fake))).rejects.toThrow(
      'function does not exist',
    )
  })
})
