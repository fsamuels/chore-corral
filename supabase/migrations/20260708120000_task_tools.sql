-- Optional per-task tool list: tools needed to do a task (e.g. chainsaw,
-- post driver), each independently checkable. Scoped through the parent
-- task, exactly like task_shopping_items — no farm_id column; RLS reaches
-- farm_memberships via tasks. Deliberately a separate table from
-- task_shopping_items per ROADMAP.md/DECISIONS.md — not unified.

create table task_tools (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  name text not null,
  checked boolean not null default false,
  created_at timestamptz not null default now()
);

create index task_tools_task_id_idx on task_tools (task_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership. task_tools carries no
-- farm_id; scope through the parent task (mirrors task_shopping_items /
-- task_tags / task_photos). auth.uid() is wrapped in a scalar subselect so
-- Postgres evaluates it once per statement (initplan) instead of once per
-- row.

alter table task_tools enable row level security;

create policy "farm members can access their farm's task tools"
on task_tools for all
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
