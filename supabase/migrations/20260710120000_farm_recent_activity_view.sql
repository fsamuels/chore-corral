-- Farm recent-activity view
--
-- Powers the default-farm fallback: when a user has no saved farm selection
-- yet (new device/browser, or the saved selection is no longer a valid
-- membership), the app picks whichever of their farms has the most recent
-- task activity instead of the alphabetically-first one.
--
-- security_invoker is safe here — unlike farm_member_profiles' abandoned
-- security_invoker attempt (see migration 20260704190000 and
-- docs/DECISIONS.md), this view only reads `tasks`, and `authenticated`
-- already holds an ordinary table-level grant on `tasks` (the app queries it
-- directly everywhere else). The view simply inherits tasks' existing
-- farm-membership RLS, with no extra scoping needed in the view definition.
create view farm_recent_activity
with (security_invoker = true) as
select
  farm_id,
  max(greatest(created_at, coalesce(completed_at, created_at))) as last_activity_at
from tasks
group by farm_id;

grant select on farm_recent_activity to authenticated;
