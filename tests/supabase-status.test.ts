import { describe, expect, it } from 'vitest'
import { isSupabaseConfigured } from '../app/utils/supabase-status'

describe('isSupabaseConfigured', () => {
  it('is true when both url and key are set', () => {
    expect(isSupabaseConfigured('https://x.supabase.co', 'anon-key')).toBe(true)
  })

  it('is false when either value is missing', () => {
    expect(isSupabaseConfigured('', 'anon-key')).toBe(false)
    expect(isSupabaseConfigured('https://x.supabase.co', '')).toBe(false)
    expect(isSupabaseConfigured(undefined, undefined)).toBe(false)
  })
})
