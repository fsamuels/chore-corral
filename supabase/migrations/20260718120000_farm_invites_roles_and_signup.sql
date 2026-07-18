-- Farm invites, membership roles, and self-serve farm creation
--
-- Opens the app up beyond manually-provisioned memberships (SPEC.md's
-- original MVP scoping):
--
--   1. `farm_memberships.role` (owner/member) — owners manage invites;
--      task-level access stays equal for every member. Existing members are
--      backfilled as owners (they were provisioned by hand and are the de
--      facto owners of their farms).
--   2. `farm_invites` — email pre-authorization: an owner records an email
--      address, and whoever signs in with Google using that address is
--      auto-joined via accept_farm_invites(). No emails are sent; Google
--      remains the only sign-in method.
--   3. create_farm() — any authenticated user can create a farm and becomes
--      its owner, which turns an uninvited Google sign-in into self-serve
--      signup instead of a dead end.
--
-- Membership rows are only ever written by the two security-definer
-- functions below (and the dashboard); there are still no client-side
-- INSERT/UPDATE/DELETE policies on farm_memberships or farms.

-- ---------------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------------

create type farm_role as enum ('owner', 'member');

alter table farm_memberships
  add column role farm_role not null default 'member';

-- Everyone provisioned before this migration was added by hand and acts as
-- an owner of their farms (SPEC.md: all members have equal, full access).
update farm_memberships set role = 'owner';

-- ---------------------------------------------------------------------------
-- farm_invites
-- ---------------------------------------------------------------------------

create table farm_invites (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id),
  -- Stored trimmed + lowercased (the app normalizes before insert; the
  -- checks are the backstop) so the accept-time match against the Google
  -- account's email is a plain equality.
  email text not null,
  role farm_role not null default 'member',
  invited_by uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  accepted_by uuid references auth.users (id),
  constraint farm_invites_email_normalized
    check (email = lower(btrim(email))),
  constraint farm_invites_email_shape
    check (position('@' in email) > 1 and char_length(email) <= 320),
  -- accepted_at/accepted_by travel together: both null (pending) or both set.
  constraint farm_invites_accepted_pair
    check ((accepted_at is null) = (accepted_by is null))
);

create index farm_invites_farm_id_idx on farm_invites (farm_id);

-- accept_farm_invites() looks up pending invites by email on every fresh
-- session; keep that lookup off a sequential scan.
create index farm_invites_pending_email_idx
  on farm_invites (email)
  where accepted_at is null;

-- At most one pending invite per (farm, email); accepted invites stay as
-- history and don't block re-inviting (e.g. after a member is removed).
create unique index farm_invites_farm_email_pending_uniq
  on farm_invites (farm_id, email)
  where accepted_at is null;

alter table farm_invites enable row level security;

-- Owners manage their farm's invites. The subquery only ever needs the
-- caller's own membership rows, which farm_memberships' RLS already allows.
create policy "farm owners can view their farm's invites"
on farm_invites for select
to authenticated
using (
  farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid()) and role = 'owner'
  )
);

create policy "farm owners can create invites for their farm"
on farm_invites for insert
to authenticated
with check (
  farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid()) and role = 'owner'
  )
  and invited_by = (select auth.uid())
  and accepted_at is null
);

-- Revocation = deleting a *pending* invite. Accepted invites are history and
-- can't be deleted from the client. No UPDATE policy at all — acceptance
-- happens exclusively inside accept_farm_invites() (security definer).
create policy "farm owners can revoke their farm's pending invites"
on farm_invites for delete
to authenticated
using (
  accepted_at is null
  and farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid()) and role = 'owner'
  )
);

-- ---------------------------------------------------------------------------
-- accept_farm_invites()
-- ---------------------------------------------------------------------------
-- Called by the app once per session after sign-in: joins the caller to
-- every farm with a pending invite matching their (verified, Google-issued)
-- email, marks those invites accepted, and returns the farm ids joined.
-- Security definer because the caller can't write farm_memberships (or see
-- farm_invites) under RLS; scoping comes from auth.uid()/the JWT email, not
-- from anything caller-supplied.

create function accept_farm_invites()
returns setof uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  user_email text := lower(btrim(coalesce(
    (select auth.jwt() ->> 'email'), ''
  )));
begin
  if uid is null or user_email = '' then
    return;
  end if;

  return query
  with pending as (
    select id, farm_id, role
    from public.farm_invites
    where accepted_at is null
      and email = user_email
    for update skip locked
  ),
  added as (
    -- Membership may already exist (e.g. provisioned by hand after the
    -- invite was created) — the invite still gets marked accepted below.
    insert into public.farm_memberships (farm_id, user_id, role)
    select p.farm_id, uid, p.role
    from pending p
    on conflict (farm_id, user_id) do nothing
  ),
  marked as (
    update public.farm_invites fi
    set accepted_at = now(), accepted_by = uid
    from pending p
    where fi.id = p.id
    returning fi.farm_id
  )
  select m.farm_id from marked m;
end;
$$;

revoke all on function accept_farm_invites() from public, anon;
grant execute on function accept_farm_invites() to authenticated;

-- ---------------------------------------------------------------------------
-- create_farm()
-- ---------------------------------------------------------------------------
-- Self-serve farm creation: inserts the farm and the caller's owner
-- membership atomically and returns the new farm's id. Security definer for
-- the same reason as above — neither table accepts client-side writes.

create function create_farm(farm_name text, farm_address text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  trimmed_name text := btrim(coalesce(farm_name, ''));
  new_farm_id uuid;
begin
  if uid is null then
    raise exception 'must be signed in to create a farm';
  end if;
  if trimmed_name = '' or char_length(trimmed_name) > 120 then
    raise exception 'farm name must be between 1 and 120 characters';
  end if;

  insert into public.farms (name, address)
  values (trimmed_name, nullif(btrim(coalesce(farm_address, '')), ''))
  returning id into new_farm_id;

  insert into public.farm_memberships (farm_id, user_id, role)
  values (new_farm_id, uid, 'owner');

  return new_farm_id;
end;
$$;

revoke all on function create_farm(text, text) from public, anon;
grant execute on function create_farm(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- farm_member_profiles: expose the membership role
-- ---------------------------------------------------------------------------
-- Same owner-rights + security_barrier + in-view scoping shape as
-- 20260704190000 (see that migration and DECISIONS.md for why), now with
-- `role` so the members page can label owners.

drop view if exists farm_member_profiles;

create view farm_member_profiles
with (security_barrier = true) as
select
  fm.farm_id,
  u.id as user_id,
  u.email,
  fm.role
from farm_memberships fm
join auth.users u on u.id = fm.user_id
where fm.farm_id in (
  select farm_id from farm_memberships
  where user_id = (select auth.uid())
);

revoke all on farm_member_profiles from public, anon;
grant select on farm_member_profiles to authenticated;
