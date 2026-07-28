-- Chore assignment: who a chore is assigned to, distinct from who completed
-- it (task_completers). Members only — no free-text names, since a
-- free-text assignee can't receive a push notification or sign in (see
-- docs/ROADMAP.md's chore-assignment entry). Assignment does not gate
-- anything: any farm member can still edit/complete any chore, consistent
-- with the existing equal-access role decision. It's purely informational
-- plus reminder-notification audience targeting (see
-- supabase/functions/send-reminders).
--
-- Patterned on task_tags (composite PK, no surrogate id) rather than
-- task_completers (which needs a surrogate id to allow a free-text row
-- alongside a member row) — every row here is a member, so (task_id,
-- user_id) alone is enough to be both the PK and the natural
-- no-duplicate-assignee constraint.
--
-- Scoped through the parent task, exactly like task_tags / task_completers —
-- no farm_id column; RLS reaches farm_memberships via tasks. auth.uid() is
-- wrapped in a scalar subselect so Postgres evaluates it once per statement
-- (initplan) instead of once per row.

create table task_assignees (
  task_id uuid not null references tasks (id) on delete cascade,
  user_id uuid not null references auth.users (id),
  primary key (task_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership, mirroring
-- task_completers' policy.

alter table task_assignees enable row level security;

create policy "farm members can access their farm's task assignees"
on task_assignees for all
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
