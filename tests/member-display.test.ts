import { describe, expect, it } from 'vitest'
import {
  memberShortLabels,
  type MemberNameInfo,
} from '../app/utils/member-display'

function member(
  user_id: string,
  display_name: string | null,
  email: string | null = `${user_id}@example.com`,
): MemberNameInfo {
  return { user_id, display_name, email }
}

function labels(members: MemberNameInfo[]): Record<string, string> {
  return Object.fromEntries(memberShortLabels(members))
}

describe('memberShortLabels', () => {
  it('uses the first name alone when no other member shares it', () => {
    expect(
      labels([member('u1', 'Steve Adams'), member('u2', 'Kaleb Cooper')]),
    ).toEqual({ u1: 'Steve', u2: 'Kaleb' })
  })

  it('adds a last initial when first names collide', () => {
    expect(
      labels([member('u1', 'Steve Adams'), member('u2', 'Steve Brown')]),
    ).toEqual({ u1: 'Steve A.', u2: 'Steve B.' })
  })

  it('compares first names case-insensitively', () => {
    expect(
      labels([member('u1', 'steve adams'), member('u2', 'Steve Brown')]),
    ).toEqual({ u1: 'steve A.', u2: 'Steve B.' })
  })

  it('falls back to the full name when first name + initial still collide', () => {
    expect(
      labels([member('u1', 'Steve Adams'), member('u2', 'Steve Anderson')]),
    ).toEqual({ u1: 'Steve Adams', u2: 'Steve Anderson' })
  })

  it('falls back to email when full names are identical', () => {
    expect(
      labels([
        member('u1', 'Steve Adams', 'steve@example.com'),
        member('u2', 'Steve Adams', 'other.steve@example.com'),
      ]),
    ).toEqual({ u1: 'steve@example.com', u2: 'other.steve@example.com' })
  })

  it('takes the initial from the last word, skipping middle names', () => {
    expect(
      labels([
        member('u1', 'Steve Michael Adams'),
        member('u2', 'Steve Brown'),
      ]),
    ).toEqual({ u1: 'Steve A.', u2: 'Steve B.' })
  })

  it('keeps a single-word name as-is alongside a colliding first name', () => {
    expect(
      labels([member('u1', 'Steve'), member('u2', 'Steve Adams')]),
    ).toEqual({ u1: 'Steve', u2: 'Steve A.' })
  })

  it('falls back to email for members with no display name', () => {
    expect(
      labels([
        member('u1', null, 'nameless@example.com'),
        member('u2', 'Steve Adams'),
      ]),
    ).toEqual({ u1: 'nameless@example.com', u2: 'Steve' })
  })

  it('treats a whitespace-only display name as missing', () => {
    expect(labels([member('u1', '   ', 'blank@example.com')])).toEqual({
      u1: 'blank@example.com',
    })
  })

  it('falls back to the user id when there is no name and no email', () => {
    expect(labels([member('u1', null, null)])).toEqual({ u1: 'u1' })
  })

  it('returns an empty map for no members', () => {
    expect(labels([])).toEqual({})
  })
})
