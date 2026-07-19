import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'
import type { Database } from '~~/app/types/database.types'
import {
  isValidSnoozeMinutes,
  snoozeTargetIso,
} from '~~/app/utils/reminder-snooze'

// This is the project's first server route, and it exists for exactly one
// reason: the service worker's notification action buttons (Snooze 10 min /
// Snooze 1 hr — see public/sw.js) have no Supabase session to work with. A
// push event handler can't read the page's auth cookies from JS, but a
// same-origin `fetch()` from the worker DOES carry the browser's cookies, so
// this route rebuilds a *user-session* Supabase client from those cookies
// and performs the exact same update the in-app snooze buttons do (see
// snoozeReminder in app/services/reminders.ts). RLS is what actually
// enforces farm scoping here, same as every client-side query in this
// codebase — this route adds no authorization logic of its own beyond "is
// there a signed-in user at all".
export default defineEventHandler(async (event) => {
  const body = await readBody<{ reminderId?: unknown; minutes?: unknown }>(
    event,
  )

  const reminderId = body?.reminderId
  if (typeof reminderId !== 'string' || reminderId.length === 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'reminderId is required',
    })
  }

  const minutes = body?.minutes
  if (!isValidSnoozeMinutes(minutes)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'minutes must be 10 or 60',
    })
  }

  // serverSupabaseUser throws (via h3's createError) on a malformed/invalid
  // session and returns null when there's simply no session — both mean "not
  // signed in" from this route's point of view.
  let user
  try {
    user = await serverSupabaseUser(event)
  } catch {
    user = null
  }
  if (!user) {
    throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
  }

  const supabase = await serverSupabaseClient<Database>(event)

  // `.update().eq().select()` returns an array, first element taken — this
  // codebase's services layer avoids `.single()` chained after `.update()`
  // (PostgREST doesn't support the combination in practice; see
  // updateTaskPhotoCaption in app/services/photos.ts), so this route matches
  // that convention rather than introducing a one-off exception.
  const { data, error } = await supabase
    .from('task_reminders')
    .update({ remind_at: snoozeTargetIso(minutes), sent_at: null })
    .eq('id', reminderId)
    .select('id, task_id, remind_at, sent_at, created_at')

  // Under RLS, a reminderId outside the caller's farms simply doesn't match
  // the update — no row comes back. Either way (a real error, or a
  // caller-invisible row) it's indistinguishable from "doesn't exist" to this
  // caller, so both map to a plain 404 rather than leaking anything about
  // reminders the caller can't see.
  const reminder = data?.[0]
  if (error || !reminder) {
    throw createError({ statusCode: 404, statusMessage: 'Reminder not found' })
  }

  return reminder
})
