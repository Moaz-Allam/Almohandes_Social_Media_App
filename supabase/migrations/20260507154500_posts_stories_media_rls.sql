-- Keep post/story creation usable from the Flutter app while preserving
-- ownership checks for writes.

do $$
begin
  if to_regclass('public.posts') is not null
      and to_regclass('public.profiles') is not null then
    alter table public.posts enable row level security;

    alter table public.posts
      add column if not exists image_url text,
      add column if not exists post_type text not null default 'general';

    grant select on public.posts to anon, authenticated;
    grant insert, update, delete on public.posts to authenticated;

    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'posts'
        and policyname = 'Posts are publicly readable'
    ) then
      create policy "Posts are publicly readable"
        on public.posts
        for select
        using (true);
    end if;

    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'posts'
        and policyname = 'Users manage their own posts'
    ) then
      create policy "Users manage their own posts"
        on public.posts
        for all
        to authenticated
        using (
          exists (
            select 1
            from public.profiles p
            where p.id = posts.profile_id
              and p.user_id = auth.uid()
          )
        )
        with check (
          exists (
            select 1
            from public.profiles p
            where p.id = posts.profile_id
              and p.user_id = auth.uid()
          )
        );
    end if;
  end if;

  if to_regclass('public.stories') is not null
      and to_regclass('public.profiles') is not null then
    alter table public.stories enable row level security;

    alter table public.stories
      add column if not exists content text not null default '',
      add column if not exists media_url text,
      add column if not exists media_type text not null default 'text',
      add column if not exists is_archived boolean not null default false,
      add column if not exists expires_at timestamptz not null default (now() + interval '24 hours');

    alter table public.stories
      alter column expires_at set default (now() + interval '24 hours');

    grant select on public.stories to anon, authenticated;
    grant insert, update, delete on public.stories to authenticated;

    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'stories'
        and policyname = 'Stories are publicly readable'
    ) then
      create policy "Stories are publicly readable"
        on public.stories
        for select
        using (true);
    end if;

    if not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'stories'
        and policyname = 'Users manage their own stories'
    ) then
      create policy "Users manage their own stories"
        on public.stories
        for all
        to authenticated
        using (
          exists (
            select 1
            from public.profiles p
            where p.id = stories.profile_id
              and p.user_id = auth.uid()
          )
        )
        with check (
          exists (
            select 1
            from public.profiles p
            where p.id = stories.profile_id
              and p.user_id = auth.uid()
          )
        );
    end if;
  end if;
end
$$;
