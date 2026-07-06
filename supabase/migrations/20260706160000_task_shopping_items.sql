-- Optional per-task shopping list: items to buy for a task (parts, supplies),
-- each independently checkable. Scoped through the parent task, exactly like
-- task_tags/task_photos — no farm_id column; RLS reaches farm_memberships via
-- tasks.

create table task_shopping_items (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  name text not null,
  checked boolean not null default false,
  created_at timestamptz not null default now()
);

create index task_shopping_items_task_id_idx on task_shopping_items (task_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership. task_shopping_items
-- carries no farm_id; scope through the parent task (mirrors task_tags /
-- task_photos). auth.uid() is wrapped in a scalar subselect so Postgres
-- evaluates it once per statement (initplan) instead of once per row.

alter table task_shopping_items enable row level security;

create policy "farm members can access their farm's task shopping items"
on task_shopping_items for all
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
