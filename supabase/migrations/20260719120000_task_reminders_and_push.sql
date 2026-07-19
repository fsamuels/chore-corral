-- Chore reminders via Web Push
--
-- Adds the backend half of "remind me about this chore": persistent push
-- subscriptions per device, a set of scheduled reminders per task, and the
-- every-minute scheduler that hands due reminders to the `send-reminders` Edge
-- Function (which performs the actual Web Push protocol sends). The client half
-- (service worker, subscribe/unsubscribe UI, reminder editor) lives in app/ and
-- talks to these two tables directly through PostgREST under the RLS below.
--
-- Two new tables:
--
--   1. `push_subscriptions` — one row per browser push subscription (i.e. per
--      device/browser a user has granted notification permission on). This is a
--      *personal device credential*, not farm data: it is owned by the user, not
--      shared with a farm, so its RLS is plain owner-only (`user_id =
--      auth.uid()`), unlike every farm-scoped table in this schema. A user may
--      have many rows (phone, laptop, ...); `endpoint` is globally unique so the
--      same device re-subscribing upserts rather than duplicates.
--
--   2. `task_reminders` — a set of scheduled reminder instants per task, each a
--      specific timestamptz. `sent_at` is stamped once a reminder has been
--      handed off for delivery, which is also the concurrency guard against
--      double-sends (see the Edge Function). Like the other task-child tables
--      (task_completers / task_tags / task_tools / ...) it carries no farm_id and
--      is scoped to a farm *through its parent task*; its RLS joins through
--      `tasks` with auth.uid() wrapped in a scalar subselect so Postgres
--      evaluates it once per statement (initplan) rather than once per row.
--
-- Audience decision (fixed with the user): when a reminder fires, EVERYONE on
-- the chore's farm who has push enabled is notified, on all their devices — the
-- Edge Function fans a due reminder out to every push_subscriptions row of every
-- farm member. There is no per-user opt-in-per-chore; enabling push on a device
-- opts that device into the farm's reminders.
--
-- Scheduler: pg_cron runs `public.invoke_send_reminders()` every minute; that
-- function (security definer) reads two Vault secrets and, only when both exist
-- AND at least one reminder is actually due, fires a pg_net POST to the Edge
-- Function. Missing secrets => no-op (so `supabase db reset` and fresh, unwired
-- environments apply this migration cleanly instead of erroring every minute).

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
-- Both are bundled with Supabase's Postgres image (and toggleable in the
-- dashboard). `if not exists` makes this idempotent whether or not they were
-- already enabled. pg_cron lives in pg_catalog on current Supabase projects;
-- pg_net exposes its API under the `net` schema regardless of where its
-- extension objects land.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net;

-- ---------------------------------------------------------------------------
-- push_subscriptions
-- ---------------------------------------------------------------------------

create table push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- The push service endpoint URL — globally unique so a device re-subscribing
  -- (same browser, refreshed keys) collides here and upserts on `endpoint`
  -- rather than accumulating stale duplicates.
  endpoint text not null unique,
  -- The two client-generated encryption params the Web Push protocol needs to
  -- encrypt a payload for this subscription (RFC 8291): the P-256 ECDH public
  -- key and the auth secret. Not credentials to anything else; just this
  -- subscription's crypto material.
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);

-- The Edge Function loads a user's subscriptions by user_id when fanning out.
create index push_subscriptions_user_id_idx on push_subscriptions (user_id);

-- ---------------------------------------------------------------------------
-- push_subscriptions — Row Level Security
-- ---------------------------------------------------------------------------
-- Owner-only: a subscription is a personal device credential, not farm data, so
-- (unlike the farm-scoped tables) it is NOT reachable via farm membership — only
-- the owning user can see or mutate their own rows. The Edge Function reads
-- across users via the service role, which bypasses RLS.

alter table push_subscriptions enable row level security;

create policy "users can access their own push subscriptions"
on push_subscriptions for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- task_reminders
-- ---------------------------------------------------------------------------

create table task_reminders (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  -- The instant the reminder should fire. The every-minute scan claims rows
  -- with remind_at <= now() and sent_at is null.
  remind_at timestamptz not null,
  -- Attribution only (who set the reminder); not used for access control, which
  -- is farm-membership-based via the parent task. Nullable + no cascade delete
  -- so a departed member's reminders survive with a null author, matching how
  -- other attribution columns treat auth.users references loosely.
  created_by uuid references auth.users (id),
  -- Stamped by the Edge Function when the reminder is claimed for delivery.
  -- Null = not yet sent; the partial index below is the hot due-scan path.
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

create index task_reminders_task_id_idx on task_reminders (task_id);

-- The every-minute due-scan (and the cheap exists-check in
-- invoke_send_reminders) only ever look at unsent reminders ordered by
-- remind_at; a partial index over just those keeps that scan tiny as sent
-- history accumulates.
create index task_reminders_due_idx
  on task_reminders (remind_at)
  where sent_at is null;

-- ---------------------------------------------------------------------------
-- task_reminders — Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership. task_reminders carries
-- no farm_id; scope through the parent task (mirrors task_completers /
-- task_tags / task_tools / task_photos). auth.uid() wrapped in a scalar
-- subselect so it's evaluated once per statement, not once per row.

alter table task_reminders enable row level security;

create policy "farm members can access their farm's task reminders"
on task_reminders for all
to authenticated
using (
  task_id in (
    select t.id from tasks t
    where t.farm_id in (
      select farm_id from farm_memberships
      where user_id = (select auth.uid())
    )
  )
)
with check (
  task_id in (
    select t.id from tasks t
    where t.farm_id in (
      select farm_id from farm_memberships
      where user_id = (select auth.uid())
    )
  )
);

-- ---------------------------------------------------------------------------
-- invoke_send_reminders() — the per-minute cron entrypoint
-- ---------------------------------------------------------------------------
-- Reads the project URL and the shared cron secret from Vault, and — only if
-- both are configured AND there is at least one due, unsent reminder — POSTs to
-- the Edge Function with the secret in the `x-cron-secret` header. The
-- exists-check keeps the every-minute job from making a pointless HTTP call
-- (and waking the Edge Function) when nothing is due, which is the common case.
--
-- Security definer so it can read `vault.decrypted_secrets` and `net.http_post`
-- regardless of the (nonexistent) caller — cron runs it as the table owner. It
-- takes no caller input and is revoked from all client roles below, so there is
-- no injection surface. Empty search_path => everything is schema-qualified.
--
-- Missing secrets => silent return (not an error): a fresh `db reset` or an
-- environment that hasn't had Vault wired yet still applies this migration and
-- runs the cron job harmlessly every minute until secrets are set.

create function public.invoke_send_reminders()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project_url text;
  v_secret text;
begin
  select decrypted_secret into v_project_url
  from vault.decrypted_secrets
  where name = 'project_url';

  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'send_reminders_secret';

  -- Not wired up yet — do nothing rather than error every minute.
  if v_project_url is null or v_secret is null then
    return;
  end if;

  -- Cheap guard: skip the HTTP round-trip entirely unless something is due.
  if not exists (
    select 1 from public.task_reminders
    where sent_at is null
      and remind_at <= now()
  ) then
    return;
  end if;

  perform net.http_post(
    url := v_project_url || '/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', v_secret
    ),
    body := '{}'::jsonb
  );
end;
$$;

-- Only cron (running as the function owner) ever calls this; no client role
-- should be able to trigger an outbound POST.
revoke all on function public.invoke_send_reminders() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Cron schedule
-- ---------------------------------------------------------------------------
-- Every minute. Wrapped in a DO/exception block so the migration still applies
-- in environments where pg_cron is unavailable (e.g. a bare Postgres without
-- the extension) — there the schedule is simply skipped with a notice instead
-- of failing the whole migration. cron.schedule upserts by job name, so
-- re-running is safe.

do $$
begin
  perform cron.schedule(
    'send-reminders',
    '* * * * *',
    $cron$select public.invoke_send_reminders()$cron$
  );
exception
  when undefined_function or undefined_table or invalid_schema_name
    or insufficient_privilege then
    raise notice 'pg_cron unavailable; skipped scheduling send-reminders';
end;
$$;
