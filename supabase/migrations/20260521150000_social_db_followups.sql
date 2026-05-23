-- Follow-up to 20260521120000_social_visibility_and_interactions.sql.
--
-- This migration cleans up a duplicate trigger that double-counted
-- follows, makes comment counters honest, notifies users when their
-- comments receive replies, backfills every server-maintained counter,
-- and adds a SELECT policy so private posts are invisible to viewers
-- who aren't connected to the author.
--
-- All blocks are idempotent: re-applying the migration is safe.

------------------------------------------------------------------------------
-- 1. Remove the duplicate followers-count triggers from the previous
--    migration. The remote already ships `update_follower_counts_trigger`,
--    so the new triggers were doubling each insert/delete.
------------------------------------------------------------------------------

drop trigger if exists on_followers_insert_counts on public.followers;
drop trigger if exists on_followers_delete_counts on public.followers;
drop function if exists public.app_followers_after_insert();
drop function if exists public.app_followers_after_delete();

-- Reset the columns to the live, deduplicated truth so any rows that got
-- inflated while the duplicate triggers were active are back to sanity.
update public.profiles p
set followers_count = coalesce((
  select count(*) from public.followers f
  where f.following_id = p.id
), 0),
    following_count = coalesce((
  select count(*) from public.followers f
  where f.follower_id = p.id
), 0);

------------------------------------------------------------------------------
-- 2. Make `posts.comments_count` reflect ONLY top-level comments. Replies
--    are visually nested under their parent, so counting them as separate
--    post comments inflated the badge.
------------------------------------------------------------------------------

create or replace function public.app_notify_on_comment() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
declare
  v_owner uuid;
begin
  if new.target_type = 'reel' then
    select r.profile_id into v_owner
    from public.reels r
    where r.id::text = new.target_id;
  elsif new.target_type = 'project' then
    select p.profile_id into v_owner
    from public.projects p
    where p.id::text = new.target_id;
  else
    select p.profile_id into v_owner
    from public.posts p
    where p.id::text = new.target_id;
  end if;

  -- Only notify the post/reel/project owner for top-level comments;
  -- replies trigger a separate notification to the parent comment's
  -- author (see `app_notify_on_reply`).
  if v_owner is not null
     and v_owner <> new.profile_id
     and new.parent_id is null then
    perform public.app_notify_once(
      v_owner,
      'تعليق جديد',
      'تم إضافة تعليق جديد على منشورك',
      'comment',
      'app://' || new.target_type || '/' || new.target_id
    );
  end if;

  -- Only top-level comments bump the post/reel comment counter; replies
  -- live inside `replies_count` on their parent comment.
  if new.parent_id is null then
    if new.target_type = 'post' then
      update public.posts
      set comments_count = coalesce(comments_count, 0) + 1
      where id::text = new.target_id;
    elsif new.target_type = 'reel' then
      update public.reels
      set comments_count = coalesce(comments_count, 0) + 1
      where id::text = new.target_id;
    end if;
  end if;

  return new;
end;
$$;

-- Mirror trigger for deletes so the counter never gets stuck high after
-- someone removes a comment.
create or replace function public.app_after_comment_delete()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  if old.parent_id is null then
    if old.target_type = 'post' then
      update public.posts
      set comments_count = greatest(coalesce(comments_count, 0) - 1, 0)
      where id::text = old.target_id;
    elsif old.target_type = 'reel' then
      update public.reels
      set comments_count = greatest(coalesce(comments_count, 0) - 1, 0)
      where id::text = old.target_id;
    end if;
  end if;
  return old;
end;
$$;

drop trigger if exists on_app_comment_delete_decrement
  on public.app_comments;
create trigger on_app_comment_delete_decrement
  after delete on public.app_comments
  for each row execute function public.app_after_comment_delete();

------------------------------------------------------------------------------
-- 3. Notify the parent commenter when someone replies to their comment.
------------------------------------------------------------------------------

create or replace function public.app_notify_on_reply()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
declare
  v_parent_owner uuid;
begin
  if new.parent_id is null then
    return new;
  end if;
  select profile_id into v_parent_owner
  from public.app_comments
  where id = new.parent_id;
  if v_parent_owner is not null
     and v_parent_owner <> new.profile_id then
    perform public.app_notify_once(
      v_parent_owner,
      'رد جديد على تعليقك',
      'قام أحدهم بالرد على تعليقك',
      'comment_reply',
      'app://comment/' || new.parent_id::text
    );
  end if;
  return new;
end;
$$;

drop trigger if exists on_app_comment_reply_notify on public.app_comments;
create trigger on_app_comment_reply_notify
  after insert on public.app_comments
  for each row execute function public.app_notify_on_reply();

------------------------------------------------------------------------------
-- 4. Backfill every counter the new schema introduces, so the UI doesn't
--    show stale zeros on rows that already existed before the triggers.
------------------------------------------------------------------------------

-- Top-level comments per post.
update public.posts p
set comments_count = coalesce(sub.value, 0)
from (
  select target_id, count(*) as value
  from public.app_comments
  where target_type = 'post' and parent_id is null
  group by target_id
) sub
where p.id::text = sub.target_id;

-- Top-level comments per reel.
update public.reels r
set comments_count = coalesce(sub.value, 0)
from (
  select target_id, count(*) as value
  from public.app_comments
  where target_type = 'reel' and parent_id is null
  group by target_id
) sub
where r.id::text = sub.target_id;

-- Replies count per parent comment.
update public.app_comments p
set replies_count = coalesce(sub.value, 0)
from (
  select parent_id, count(*) as value
  from public.app_comments
  where parent_id is not null
  group by parent_id
) sub
where p.id = sub.parent_id;

-- Likes count per comment from app_comment_likes.
update public.app_comments p
set likes_count = coalesce(sub.value, 0)
from (
  select comment_id, count(*) as value
  from public.app_comment_likes
  group by comment_id
) sub
where p.id = sub.comment_id;

-- Story likes count = real story_likes + story_reactions, so the legacy
-- counter mirrors what users actually feel about the story.
update public.stories s
set likes_count = coalesce(sub.value, 0)
from (
  select story_id, count(*) as value
  from (
    select story_id from public.story_likes
    union all
    select story_id from public.story_reactions
  ) rows
  group by story_id
) sub
where s.id = sub.story_id;

------------------------------------------------------------------------------
-- 5. Story reaction insert also bumps the legacy `stories.likes_count` so
--    the strip / story card surfaces don't undercount engagement.
------------------------------------------------------------------------------

create or replace function public.app_story_reactions_after_insert()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
declare
  v_owner uuid;
begin
  select profile_id into v_owner
  from public.stories
  where id = new.story_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'تفاعل جديد على قصتك',
      'تفاعل أحدهم مع قصتك ' || new.emoji,
      'story_reaction',
      'app://story/' || new.story_id::text
    );
  end if;

  update public.stories
  set likes_count = coalesce(likes_count, 0) + 1
  where id = new.story_id;

  return new;
end;
$$;

create or replace function public.app_story_reactions_after_delete()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  update public.stories
  set likes_count = greatest(coalesce(likes_count, 0) - 1, 0)
  where id = old.story_id;
  return old;
end;
$$;

drop trigger if exists on_story_reaction_delete on public.story_reactions;
create trigger on_story_reaction_delete
  after delete on public.story_reactions
  for each row execute function public.app_story_reactions_after_delete();

------------------------------------------------------------------------------
-- 6. Post visibility enforcement: a `connections`-only post is selectable
--    only by its author or by viewers who share an accepted connection
--    with the author. Public posts stay visible to everyone (subject to
--    the existing is_active / is_archived rules).
------------------------------------------------------------------------------

drop policy if exists "Posts visibility respects connection scope"
  on public.posts;
create policy "Posts visibility respects connection scope"
  on public.posts for select
  using (
    coalesce(visibility, 'public') = 'public'
    or profile_id in (
      select p.id from public.profiles p where p.user_id = auth.uid()
    )
    or exists (
      select 1
      from public.connection_requests cr
      join public.profiles me on me.user_id = auth.uid()
      where cr.status = 'accepted'
        and (
          (cr.requester_profile_id = posts.profile_id
            and cr.receiver_profile_id = me.id)
          or
          (cr.receiver_profile_id = posts.profile_id
            and cr.requester_profile_id = me.id)
        )
    )
  );
