-- Fix "permission denied for table users" on farm_member_profiles
--
-- The previous migration created this view with `security_invoker = true`,
-- reasoning that it made the view exactly as permissive as farm_memberships'
-- RLS with no extra grants needed. That was wrong on two counts:
--
-- 1. Under security_invoker, plain table-level GRANTs on the underlying
--    tables apply to the querying user too — and `authenticated` has no
--    SELECT grant on `auth.users` (deliberately; it's why auth.users isn't
--    exposed via PostgREST). Every select on the view failed with
--    "permission denied for table users".
-- 2. Even if such a grant existed, farm_memberships' "users can view their
--    own memberships" policy means the view could only ever return the
--    caller's own row — never the *other* farm members the activity log
--    needs to attribute entries to.
--
-- Recreate the view with default (owner-rights) execution: the owner can
-- read auth.users and isn't subject to farm_memberships' RLS, and the
-- membership scoping moves into the view definition itself — callers see
-- members of farms they belong to, and nothing else. security_barrier stops
-- the planner from evaluating caller-supplied (potentially leaky) predicates
-- before that scoping filter.

drop view if exists farm_member_profiles;

create view farm_member_profiles
with (security_barrier = true) as
select
  fm.farm_id,
  u.id as user_id,
  u.email
from farm_memberships fm
join auth.users u on u.id = fm.user_id
where fm.farm_id in (
  select farm_id from farm_memberships
  where user_id = (select auth.uid())
);

-- Owner-rights view over auth data: keep the audience tight. anon gets
-- nothing (auth.uid() is null for it anyway); authenticated gets read-only.
revoke all on farm_member_profiles from public, anon;
grant select on farm_member_profiles to authenticated;
