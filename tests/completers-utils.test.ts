import { describe, expect, it } from 'vitest'
import {
  completerMemberItems,
  completersFromDrafts,
  draftsFromCompleters,
  prefillCompleterDrafts,
} from '../app/utils/completers'

describe('completersFromDrafts', () => {
  it('turns members and names into one completer set', () => {
    expect(completersFromDrafts(['u1'], ['Grandpa'])).toEqual([
      { user_id: 'u1', completer_name: null },
      { user_id: null, completer_name: 'Grandpa' },
    ])
  })

  it('trims names, drops blanks and de-duplicates', () => {
    expect(completersFromDrafts([], [' Sam ', 'Sam', '  ', ''])).toEqual([
      { user_id: null, completer_name: 'Sam' },
    ])
  })
})

describe('draftsFromCompleters', () => {
  it('splits a completer set back into member and name drafts', () => {
    expect(
      draftsFromCompleters([
        { user_id: 'u1', completer_name: null },
        { user_id: null, completer_name: 'Sam' },
      ]),
    ).toEqual({ members: ['u1'], names: ['Sam'] })
  })
})

describe('prefillCompleterDrafts', () => {
  it('uses the existing completers when there are any', () => {
    expect(
      prefillCompleterDrafts(
        [
          { user_id: 'u2', completer_name: null },
          { user_id: null, completer_name: 'Sam' },
        ],
        'me',
      ),
    ).toEqual({ members: ['u2'], names: ['Sam'] })
  })

  it('credits the signed-in member when nobody is credited yet', () => {
    expect(prefillCompleterDrafts([], 'me')).toEqual({
      members: ['me'],
      names: [],
    })
  })

  it('starts empty when nobody is credited and there is no signed-in user', () => {
    expect(prefillCompleterDrafts([], undefined)).toEqual({
      members: [],
      names: [],
    })
  })
})

describe('completerMemberItems', () => {
  it('maps members to picker items with short labels and avatars', () => {
    expect(
      completerMemberItems([
        {
          user_id: 'u1',
          display_name: 'Steve Adams',
          email: 's@x.com',
          avatar_url: 'http://a/1.png',
        },
        {
          user_id: 'u2',
          display_name: null,
          email: 'pat@x.com',
          avatar_url: null,
        },
      ]),
    ).toEqual([
      { title: 'Steve', value: 'u1', avatarUrl: 'http://a/1.png' },
      { title: 'pat@x.com', value: 'u2', avatarUrl: null },
    ])
  })
})
