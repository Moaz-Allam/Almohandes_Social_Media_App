-- ============================================================
-- المهندس — comment replies + comment likes.
--
-- app_comments was missing the columns the app already writes
-- (parent_id, likes_count, replies_count) and app_comment_likes
-- didn't exist, so replies silently fell back to top-level comments
-- and likes were dropped. This adds them with count-maintaining
-- triggers and RLS.
-- ============================================================

-- 1. Threading + counters on app_comments.
alter table public.app_comments
  add column if not exists parent_id uuid
    references public.app_comments(id) on delete cascade,
  add column if not exists likes_count integer not null default 0,
  add column if not exists replies_count integer not null default 0;

create index if not exists app_comments_parent_id_idx
  on public.app_comments (parent_id);

-- 2. Comment likes table.
create table if not exists public.app_comment_likes (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.app_comments(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (comment_id, profile_id)
);

alter table public.app_comment_likes enable row level security;

drop policy if exists "comment likes readable" on public.app_comment_likes;
create policy "comment likes readable" on public.app_comment_likes
  for select using (true);

drop policy if exists "users manage own comment likes" on public.app_comment_likes;
create policy "users manage own comment likes" on public.app_comment_likes
  for all to authenticated
  using (profile_id in (select id from public.profiles where user_id = auth.uid()))
  with check (profile_id in (select id from public.profiles where user_id = auth.uid()));

-- 3. Keep replies_count in sync.
create or replace function public.tg_app_comments_replies_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' and new.parent_id is not null then
    update public.app_comments set replies_count = replies_count + 1 where id = new.parent_id;
  elsif tg_op = 'DELETE' and old.parent_id is not null then
    update public.app_comments set replies_count = greatest(replies_count - 1, 0) where id = old.parent_id;
  end if;
  return null;
end $$;

drop trigger if exists trg_app_comments_replies on public.app_comments;
create trigger trg_app_comments_replies
  after insert or delete on public.app_comments
  for each row execute function public.tg_app_comments_replies_count();

-- 4. Keep likes_count in sync.
create or replace function public.tg_app_comment_likes_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update public.app_comments set likes_count = likes_count + 1 where id = new.comment_id;
  elsif tg_op = 'DELETE' then
    update public.app_comments set likes_count = greatest(likes_count - 1, 0) where id = old.comment_id;
  end if;
  return null;
end $$;

drop trigger if exists trg_app_comment_likes on public.app_comment_likes;
create trigger trg_app_comment_likes
  after insert or delete on public.app_comment_likes
  for each row execute function public.tg_app_comment_likes_count();
