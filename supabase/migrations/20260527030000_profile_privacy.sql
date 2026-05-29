-- ============================================================
-- المهندس — Instagram-style profile privacy.
--
-- Adds a per-profile `is_private` flag and enforces it on posts via
-- RLS: a private profile's posts are visible only to the owner and
-- to accepted connections. Public profiles stay visible to everyone
-- (including the home feed), exactly as before.
-- ============================================================

-- 1. Privacy flag. Defaults to public so nothing changes for existing
--    accounts until a user opts into private.
alter table public.profiles
  add column if not exists is_private boolean not null default false;

-- 2. Helper: may the current auth user see the gated content (posts) of
--    the given profile? security definer so it can read connection rows
--    regardless of their own RLS.
create or replace function public.can_view_profile_content(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    -- public profile → visible to everyone
    coalesce(
      (select not is_private from public.profiles where id = p_profile_id),
      true
    )
    -- or I am the owner
    or exists (
      select 1 from public.profiles
       where id = p_profile_id and user_id = auth.uid()
    )
    -- or I am an accepted connection (either direction)
    or exists (
      select 1
        from public.connection_requests cr
        join public.profiles me on me.user_id = auth.uid()
       where cr.status = 'accepted'
         and (
              (cr.requester_profile_id = p_profile_id and cr.receiver_profile_id = me.id)
           or (cr.receiver_profile_id = p_profile_id and cr.requester_profile_id = me.id)
         )
    );
$$;

revoke all on function public.can_view_profile_content(uuid) from public;
grant execute on function public.can_view_profile_content(uuid) to anon, authenticated;

-- 3. Replace the broad "everyone can read" SELECT policies on posts with a
--    privacy-aware one. The owner still sees all of their own posts
--    (including archived); everyone else sees only active posts of profiles
--    they're allowed to view.
drop policy if exists "Posts are publicly readable" on public.posts;
drop policy if exists "Posts are viewable by everyone" on public.posts;
drop policy if exists "Posts viewable - active for all, all for owner" on public.posts;

create policy "Posts visible per profile privacy" on public.posts
for select using (
  -- owner sees everything they posted
  profile_id in (
    select id from public.profiles where user_id = auth.uid()
  )
  or (
    (((is_archived = false) or (is_archived is null)) and (is_active = true))
    and public.can_view_profile_content(profile_id)
  )
);
