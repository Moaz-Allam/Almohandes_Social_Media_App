-- ============================================================
-- المهندس — private profiles: posts visible to followers too.
--
-- A private profile's posts are visible only to the owner, accepted
-- connections, and FOLLOWERS. Everyone else cannot see them in the
-- feed or on the profile. Public profiles stay visible to all.
-- ============================================================

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
    -- owner
    or exists (
      select 1 from public.profiles
       where id = p_profile_id and user_id = auth.uid()
    )
    -- accepted connection (either direction)
    or exists (
      select 1
        from public.connection_requests cr
        join public.profiles me on me.user_id = auth.uid()
       where cr.status = 'accepted'
         and (
              (cr.requester_profile_id = p_profile_id and cr.receiver_profile_id = me.id)
           or (cr.receiver_profile_id = p_profile_id and cr.requester_profile_id = me.id)
         )
    )
    -- follower (viewer follows the private profile)
    or exists (
      select 1
        from public.followers f
        join public.profiles me on me.user_id = auth.uid()
       where f.following_id = p_profile_id
         and f.follower_id = me.id
    );
$$;

revoke all on function public.can_view_profile_content(uuid) from public;
grant execute on function public.can_view_profile_content(uuid) to anon, authenticated;
