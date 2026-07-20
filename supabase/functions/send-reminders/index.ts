// send-reminders — Web Push delivery for due chore reminders
//
// Invoked once a minute by pg_cron (via `public.invoke_send_reminders()` +
// pg_net) whenever at least one reminder is due. It claims the due rows,
// resolves each chore's farm audience, and fans one Web Push out to every push
// subscription of every member of that farm.
//
// Auth: this function is NOT protected by a Supabase JWT (verify_jwt = false in
// config.toml). The caller is Postgres/cron, which can't present a user JWT, so
// the shared secret in the `x-cron-secret` header IS the auth — it must equal
// the SEND_REMINDERS_SECRET env var or we 401. That same secret is stored in
// Vault as `send_reminders_secret` and sent by invoke_send_reminders().
//
// All database work uses the service-role client (SUPABASE_SERVICE_ROLE_KEY,
// auto-injected in Edge Functions), which bypasses RLS — required because the
// audience spans every farm member's personal, owner-only push_subscriptions.
//
// Library choice: npm:web-push. It consumes the exact base64url VAPID keypair
// that `npx web-push generate-vapid-keys` emits (the same public key the client
// hands navigator's PushManager.subscribe as applicationServerKey), and its
// thrown WebPushError carries a `.statusCode` so we can prune dead devices on
// 404/410. It runs under the Supabase Edge runtime's Node compatibility layer
// (node:crypto / node:https). A JSR-native option (e.g. @negrel/webpush) exists
// but wants VAPID keys as JWK, which would fork the key format away from what
// the client needs, so web-push is the more reliable fit here.

import webpush from 'web-push'
import { createClient } from '@supabase/supabase-js'

// Reminders more than this far past due are claimed (marked sent) but NOT
// delivered. Rationale: if the scheduler or this function was down for a while,
// a backlog of long-past reminders shouldn't blast a burst of stale pings the
// moment things recover — a chore reminder is only useful near its time.
const STALE_AFTER_MS = 60 * 60 * 1000 // ~1 hour

interface ClaimedReminder {
  id: string
  task_id: string
  remind_at: string
}

interface TaskRow {
  id: string
  title: string
  farm_id: string
  status: string
}

interface SubscriptionRow {
  id: string
  endpoint: string
  p256dh: string
  auth: string
  user_id: string
}

interface ReminderPayload {
  title: string
  body: string
  url: string
  tag: string
  // The claimed row's id, so the service worker's notification action
  // buttons (Snooze 10 min / Snooze 1 hr — see public/sw.js) know which
  // task_reminders row to mutate. Every payload has one: this function only
  // ever builds a payload for a reminder it just claimed.
  reminderId: string
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  // --- Shared-secret auth -------------------------------------------------
  const expectedSecret = Deno.env.get('SEND_REMINDERS_SECRET')
  const providedSecret = req.headers.get('x-cron-secret')
  if (!expectedSecret || providedSecret !== expectedSecret) {
    return json({ error: 'unauthorized' }, 401)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: 'server not configured' }, 500)
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  })

  // --- VAPID setup --------------------------------------------------------
  const vapidPublic = Deno.env.get('VAPID_PUBLIC_KEY')
  const vapidPrivate = Deno.env.get('VAPID_PRIVATE_KEY')
  const vapidSubject =
    Deno.env.get('VAPID_SUBJECT') ?? 'mailto:reminders@chore-corral.app'
  if (!vapidPublic || !vapidPrivate) {
    return json({ error: 'push not configured' }, 500)
  }
  webpush.setVapidDetails(vapidSubject, vapidPublic, vapidPrivate)

  const nowMs = Date.now()
  const nowIso = new Date(nowMs).toISOString()

  // --- Atomically claim due reminders -------------------------------------
  // A single UPDATE ... WHERE sent_at IS NULL AND remind_at <= now() that
  // returns the rows it actually touched. Postgres row-locks each matched row
  // and re-checks the predicate after locking, so a concurrent invocation can
  // never claim the same row twice — whoever stamps sent_at first wins and the
  // other's UPDATE no longer matches. This is our double-send guard.
  const { data: claimedData, error: claimError } = await supabase
    .from('task_reminders')
    .update({ sent_at: nowIso })
    .is('sent_at', null)
    .lte('remind_at', nowIso)
    .select('id, task_id, remind_at')

  if (claimError) {
    console.error('claim failed', claimError)
    return json({ error: 'claim failed' }, 500)
  }

  const claimed = (claimedData ?? []) as ClaimedReminder[]
  const summary = {
    claimed: claimed.length,
    sent: 0,
    failed: 0,
    prunedSubscriptions: 0,
  }
  if (claimed.length === 0) {
    return json(summary)
  }

  // Drop stale reminders: claimed (so they won't retry) but not delivered.
  const staleCutoffMs = nowMs - STALE_AFTER_MS
  const fresh = claimed.filter(
    (r) => new Date(r.remind_at).getTime() >= staleCutoffMs,
  )
  if (fresh.length === 0) {
    return json(summary)
  }

  // --- Resolve tasks (title + audience farm; skip completed chores) -------
  const taskIds = [...new Set(fresh.map((r) => r.task_id))]
  const { data: taskData, error: taskError } = await supabase
    .from('tasks')
    .select('id, title, farm_id, status')
    .in('id', taskIds)

  if (taskError) {
    console.error('task lookup failed', taskError)
    return json({ ...summary, error: 'task lookup failed' }, 500)
  }
  const tasksById = new Map<string, TaskRow>(
    (taskData ?? []).map((t) => [t.id, t as TaskRow]),
  )

  // A reminder is deliverable only if its task still exists and isn't done — a
  // completed chore shouldn't nag. (A deleted task cascade-deletes its
  // reminders, so a missing task here would be an edge race; skip it too.)
  const deliverable = fresh.filter((r) => {
    const task = tasksById.get(r.task_id)
    return task !== undefined && task.status !== 'done'
  })
  if (deliverable.length === 0) {
    return json(summary)
  }

  // --- Resolve farm audiences --------------------------------------------
  const farmIds = [
    ...new Set(deliverable.map((r) => tasksById.get(r.task_id)!.farm_id)),
  ]
  const { data: memberData, error: memberError } = await supabase
    .from('farm_memberships')
    .select('farm_id, user_id')
    .in('farm_id', farmIds)

  if (memberError) {
    console.error('membership lookup failed', memberError)
    return json({ ...summary, error: 'membership lookup failed' }, 500)
  }

  const usersByFarm = new Map<string, Set<string>>()
  for (const m of memberData ?? []) {
    const set = usersByFarm.get(m.farm_id) ?? new Set<string>()
    set.add(m.user_id)
    usersByFarm.set(m.farm_id, set)
  }

  // --- Resolve every audience member's push subscriptions -----------------
  const allUserIds = [...new Set((memberData ?? []).map((m) => m.user_id))]
  const subsByUser = new Map<string, SubscriptionRow[]>()
  if (allUserIds.length > 0) {
    const { data: subData, error: subError } = await supabase
      .from('push_subscriptions')
      .select('id, endpoint, p256dh, auth, user_id')
      .in('user_id', allUserIds)

    if (subError) {
      console.error('subscription lookup failed', subError)
      return json({ ...summary, error: 'subscription lookup failed' }, 500)
    }
    for (const s of subData ?? []) {
      const list = subsByUser.get(s.user_id) ?? []
      list.push(s as SubscriptionRow)
      subsByUser.set(s.user_id, list)
    }
  }

  // --- Deliver ------------------------------------------------------------
  const deadSubscriptionIds = new Set<string>()

  for (const reminder of deliverable) {
    const task = tasksById.get(reminder.task_id)!
    const payload: ReminderPayload = {
      title: task.title,
      body: 'Reminder for this chore',
      // `?farm=` so the client can switch farms before loading the chore —
      // a reminder can fire while the user's browser has a *different* farm
      // active (see resolveActiveFarmId's saved-selection cookie), and
      // useTask()'s farm-scoped lookup would otherwise report "not found"
      // for a chore that exists, just in the other farm.
      url: `/tasks/${task.id}?farm=${task.farm_id}`,
      tag: `reminder-${reminder.id}`,
      reminderId: reminder.id,
    }
    const payloadJson = JSON.stringify(payload)

    // Fan out to every subscription of every member of the chore's farm.
    const audienceUserIds = usersByFarm.get(task.farm_id) ?? new Set<string>()
    const seenSubscriptionIds = new Set<string>()
    for (const userId of audienceUserIds) {
      for (const sub of subsByUser.get(userId) ?? []) {
        if (seenSubscriptionIds.has(sub.id)) continue
        seenSubscriptionIds.add(sub.id)

        try {
          await webpush.sendNotification(
            {
              endpoint: sub.endpoint,
              keys: { p256dh: sub.p256dh, auth: sub.auth },
            },
            payloadJson,
          )
          summary.sent++
        } catch (err) {
          summary.failed++
          const statusCode = (err as { statusCode?: number })?.statusCode
          // 404/410 => the push subscription is gone (device unsubscribed or
          // expired). Prune it so we stop trying. Other errors are transient
          // (network, 5xx) and left in place; we just log and move on so one
          // bad send never sinks the whole batch.
          if (statusCode === 404 || statusCode === 410) {
            deadSubscriptionIds.add(sub.id)
          } else {
            console.error(
              `push failed for subscription ${sub.id}`,
              statusCode ?? err,
            )
          }
        }
      }
    }
  }

  // Prune dead subscriptions in one batch.
  if (deadSubscriptionIds.size > 0) {
    const ids = [...deadSubscriptionIds]
    const { error: pruneError } = await supabase
      .from('push_subscriptions')
      .delete()
      .in('id', ids)
    if (pruneError) {
      console.error('failed to prune dead subscriptions', pruneError)
    } else {
      summary.prunedSubscriptions = ids.length
    }
  }

  return json(summary)
})
