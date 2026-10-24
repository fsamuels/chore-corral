import { describe, expect, it } from 'vitest'
import { reminderPresets } from '../app/utils/reminder-presets'

// Local-time constructors, matching how the util computes its targets.
const local = (y: number, m: number, d: number, h = 0, min = 0) =>
  new Date(y, m - 1, d, h, min, 0, 0)

describe('reminderPresets', () => {
  it('offers three presets in order', () => {
    const labels = reminderPresets(local(2026, 10, 24, 10)).map((p) => p.label)
    expect(labels).toEqual(['In 1 hour', 'This evening', 'Tomorrow morning'])
  })

  it('"In 1 hour" is exactly 60 minutes after now', () => {
    const now = local(2026, 10, 24, 10, 17)
    expect(reminderPresets(now)[0]!.at.getTime()).toBe(now.getTime() + 3600_000)
  })

  it('"This evening" is today at 6:00 PM before 6 PM', () => {
    const at = reminderPresets(local(2026, 10, 24, 17, 59))[1]!.at
    expect(at).toEqual(local(2026, 10, 24, 18))
  })

  it('rolls to "Tomorrow evening" from 6 PM onward', () => {
    for (const now of [local(2026, 10, 24, 18), local(2026, 10, 24, 23, 30)]) {
      const preset = reminderPresets(now)[1]!
      expect(preset.label).toBe('Tomorrow evening')
      expect(preset.at).toEqual(local(2026, 10, 25, 18))
    }
  })

  it('"Tomorrow morning" is tomorrow at 8:00 AM, even just after midnight', () => {
    expect(reminderPresets(local(2026, 10, 24, 0, 5))[2]!.at).toEqual(
      local(2026, 10, 25, 8),
    )
  })

  it('crosses month and year boundaries', () => {
    const now = local(2026, 12, 31, 20)
    const presets = reminderPresets(now)
    expect(presets[1]!.at).toEqual(local(2027, 1, 1, 18))
    expect(presets[2]!.at).toEqual(local(2027, 1, 1, 8))
  })

  it('every preset is in the future', () => {
    for (let h = 0; h < 24; h++) {
      const now = local(2026, 10, 24, h, 30)
      for (const p of reminderPresets(now)) {
        expect(p.at.getTime()).toBeGreaterThan(now.getTime())
      }
    }
  })
})
