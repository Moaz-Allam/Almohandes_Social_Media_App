-- ============================================================
-- المهندس — expose the author's governorate in the home feed.
--
-- The feed card showed a hardcoded "بغداد" for every post because
-- `get_home_feed` never returned the author's governorate. Add a
-- `governorate text` column (the enum cast to text, e.g. 'baghdad') so the
-- client can render the real location. Adding a column changes the RETURNS
-- TABLE type, which `create or replace` can't do, so we drop + recreate and
-- restore the authenticated-only grant from the privacy-hardening migration.
-- ============================================================

drop function if exists public.get_home_feed(uuid, integer, integer);

create function public.get_home_feed(
  p_profile_id uuid,
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  post_id uuid,
  content text,
  image_url text,
  post_type text,
  likes_count integer,
  comments_count integer,
  created_at timestamptz,
  repost_of_post_id uuid,
  repost_original_profile_id uuid,
  repost_original_name text,
  profile_id uuid,
  full_name text,
  username text,
  avatar_url text,
  role public.user_role,
  governorate text,
  is_verified boolean,
  is_liked boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    p.id as post_id,
    p.content,
    p.image_url,
    p.post_type,
    p.likes_count,
    p.comments_count,
    p.created_at,
    p.repost_of_post_id,
    p.repost_original_profile_id,
    p.repost_original_name,
    pr.id as profile_id,
    pr.full_name,
    pr.username,
    pr.avatar_url,
    pr.role,
    pr.governorate::text as governorate,
    pr.is_verified,
    exists(
      select 1
      from public.post_likes pl
      where pl.post_id = p.id
        and pl.profile_id = p_profile_id
    ) as is_liked
  from public.posts p
  join public.profiles pr on pr.id = p.profile_id
  left join public.blocked_users bu on
    (bu.blocker_id = p_profile_id and bu.blocked_id = p.profile_id)
    or (bu.blocker_id = p.profile_id and bu.blocked_id = p_profile_id)
  where p.is_active = true
    and (p.is_archived = false or p.is_archived is null)
    and bu.id is null
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

revoke execute on function public.get_home_feed(uuid, integer, integer)
  from public, anon;
grant execute on function public.get_home_feed(uuid, integer, integer)
  to authenticated, service_role;
