-- Activity log actor attribution
-- `activity_log.actor_user_id` references `auth.users`, which isn't exposed
-- via PostgREST — the app has had no way to turn an actor id into a display
-- name/email. This view exposes just enough of `auth.users` (id, email) to
-- attribute log entries to a person, scoped to farms the querying user
-- shares membership with (see docs/DECISIONS.md).

-- `security_invoker = true` runs the view under the querying user's own RLS
-- rather than the view owner's, so it's exactly as permissive as
-- `farm_memberships`' existing "users can view their own memberships" policy
-- already is — no separate grant/policy needed on the view itself. Views
-- can't carry their own `create policy`, so this is the equivalent
-- mechanism for a view that a farm-scoped RLS policy is for a table.
create view farm_member_profiles
with (security_invoker = true) as
select
  fm.farm_id,
  u.id as user_id,
  u.email
from farm_memberships fm
join auth.users u on u.id = fm.user_id;
