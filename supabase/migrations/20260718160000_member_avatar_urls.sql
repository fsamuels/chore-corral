-- Member avatar URLs
--
-- Companion to 20260718150000 (display names): expose the Google profile
-- picture the same way, so member lists and pickers can show a face next to
-- the name. GoTrue stores it in `auth.users.raw_user_meta_data` under
-- `avatar_url` (Supabase's normalized key) with `picture` as the raw OIDC
-- claim fallback, refreshed on every sign-in like the name. Same
-- owner-rights + security_barrier + in-view membership scoping shape as the
-- last two recreations.

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
  coalesce(
    nullif(btrim(u.raw_user_meta_data ->> 'avatar_url'), ''),
    nullif(btrim(u.raw_user_meta_data ->> 'picture'), '')
  ) as avatar_url,
  fm.role
from farm_memberships fm
join auth.users u on u.id = fm.user_id
where fm.farm_id in (
  select farm_id from farm_memberships
  where user_id = (select auth.uid())
);

revoke all on farm_member_profiles from public, anon;
grant select on farm_member_profiles to authenticated;
