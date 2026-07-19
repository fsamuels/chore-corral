import { describe, expect, it } from 'vitest'
import { urlBase64ToUint8Array } from '../app/utils/push'

describe('urlBase64ToUint8Array', () => {
  it('decodes a standard base64 string to matching bytes', () => {
    // "Hello" in base64 is "SGVsbG8=" — no URL-safe chars, so this also
    // exercises the plain (already-padded) path.
    const result = urlBase64ToUint8Array('SGVsbG8=')
    expect(Array.from(result)).toEqual([72, 101, 108, 108, 111])
  })

  it('decodes URL-safe base64 (- and _ instead of + and /)', () => {
    // Byte sequence [251, 255, 191] base64-encodes to "+/+/" in standard
    // form and "-_-_" in URL-safe form — this exercises both substitutions.
    const standard = Buffer.from([0xfb, 0xff, 0xbf]).toString('base64')
    expect(standard).toBe('+/+/')
    const urlSafe = standard.replace(/\+/g, '-').replace(/\//g, '_')

    const result = urlBase64ToUint8Array(urlSafe)
    expect(Array.from(result)).toEqual([0xfb, 0xff, 0xbf])
  })

  it('pads a string missing its trailing "="', () => {
    // A real VAPID public key is 65 raw bytes -> 87 base64 chars with no
    // padding needed to reach a multiple of 4; a shorter example that does
    // need padding restored is used here instead.
    const withPadding = urlBase64ToUint8Array('SGVsbG8=') // 8 chars, has '='
    const withoutPadding = urlBase64ToUint8Array('SGVsbG8') // 7 chars, needs 1 '='
    expect(Array.from(withoutPadding)).toEqual(Array.from(withPadding))
  })

  it('returns an empty array for an empty string', () => {
    expect(urlBase64ToUint8Array('').length).toBe(0)
  })
})
