-- App interactions used by the Flutter client: persistent comments, reposts,
-- connection-backed conversations, premium flags, and safer signup enum values.

do $$
begin
  if to_regtype('public.user_role') is not null then
    alter type public.user_role add value if not exists 'engineer';
    alter type public.user_role add value if not exists 'contractor';
    alter type public.user_role add value if not exists 'client';
    alter type public.user_role add value if not exists 'craftsman';
    alter type public.user_role add value if not exists 'worker';
    alter type public.user_role add value if not exists 'machinery';
    alter type public.user_role add value if not exists 'admin';
  end if;
end
$$;

alter table if exists public.profiles
  add column if not exists subscription_status text not null default 'free',
  add column if not exists has_pro_badge boolean not null default false,
  add column if not exists following_count integer not null default 0,
  add column if not exists followers_count integer not null default 0;

create table if not exists public.app_comments (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('post', 'reel', 'project')),
  target_id text not null,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_app_comments_target_created_at
  on public.app_comments(target_type, target_id, created_at desc);

create table if not exists public.app_reposts (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('post', 'reel')),
  target_id text not null,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (target_type, target_id, profile_id)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  participant_one uuid not null references public.profiles(id) on delete cascade,
  participant_two uuid not null references public.profiles(id) on delete cascade,
  last_message text not null default '',
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (participant_one <> participant_two),
  unique (participant_one, participant_two)
);

alter table if exists public.conversations
  add column if not exists participant_one uuid references public.profiles(id) on delete cascade,
  add column if not exists participant_two uuid references public.profiles(id) on delete cascade,
  add column if not exists last_message text not null default '',
  add column if not exists last_message_at timestamptz not null default now(),
  add column if not exists created_at timestamptz not null default now();

create or replace function public.app_normalize_conversation_participants()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_first uuid;
begin
  if new.participant_one is not null
    and new.participant_two is not null
    and new.participant_one::text > new.participant_two::text then
    v_first := new.participant_one;
    new.participant_one := new.participant_two;
    new.participant_two := v_first;
  end if;
  return new;
end;
$$;

drop trigger if exists on_app_normalize_conversation_participants
  on public.conversations;
create trigger on_app_normalize_conversation_participants
  before insert or update on public.conversations
  for each row execute function public.app_normalize_conversation_participants();

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  message_type text not null default 'text' check (message_type in ('text', 'voice', 'file', 'image', 'video')),
  read_at timestamptz,
  created_at timestamptz not null default now()
);

alter table if exists public.messages
  add column if not exists conversation_id uuid references public.conversations(id) on delete cascade,
  add column if not exists sender_id uuid references public.profiles(id) on delete cascade,
  add column if not exists content text not null default '',
  add column if not exists message_type text not null default 'text',
  add column if not exists read_at timestamptz,
  add column if not exists created_at timestamptz not null default now();

do $$
declare
  v_constraint text;
begin
  if to_regclass('public.messages') is not null then
    select conname into v_constraint
    from pg_constraint
    where conrelid = 'public.messages'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%message_type%';

    if v_constraint is not null then
      execute format('alter table public.messages drop constraint %I', v_constraint);
    end if;

    alter table public.messages
      add constraint messages_message_type_check
      check (message_type in ('text', 'voice', 'file', 'image', 'video'));
  end if;
end
$$;

create index if not exists idx_messages_conversation_created_at
  on public.messages(conversation_id, created_at);

create index if not exists idx_messages_unread_by_conversation
  on public.messages(conversation_id, sender_id)
  where read_at is null;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null default '',
  type text not null default 'general',
  is_read boolean not null default false,
  action_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_profile_created_at
  on public.notifications(profile_id, created_at desc);

create unique index if not exists idx_project_applications_project_profile
  on public.project_applications(project_id, profile_id);

create table if not exists public.blocked_profiles (
  id uuid primary key default gen_random_uuid(),
  blocker_profile_id uuid not null references public.profiles(id) on delete cascade,
  blocked_profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_profile_id, blocked_profile_id),
  check (blocker_profile_id <> blocked_profile_id)
);

alter table if exists public.reels
  add column if not exists video_url text,
  add column if not exists thumbnail_url text,
  add column if not exists caption text not null default '',
  add column if not exists likes_count integer not null default 0,
  add column if not exists comments_count integer not null default 0,
  add column if not exists shares_count integer not null default 0,
  add column if not exists is_active boolean not null default true;

alter table public.app_comments enable row level security;
alter table public.app_reposts enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.blocked_profiles enable row level security;
alter table public.notifications enable row level security;
alter table if exists public.reels enable row level security;

grant select on public.app_comments, public.app_reposts, public.conversations, public.messages to authenticated;
grant insert, update, delete on public.app_comments, public.app_reposts, public.conversations, public.messages to authenticated;
grant select, insert, delete on public.blocked_profiles to authenticated;
grant select, insert, update, delete on public.notifications to authenticated;

do $$
begin
  if to_regclass('public.reels') is not null then
    grant select on public.reels to anon, authenticated;
    grant insert, update, delete on public.reels to authenticated;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'app_comments'
      and policyname = 'Comments are readable'
  ) then
    create policy "Comments are readable"
      on public.app_comments for select using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'app_comments'
      and policyname = 'Users create own comments'
  ) then
    create policy "Users create own comments"
      on public.app_comments for insert to authenticated
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = app_comments.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'app_reposts'
      and policyname = 'Users manage own reposts'
  ) then
    create policy "Users manage own reposts"
      on public.app_reposts for all to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = app_reposts.profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = app_reposts.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'conversations'
      and policyname = 'Conversation participants can read'
  ) then
    create policy "Conversation participants can read"
      on public.conversations for select to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.user_id = auth.uid()
            and p.id in (conversations.participant_one, conversations.participant_two)
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'conversations'
      and policyname = 'Users create own conversations'
  ) then
    create policy "Users create own conversations"
      on public.conversations for insert to authenticated
      with check (
        exists (
          select 1 from public.profiles p
          where p.user_id = auth.uid()
            and p.id in (conversations.participant_one, conversations.participant_two)
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'messages'
      and policyname = 'Conversation participants can read messages'
  ) then
    create policy "Conversation participants can read messages"
      on public.messages for select to authenticated
      using (
        exists (
          select 1
          from public.conversations c
          join public.profiles p
            on p.id in (c.participant_one, c.participant_two)
          where c.id = messages.conversation_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'messages'
      and policyname = 'Conversation participants send messages'
  ) then
    create policy "Conversation participants send messages"
      on public.messages for insert to authenticated
      with check (
        exists (
          select 1
          from public.conversations c
          join public.profiles p
            on p.id = messages.sender_id
          where c.id = messages.conversation_id
            and p.user_id = auth.uid()
            and messages.sender_id in (c.participant_one, c.participant_two)
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'messages'
      and policyname = 'Conversation participants delete messages'
  ) then
    create policy "Conversation participants delete messages"
      on public.messages for delete to authenticated
      using (
        exists (
          select 1
          from public.conversations c
          join public.profiles p
            on p.id in (c.participant_one, c.participant_two)
          where c.id = messages.conversation_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'messages'
      and policyname = 'Conversation participants update messages'
  ) then
    create policy "Conversation participants update messages"
      on public.messages for update to authenticated
      using (
        exists (
          select 1
          from public.conversations c
          join public.profiles p
            on p.id in (c.participant_one, c.participant_two)
          where c.id = messages.conversation_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1
          from public.conversations c
          join public.profiles p
            on p.id in (c.participant_one, c.participant_two)
          where c.id = messages.conversation_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'conversations'
      and policyname = 'Conversation participants delete'
  ) then
    create policy "Conversation participants delete"
      on public.conversations for delete to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.user_id = auth.uid()
            and p.id in (conversations.participant_one, conversations.participant_two)
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'blocked_profiles'
      and policyname = 'Users manage own blocks'
  ) then
    create policy "Users manage own blocks"
      on public.blocked_profiles for all to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = blocked_profiles.blocker_profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = blocked_profiles.blocker_profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'notifications'
      and policyname = 'Users read own notifications'
  ) then
    create policy "Users read own notifications"
      on public.notifications for select to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = notifications.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'notifications'
      and policyname = 'Authenticated users create notifications'
  ) then
    create policy "Authenticated users create notifications"
      on public.notifications for insert to authenticated
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'notifications'
      and policyname = 'Users manage own notifications'
  ) then
    create policy "Users manage own notifications"
      on public.notifications for update to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = notifications.profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = notifications.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'notifications'
      and policyname = 'Users delete own notifications'
  ) then
    create policy "Users delete own notifications"
      on public.notifications for delete to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = notifications.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if to_regclass('public.reels') is not null then
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = 'reels'
        and policyname = 'Reels are publicly readable'
    ) then
      create policy "Reels are publicly readable"
        on public.reels for select using (true);
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = 'reels'
        and policyname = 'Users manage own reels'
    ) then
      create policy "Users manage own reels"
        on public.reels for all to authenticated
        using (
          exists (
            select 1 from public.profiles p
            where p.id = reels.profile_id
              and p.user_id = auth.uid()
          )
        )
        with check (
          exists (
            select 1 from public.profiles p
            where p.id = reels.profile_id
              and p.user_id = auth.uid()
          )
        );
    end if;
  end if;
end
$$;

drop policy if exists "Project owners can read applications"
  on public.project_applications;
create policy "Project owners can read applications"
  on public.project_applications
  for select
  using (
    exists (
      select 1
      from public.projects pr
      join public.profiles owner on owner.id = pr.profile_id
      where pr.id = project_applications.project_id
        and owner.user_id = auth.uid()
    )
  );

drop policy if exists "Project owners can update application status"
  on public.project_applications;
create policy "Project owners can update application status"
  on public.project_applications
  for update
  using (
    exists (
      select 1
      from public.projects pr
      join public.profiles owner on owner.id = pr.profile_id
      where pr.id = project_applications.project_id
        and owner.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.projects pr
      join public.profiles owner on owner.id = pr.profile_id
      where pr.id = project_applications.project_id
        and owner.user_id = auth.uid()
    )
  );

create or replace function public.apply_to_project_for_app(
  p_project_id uuid,
  p_subject text,
  p_message text,
  p_files jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_owner_id uuid;
  v_application_id uuid;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  select profile_id into v_owner_id
  from public.projects
  where id = p_project_id;

  if v_owner_id = v_profile_id then
    raise exception 'cannot_apply_to_own_project';
  end if;

  select id into v_application_id
  from public.project_applications
  where project_id = p_project_id
    and profile_id = v_profile_id;

  if v_application_id is not null then
    raise exception 'already_applied';
  end if;

  insert into public.project_applications (
    project_id,
    profile_id,
    subject,
    message,
    attachments_count,
    files
  )
  values (
    p_project_id,
    v_profile_id,
    p_subject,
    p_message,
    jsonb_array_length(coalesce(p_files, '[]'::jsonb)),
    coalesce(p_files, '[]'::jsonb)
  )
  returning id into v_application_id;

  return v_application_id;
end;
$$;

grant execute on function public.apply_to_project_for_app(uuid, text, text, jsonb)
  to authenticated;

create or replace function public.app_touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
  set last_message = case
      when new.message_type = 'voice' then 'رسالة صوتية'
      when new.message_type = 'image' then 'صورة مرفقة'
      when new.message_type = 'video' then 'فيديو مرفق'
      when new.message_type = 'file' then 'ملف مرفق'
      else left(new.content, 180)
    end,
    last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists on_app_message_touch_conversation on public.messages;
create trigger on_app_message_touch_conversation
  after insert on public.messages
  for each row execute function public.app_touch_conversation();

create or replace function public.app_update_connection_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    update public.profiles
    set following_count = coalesce(following_count, 0) + 1
    where id in (new.requester_profile_id, new.receiver_profile_id);
  end if;
  return new;
end;
$$;

drop trigger if exists on_connection_request_counts on public.connection_requests;
create trigger on_connection_request_counts
  after update on public.connection_requests
  for each row execute function public.app_update_connection_counts();
