-- Social features: post visibility, profile privacy, threaded comments with
-- likes, story reactions with emoji, and a proper connections counter.
--
-- The Flutter client already degrades gracefully when these columns don't
-- exist (see SupabaseFeedRepository, SupabaseCommentRepository,
-- SupabaseStoryRepository) — applying this migration unlocks the full UX
-- and stops the silent fall-back queries.

------------------------------------------------------------------------------
-- 1. Posts: visibility column (public / connections-only)
------------------------------------------------------------------------------

alter table if exists public.posts
  add column if not exists visibility text not null default 'public'
    check (visibility in ('public', 'connections'));

create index if not exists idx_posts_visibility
  on public.posts (visibility);

------------------------------------------------------------------------------
-- 2. Profiles: profile-level privacy + correct connections counter
------------------------------------------------------------------------------

alter table if exists public.profiles
  add column if not exists is_private boolean not null default false,
  add column if not exists connections_count integer not null default 0;

-- Rebuild connections_count from the source of truth and stop letting the
-- legacy `following_count` double as a connections counter.
update public.profiles p
set connections_count = sub.value
from (
  select participant_id, count(*) as value
  from (
    select requester_profile_id as participant_id
    from public.connection_requests
    where status = 'accepted'
    union all
    select receiver_profile_id as participant_id
    from public.connection_requests
    where status = 'accepted'
  ) rows
  group by participant_id
) sub
where p.id = sub.participant_id;

update public.profiles
set following_count = coalesce((
  select count(*)
  from public.followers f
  where f.follower_id = profiles.id
), 0),
    followers_count = coalesce((
  select count(*)
  from public.followers f
  where f.following_id = profiles.id
), 0);

-- Replace the trigger that incorrectly incremented following_count when a
-- connection was accepted. From now on a connection accept bumps
-- connections_count, and follows alone bump following_count.
create or replace function public.app_update_connection_counts()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
declare
  v_one uuid;
  v_two uuid;
begin
  if new.status = 'accepted'
     and (old.status is distinct from 'accepted') then
    update public.profiles
    set connections_count = coalesce(connections_count, 0) + 1
    where id in (new.requester_profile_id, new.receiver_profile_id);

    v_one := least(new.requester_profile_id, new.receiver_profile_id);
    v_two := greatest(new.requester_profile_id, new.receiver_profile_id);

    insert into public.conversations (
      participant_one,
      participant_two,
      last_message,
      last_message_at
    )
    values (v_one, v_two, '', now())
    on conflict (participant_one, participant_two) do nothing;
  elsif (old.status = 'accepted')
        and new.status is distinct from 'accepted' then
    update public.profiles
    set connections_count = greatest(coalesce(connections_count, 0) - 1, 0)
    where id in (new.requester_profile_id, new.receiver_profile_id);
  end if;

  return new;
end;
$$;

------------------------------------------------------------------------------
-- 3. Followers counters: keep them honest via insert/delete triggers
------------------------------------------------------------------------------

create or replace function public.app_followers_after_insert()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  update public.profiles
  set followers_count = coalesce(followers_count, 0) + 1
  where id = new.following_id;
  update public.profiles
  set following_count = coalesce(following_count, 0) + 1
  where id = new.follower_id;
  return new;
end;
$$;

create or replace function public.app_followers_after_delete()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  update public.profiles
  set followers_count = greatest(coalesce(followers_count, 0) - 1, 0)
  where id = old.following_id;
  update public.profiles
  set following_count = greatest(coalesce(following_count, 0) - 1, 0)
  where id = old.follower_id;
  return old;
end;
$$;

drop trigger if exists on_followers_insert_counts on public.followers;
create trigger on_followers_insert_counts
  after insert on public.followers
  for each row execute function public.app_followers_after_insert();

drop trigger if exists on_followers_delete_counts on public.followers;
create trigger on_followers_delete_counts
  after delete on public.followers
  for each row execute function public.app_followers_after_delete();

------------------------------------------------------------------------------
-- 4. Threaded comments: parent_id, likes_count, replies_count
------------------------------------------------------------------------------

alter table if exists public.app_comments
  add column if not exists parent_id uuid
    references public.app_comments(id) on delete cascade,
  add column if not exists likes_count integer not null default 0,
  add column if not exists replies_count integer not null default 0;

create index if not exists idx_app_comments_parent
  on public.app_comments (parent_id)
  where parent_id is not null;

create table if not exists public.app_comment_likes (
  comment_id uuid not null references public.app_comments(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, profile_id)
);

alter table public.app_comment_likes enable row level security;

drop policy if exists "Comment likes are visible to everyone"
  on public.app_comment_likes;
create policy "Comment likes are visible to everyone"
  on public.app_comment_likes for select using (true);

drop policy if exists "Authors can like comments"
  on public.app_comment_likes;
create policy "Authors can like comments"
  on public.app_comment_likes for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = app_comment_likes.profile_id
        and p.user_id = auth.uid()
    )
  );

drop policy if exists "Authors can unlike their comment likes"
  on public.app_comment_likes;
create policy "Authors can unlike their comment likes"
  on public.app_comment_likes for delete to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = app_comment_likes.profile_id
        and p.user_id = auth.uid()
    )
  );

grant select, insert, delete on public.app_comment_likes to authenticated;
grant select on public.app_comment_likes to anon;

create or replace function public.app_comment_likes_after_insert()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
declare
  v_owner uuid;
begin
  update public.app_comments
  set likes_count = coalesce(likes_count, 0) + 1
  where id = new.comment_id;

  select profile_id into v_owner
  from public.app_comments
  where id = new.comment_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'إعجاب جديد',
      'أعجب أحدهم بتعليقك',
      'comment_like',
      'app://comment/' || new.comment_id::text
    );
  end if;

  return new;
end;
$$;

create or replace function public.app_comment_likes_after_delete()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  update public.app_comments
  set likes_count = greatest(coalesce(likes_count, 0) - 1, 0)
  where id = old.comment_id;
  return old;
end;
$$;

drop trigger if exists on_app_comment_like_insert on public.app_comment_likes;
create trigger on_app_comment_like_insert
  after insert on public.app_comment_likes
  for each row execute function public.app_comment_likes_after_insert();

drop trigger if exists on_app_comment_like_delete on public.app_comment_likes;
create trigger on_app_comment_like_delete
  after delete on public.app_comment_likes
  for each row execute function public.app_comment_likes_after_delete();

-- Keep replies_count in sync when threaded comments are added/removed.
create or replace function public.app_comments_after_insert_threaded()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  if new.parent_id is not null then
    update public.app_comments
    set replies_count = coalesce(replies_count, 0) + 1
    where id = new.parent_id;
  end if;
  return new;
end;
$$;

create or replace function public.app_comments_after_delete_threaded()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  if old.parent_id is not null then
    update public.app_comments
    set replies_count = greatest(coalesce(replies_count, 0) - 1, 0)
    where id = old.parent_id;
  end if;
  return old;
end;
$$;

drop trigger if exists on_app_comment_insert_threaded
  on public.app_comments;
create trigger on_app_comment_insert_threaded
  after insert on public.app_comments
  for each row execute function public.app_comments_after_insert_threaded();

drop trigger if exists on_app_comment_delete_threaded
  on public.app_comments;
create trigger on_app_comment_delete_threaded
  after delete on public.app_comments
  for each row execute function public.app_comments_after_delete_threaded();

-- Backfill replies_count from existing parent_id rows.
update public.app_comments p
set replies_count = sub.value
from (
  select parent_id, count(*) as value
  from public.app_comments
  where parent_id is not null
  group by parent_id
) sub
where p.id = sub.parent_id;

------------------------------------------------------------------------------
-- 5. Story reactions (emoji) + notify the creator
------------------------------------------------------------------------------

create table if not exists public.story_reactions (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  unique (story_id, profile_id)
);

create index if not exists idx_story_reactions_story
  on public.story_reactions (story_id);

alter table public.story_reactions enable row level security;

drop policy if exists "Story reactions are visible to everyone"
  on public.story_reactions;
create policy "Story reactions are visible to everyone"
  on public.story_reactions for select using (true);

drop policy if exists "Authors can react to stories"
  on public.story_reactions;
create policy "Authors can react to stories"
  on public.story_reactions for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = story_reactions.profile_id
        and p.user_id = auth.uid()
    )
  );

drop policy if exists "Authors can update their story reactions"
  on public.story_reactions;
create policy "Authors can update their story reactions"
  on public.story_reactions for update to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = story_reactions.profile_id
        and p.user_id = auth.uid()
    )
  );

drop policy if exists "Authors can delete their story reactions"
  on public.story_reactions;
create policy "Authors can delete their story reactions"
  on public.story_reactions for delete to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = story_reactions.profile_id
        and p.user_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.story_reactions to authenticated;
grant select on public.story_reactions to anon;

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

  return new;
end;
$$;

drop trigger if exists on_story_reaction_insert on public.story_reactions;
create trigger on_story_reaction_insert
  after insert on public.story_reactions
  for each row execute function public.app_story_reactions_after_insert();

------------------------------------------------------------------------------
-- 6. Backfill connections_count from the corrected formula above. This was
--    done after the new columns/triggers existed so any inflight UPDATE
--    statements run against the post-migration schema.
------------------------------------------------------------------------------

-- Already handled above via the initial UPDATE; this block reasserts the
-- counter using a deterministic count so the migration is idempotent.
update public.profiles p
set connections_count = coalesce(sub.value, 0)
from (
  select participant_id, count(*) as value
  from (
    select requester_profile_id as participant_id
    from public.connection_requests
    where status = 'accepted'
    union all
    select receiver_profile_id as participant_id
    from public.connection_requests
    where status = 'accepted'
  ) rows
  group by participant_id
) sub
where p.id = sub.participant_id;
