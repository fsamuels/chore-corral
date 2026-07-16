-- Multi-person completion attribution: who actually did the work, now a set
-- rather than a single credit. Replaces the two scalar columns
-- `tasks.completed_by` / `tasks.completed_by_name` (added
-- 20260712120000_task_completed_by.sql) with a `task_completers` join table,
-- so a task can be credited to any number of people — a mix of app members and
-- free-text names for whoever finished the task but isn't an app user (a
-- contractor, a kid, a neighbor).
--
-- Per-ROW XOR: each completer row is either a member (`user_id`, FK ->
-- auth.users, like `tasks.created_by`) OR a free-text name (`completer_name`),
-- never both and never neither — a CHECK enforces it, and the app layer
-- (`assertValidCompleters` in services/completers.ts) enforces the same rule up
-- front so a bad combination fails with a readable message before the Postgres
-- constraint fires. Mixing within one task's set is allowed: only the per-row
-- rule is constrained, not the composition of the set. Two partial unique
-- indexes keep a task from listing the same member twice or the same free-text
-- name twice.
--
-- Scoped through the parent task, exactly like task_tags / task_tools /
-- task_photos — no farm_id column; RLS reaches farm_memberships via tasks.
-- auth.uid() is wrapped in a scalar subselect so Postgres evaluates it once per
-- statement (initplan) instead of once per row.
--
-- Auto-credit behavior (unchanged in spirit, generalized to a set — see
-- services/tasks.ts changeTaskStatus and docs/DECISIONS.md): marking a task
-- done credits the acting member ONLY IF the task has no completers yet;
-- leaving done clears the whole set. Attribution stays optional (a done task
-- may legitimately have zero completers).

create table task_completers (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  user_id uuid references auth.users (id),
  completer_name text,
  -- Per-row XOR: exactly one of user_id / completer_name is set.
  check ((user_id is null) <> (completer_name is null))
);

create index task_completers_task_id_idx on task_completers (task_id);

-- No duplicate member, and no duplicate free-text name, within one task's set.
-- Partial indexes because each covers only the rows whose relevant column is
-- non-null (the other kind of row has a null there and is irrelevant).
create unique index task_completers_task_user_uniq
  on task_completers (task_id, user_id)
  where user_id is not null;

create unique index task_completers_task_name_uniq
  on task_completers (task_id, completer_name)
  where completer_name is not null;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership. task_completers carries
-- no farm_id; scope through the parent task (mirrors task_tags / task_tools /
-- task_photos).

alter table task_completers enable row level security;

create policy "farm members can access their farm's task completers"
on task_completers for all
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
-- Backfill from the columns being retired, then drop them.
-- ---------------------------------------------------------------------------
-- One row per non-null attribution; the old XOR CHECK guaranteed at most one of
-- the two was ever set on a given task, so these two inserts never collide.

insert into task_completers (task_id, user_id, completer_name)
select id, completed_by, null from tasks where completed_by is not null;

insert into task_completers (task_id, user_id, completer_name)
select id, null, completed_by_name from tasks where completed_by_name is not null;

alter table tasks drop constraint tasks_completed_by_xor_name;
alter table tasks drop column completed_by;
alter table tasks drop column completed_by_name;
