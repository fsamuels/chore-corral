-- accept_farm_invites(): match only a verified email
--
-- The original function (20260718120000) matched pending invites against the
-- JWT's `email` claim, assuming it was always a Google-verified address. It
-- wasn't: with email/password signup enabled and confirmations off (both
-- pushed to the hosted project from config.toml), anyone could sign up with an
-- invitee's address, get a session immediately, and call this function to join
-- that farm at the invited role. See DECISIONS.md.
--
-- config.toml now disables email signup, but this function shouldn't depend on
-- auth settings staying that way. It now reads the caller's email from
-- auth.users and only when `email_confirmed_at` is set — GoTrue sets that for
-- Google sign-ins (Google asserts email_verified) and for admin-created users
-- with email_confirm, but never for an unconfirmed email signup. Everything
-- else is unchanged; `create or replace` keeps the existing grants.

create or replace function accept_farm_invites()
returns setof uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  user_email text;
begin
  if uid is null then
    return;
  end if;

  select lower(btrim(u.email)) into user_email
  from auth.users u
  where u.id = uid
    and u.email_confirmed_at is not null;

  if user_email is null or user_email = '' then
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
