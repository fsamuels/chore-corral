-- Optional user-entered time estimate on tasks: how long the creator/editor
-- expects the task to take, in whole minutes, set at create/edit time. Purely
-- a plan-ahead estimate — a future, separate feature will add an "actual"
-- counterpart (measured via timer), which will sit next to this as an obvious
-- sibling column (e.g. actual_minutes) using the same integer-minutes unit.
--
-- Nullable with no default and no backfill: existing tasks simply have no
-- estimate (null), and null stays the "unset" sentinel going forward. A CHECK
-- keeps the value positive when present (null passes the check, so unset rows
-- are unaffected). Rides on the tasks table's existing farm-membership RLS
-- policy ("farm members can access their farm's tasks", for all) — a new
-- column on an already-policied table needs no RLS or index change.

alter table tasks
  add column estimated_minutes integer
    check (estimated_minutes is null or estimated_minutes > 0);
