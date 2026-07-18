-- Member display names
--
-- The app has attributed everything (completed-by pills, activity log,
-- members page) to raw email addresses because `farm_member_profiles` only
-- exposed `email`. Google sign-in already gives us a human name: GoTrue
-- copies the provider's profile into `auth.users.raw_user_meta_data`
-- (`full_name` / `name`) on first sign-in and refreshes it from the
-- provider's claims on every subsequent sign-in — so the value is already
-- stored for every member (membership only ever exists after at least one
-- Google sign-in) and stays current without any app-side capture step.
--
-- Recreate the view with a `display_name` column sourced from that
-- metadata: `full_name` first (Google's canonical key), `name` as fallback
-- (some providers/older records only set it), blank-trimmed to null so the
-- app has a single "no name" case to fall back to email from. Same
-- owner-rights + security_barrier + in-view membership scoping shape as
-- 20260718120000 (see that migration and DECISIONS.md for why).

drop view if exists farm_member_profiles;

create view farm_member_profiles
with (security_barrier = true) as
select
  fm.farm_id,
  u.id as user_id,
  u.email,
  coalesce(
    nullif(btrim(u.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(u.raw_user_meta_data ->> 'name'), '')
  ) as display_name,
  fm.role
from farm_memberships fm
join auth.users u on u.id = fm.user_id
where fm.farm_id in (
  select farm_id from farm_memberships
  where user_id = (select auth.uid())
);

revoke all on farm_member_profiles from public, anon;
grant select on farm_member_profiles to authenticated;
