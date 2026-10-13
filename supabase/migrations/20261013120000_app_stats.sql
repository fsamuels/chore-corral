-- App-wide stats for the About page
--
-- The About page shows a few "how big has this gotten" totals across every
-- farm: farms, accounts, chores, photos, time tracked, and so on. RLS only
-- lets a user see their own farms' rows, so — same approach as
-- get_public_task_count() (20260727120000_public_task_count.sql) — this is a
-- `security definer` function that returns aggregate counts only: no row
-- data, no farm names, no user identity.
--
-- Unlike get_public_task_count(), it's granted to `authenticated` only: the
-- About page sits behind sign-in, and the account total (`auth.users`) isn't
-- something to hand to anonymous callers.

create function get_app_stats()
returns table (
  farms bigint,
  accounts bigint,
  chores bigint,
  chores_done bigint,
  completions bigint,
  photos bigint,
  tracked_seconds bigint,
  categories bigint,
  locations bigint,
  tags bigint,
  shopping_items bigint,
  tools bigint,
  activity_events bigint,
  first_chore_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    (select count(*) from public.farms),
    (select count(*) from auth.users),
    (select count(*) from public.tasks),
    (select count(*) from public.tasks where status = 'done'),
    (select count(*) from public.task_completers),
    (select count(*) from public.task_photos),
    (select coalesce(
       sum(extract(epoch from (ended_at - started_at)))::bigint, 0)
       from public.task_time_entries
      where ended_at is not null),
    (select count(*) from public.categories where deleted_at is null),
    (select count(*) from public.locations where deleted_at is null),
    (select count(*) from public.tags),
    (select count(*) from public.task_shopping_items),
    (select count(*) from public.task_tools),
    (select count(*) from public.activity_log),
    (select min(created_at) from public.tasks);
$$;

revoke all on function get_app_stats() from public, anon, authenticated;
grant execute on function get_app_stats() to authenticated;
