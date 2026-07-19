/**
 * Snooze support for chore reminders. A snooze doesn't create anything new —
 * it mutates the same `task_reminders` row (`remind_at` pushed out, `sent_at`
 * cleared back to null) so the row re-fires through the existing every-minute
 * send-reminders pipeline and the chore's Reminders card naturally shows it
 * as upcoming again. See docs/ARCHITECTURE.md ("Push Notifications").
 *
 * This file is pure/dependency-free on purpose: it's shared by the client
 * services layer (app/services/reminders.ts) AND the Nitro server route
 * (server/api/reminders/snooze.post.ts) that the service worker's notification
 * action buttons call — both need the exact same validation and math.
 */

/** The only two snooze durations offered, on both surfaces. */
export type SnoozeMinutes = 10 | 60

export interface SnoozeOption {
  minutes: SnoozeMinutes
  /** Short — used as button text, so keep it tight. User copy says "chore(s)", never "task(s)", but these labels don't reference either. */
  label: string
}

export const SNOOZE_OPTIONS: readonly SnoozeOption[] = [
  { minutes: 10, label: 'Snooze 10 min' },
  { minutes: 60, label: 'Snooze 1 hr' },
]

const VALID_MINUTES: ReadonlySet<number> = new Set(
  SNOOZE_OPTIONS.map((o) => o.minutes),
)

/**
 * Strict whitelist check: a real snooze request (from the in-app buttons or
 * the service worker's POST body) must be exactly the number 10 or 60 — not
 * a numeric string, not a float, not a lookalike like 10.0 masquerading as
 * something else. Typed as a `value is SnoozeMinutes` guard so callers get
 * the narrowed literal union back.
 */
export function isValidSnoozeMinutes(value: unknown): value is SnoozeMinutes {
  return (
    typeof value === 'number' &&
    Number.isInteger(value) &&
    VALID_MINUTES.has(value)
  )
}

/**
 * The new `remind_at` instant for a snooze: `minutes` from now, as an ISO
 * string ready to write straight to the `task_reminders` row. `nowMs`
 * defaults to `Date.now()` but is overridable for deterministic tests.
 */
export function snoozeTargetIso(
  minutes: SnoozeMinutes,
  nowMs: number = Date.now(),
): string {
  return new Date(nowMs + minutes * 60_000).toISOString()
}
