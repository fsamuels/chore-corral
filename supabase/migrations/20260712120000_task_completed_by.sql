-- Optional completion attribution on tasks: who actually did the work. Two
-- nullable columns, set/cleared by app code alongside `completed_at` — when a
-- task moves to done the app records the acting member in `completed_by`, and
-- clears it again when the task leaves done. `completed_by_name` is a
-- free-text fallback for whoever finished the task but isn't an app user (a
-- contractor, a kid, a neighbor), captured after the fact via a plain edit.
--
-- At most one is ever set: a task is credited to a member OR to a free-text
-- name, never both (both-null is fine — attribution is optional). A CHECK
-- enforces that; the app layer (`assertCompletedByXorName`) enforces the same
-- rule up front so a bad combination fails with a readable message. Nullable,
-- no default, no backfill — existing tasks simply have no attribution. Rides
-- on the tasks table's existing farm-membership RLS policy, so a new column on
-- an already-policied table needs no RLS or index change.

alter table tasks
  add column completed_by uuid references auth.users (id);

alter table tasks
  add column completed_by_name text;

alter table tasks
  add constraint tasks_completed_by_xor_name
    check (completed_by is null or completed_by_name is null);
