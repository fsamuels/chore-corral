-- Task time tracking: one row per start/stop timer session. A running
-- timer is a row with ended_at IS NULL. Actual time per task is derived
-- (sum of ended_at - started_at) — deliberately no denormalized
-- actual_minutes column on tasks to keep in sync. Scoped through the
-- parent task like task_tools/task_shopping_items — no farm_id column;
-- RLS reaches farm_memberships via tasks.

create table task_time_entries (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  user_id uuid not null references auth.users (id),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  constraint task_time_entries_ends_after_start
    check (ended_at is null or ended_at > started_at)
);

create index task_time_entries_task_id_idx on task_time_entries (task_id);

-- One running timer per user, farm-wide (the Toggl model: starting a timer
-- elsewhere auto-stops the current one in application code; this index is
-- the backstop against races leaving two running).
create unique index task_time_entries_one_running_per_user
  on task_time_entries (user_id)
  where ended_at is null;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership through the parent
-- task (mirrors task_tools / task_shopping_items / task_tags / task_photos).
-- auth.uid() is wrapped in a scalar subselect so Postgres evaluates it once
-- per statement (initplan) instead of once per row.

alter table task_time_entries enable row level security;

create policy "farm members can access their farm's task time entries"
on task_time_entries for all
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
