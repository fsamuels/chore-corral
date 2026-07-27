-- Public task-count stat
--
-- Two needs landed on the same solution: the login page (unauthenticated)
-- wants a bit of social proof ("X chores tracked"), and the project's
-- Supabase free-tier project needs at least one query a week or risks being
-- paused for inactivity. `get_public_task_count()` serves both — the login
-- page calls it client-side, and an external weekly cron (e.g. a curl from
-- a Raspberry Pi, using the anon key) can call the same RPC endpoint purely
-- to keep the project warm. See DECISIONS.md for why this is safe to expose
-- to `anon` despite RLS being deny-by-default everywhere else.
--
-- Security definer, not a relaxed RLS policy on `tasks`: the existing
-- farm-membership policy on `tasks` stays `to authenticated` only (see
-- 20260702154910_m2_schema_and_rls.sql) — `anon` still can't read a single
-- task row. This function only ever returns one aggregate integer, never
-- row data, so it can't leak task titles, farm identity, or anything else.

create function get_public_task_count()
returns bigint
language sql
security definer
set search_path = ''
stable
as $$
  select count(*) from public.tasks;
$$;

revoke all on function get_public_task_count() from public, anon, authenticated;
grant execute on function get_public_task_count() to anon, authenticated;
