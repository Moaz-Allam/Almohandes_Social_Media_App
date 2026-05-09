-- Runtime hardening for the Flutter app after exporting the live schema.
-- This migration keeps existing production data, fixes stale RPCs, and makes
-- repeated user actions idempotent.

alter table if exists public.profiles
  add column if not exists cover_url text;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'cover_photo_url'
  ) then
    update public.profiles
    set cover_url = cover_photo_url
    where cover_url is null
      and cover_photo_url is not null;
  end if;
end
$$;

create or replace function public.app_sync_profile_cover_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.cover_url is null and new.cover_photo_url is not null then
    new.cover_url := new.cover_photo_url;
  elsif new.cover_photo_url is null and new.cover_url is not null then
    new.cover_photo_url := new.cover_url;
  elsif tg_op = 'UPDATE'
    and new.cover_url is distinct from old.cover_url
    and new.cover_url is not null then
    new.cover_photo_url := new.cover_url;
  elsif tg_op = 'UPDATE'
    and new.cover_photo_url is distinct from old.cover_photo_url
    and new.cover_photo_url is not null then
    new.cover_url := new.cover_photo_url;
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_sync_profile_cover_columns on public.profiles;
create trigger on_app_sync_profile_cover_columns
  before insert or update on public.profiles
  for each row execute function public.app_sync_profile_cover_columns();

create or replace function public.app_safe_user_role(p_role text)
returns public.user_role
language sql
immutable
set search_path = public
as $$
  select case lower(coalesce(nullif(trim(p_role), ''), 'engineer'))
    when 'engineer' then 'engineer'::public.user_role
    when 'contractor' then 'contractor'::public.user_role
    when 'company' then 'contractor'::public.user_role
    when 'client' then 'client'::public.user_role
    when 'craftsman' then 'craftsman'::public.user_role
    when 'worker' then 'worker'::public.user_role
    when 'machinery' then 'machinery'::public.user_role
    when 'equipment' then 'machinery'::public.user_role
    when 'admin' then 'admin'::public.user_role
    else 'engineer'::public.user_role
  end
$$;

create or replace function public.app_safe_governorate(p_governorate text)
returns public.governorate
language sql
immutable
set search_path = public
as $$
  select case lower(coalesce(nullif(trim(p_governorate), ''), 'baghdad'))
    when 'baghdad' then 'baghdad'::public.governorate
    when 'basra' then 'basra'::public.governorate
    when 'nineveh' then 'nineveh'::public.governorate
    when 'erbil' then 'erbil'::public.governorate
    when 'sulaymaniyah' then 'sulaymaniyah'::public.governorate
    when 'duhok' then 'duhok'::public.governorate
    when 'kirkuk' then 'kirkuk'::public.governorate
    when 'diyala' then 'diyala'::public.governorate
    when 'anbar' then 'anbar'::public.governorate
    when 'babylon' then 'babylon'::public.governorate
    when 'karbala' then 'karbala'::public.governorate
    when 'najaf' then 'najaf'::public.governorate
    when 'wasit' then 'wasit'::public.governorate
    when 'saladin' then 'saladin'::public.governorate
    when 'dhi_qar' then 'dhi_qar'::public.governorate
    when 'maysan' then 'maysan'::public.governorate
    when 'muthanna' then 'muthanna'::public.governorate
    when 'qadisiyah' then 'qadisiyah'::public.governorate
    else 'baghdad'::public.governorate
  end
$$;

create or replace function public.complete_signup_profile_for_app(
  p_full_name text,
  p_email text,
  p_phone text,
  p_role text,
  p_governorate text,
  p_bio text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_profile_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = v_user_id
  order by p.created_at desc nulls last, p.id
  limit 1;

  if v_profile_id is null then
    insert into public.profiles (
      user_id,
      full_name,
      email,
      phone,
      role,
      governorate,
      bio
    )
    values (
      v_user_id,
      coalesce(nullif(trim(p_full_name), ''), split_part(coalesce(p_email, ''), '@', 1), 'User'),
      nullif(trim(p_email), ''),
      nullif(trim(p_phone), ''),
      public.app_safe_user_role(p_role),
      public.app_safe_governorate(p_governorate),
      nullif(trim(p_bio), '')
    )
    returning id into v_profile_id;
  else
    update public.profiles
    set
      full_name = coalesce(nullif(trim(p_full_name), ''), full_name),
      email = coalesce(nullif(trim(p_email), ''), email),
      phone = nullif(trim(p_phone), ''),
      role = public.app_safe_user_role(p_role),
      governorate = public.app_safe_governorate(p_governorate),
      bio = nullif(trim(p_bio), ''),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return v_profile_id;
end;
$$;

grant execute on function public.complete_signup_profile_for_app(
  text,
  text,
  text,
  text,
  text,
  text
) to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    user_id,
    email,
    full_name,
    role,
    governorate
  )
  values (
    new.id,
    nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''),
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      split_part(coalesce(new.email, ''), '@', 1),
      'User'
    ),
    public.app_safe_user_role(new.raw_user_meta_data->>'role'),
    public.app_safe_governorate(new.raw_user_meta_data->>'governorate')
  )
  on conflict (user_id)
  do update set
    email = coalesce(excluded.email, public.profiles.email),
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    role = coalesce(public.profiles.role, excluded.role),
    governorate = coalesce(public.profiles.governorate, excluded.governorate),
    updated_at = now();

  return new;
end;
$$;

create or replace function public.handle_new_auth_user_for_app()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
begin
  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = new.id
  order by p.created_at desc nulls last, p.id
  limit 1;

  if v_profile_id is null then
    insert into public.profiles (
      user_id,
      full_name,
      email,
      phone,
      role,
      governorate,
      bio
    )
    values (
      new.id,
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        split_part(coalesce(new.email, ''), '@', 1),
        'User'
      ),
      nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''),
      nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''),
      public.app_safe_user_role(new.raw_user_meta_data->>'role'),
      public.app_safe_governorate(new.raw_user_meta_data->>'governorate'),
      nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), '')
    );
  else
    update public.profiles
    set
      full_name = coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        split_part(coalesce(new.email, ''), '@', 1),
        full_name
      ),
      email = coalesce(nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''), email),
      phone = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''), phone),
      role = public.app_safe_user_role(coalesce(new.raw_user_meta_data->>'role', role::text)),
      governorate = public.app_safe_governorate(coalesce(new.raw_user_meta_data->>'governorate', governorate::text)),
      bio = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), ''), bio),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return new;
end;
$$;

do $$
begin
  if to_regclass('public.conversations') is not null then
    update public.conversations
    set participant_one = least(participant_one, participant_two),
        participant_two = greatest(participant_one, participant_two)
    where participant_one > participant_two;

    with ranked as (
      select
        id,
        first_value(id) over (
          partition by participant_one, participant_two
          order by coalesce(last_message_at, created_at) desc nulls last, created_at desc nulls last, id
        ) as keep_id,
        row_number() over (
          partition by participant_one, participant_two
          order by coalesce(last_message_at, created_at) desc nulls last, created_at desc nulls last, id
        ) as rn
      from public.conversations
    ),
    mapping as (
      select id as duplicate_id, keep_id
      from ranked
      where rn > 1
    )
    update public.messages m
    set conversation_id = mapping.keep_id
    from mapping
    where m.conversation_id = mapping.duplicate_id;

    with ranked as (
      select
        id,
        row_number() over (
          partition by participant_one, participant_two
          order by coalesce(last_message_at, created_at) desc nulls last, created_at desc nulls last, id
        ) as rn
      from public.conversations
    )
    delete from public.conversations c
    using ranked
    where c.id = ranked.id
      and ranked.rn > 1;

    alter table public.conversations
      alter column last_message set default '',
      alter column last_message_at set default now();
  end if;
end
$$;

create unique index if not exists conversations_participant_pair_unique_idx
  on public.conversations(participant_one, participant_two);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.conversations'::regclass
      and conname = 'conversations_participant_pair_key'
  ) then
    alter table public.conversations
      add constraint conversations_participant_pair_key
      unique using index conversations_participant_pair_unique_idx;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.connection_requests') is not null then
    with ranked as (
      select
        id,
        row_number() over (
          partition by least(requester_profile_id, receiver_profile_id),
                       greatest(requester_profile_id, receiver_profile_id)
          order by
            case status when 'accepted' then 0 when 'pending' then 1 else 2 end,
            updated_at desc nulls last,
            created_at desc nulls last,
            id
        ) as rn
      from public.connection_requests
      where status in ('pending', 'accepted')
    )
    delete from public.connection_requests cr
    using ranked
    where cr.id = ranked.id
      and ranked.rn > 1;
  end if;
end
$$;

create unique index if not exists connection_requests_active_pair_unique_idx
  on public.connection_requests(
    least(requester_profile_id, receiver_profile_id),
    greatest(requester_profile_id, receiver_profile_id)
  )
  where status in ('pending', 'accepted');

create or replace function public.request_connection_for_app(
  p_receiver_profile_id uuid,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_request_id uuid;
  v_status text;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  if p_receiver_profile_id is null or p_receiver_profile_id = v_profile_id then
    raise exception 'invalid_receiver';
  end if;

  select id, status
  into v_request_id, v_status
  from public.connection_requests
  where (
      requester_profile_id = v_profile_id
      and receiver_profile_id = p_receiver_profile_id
    )
    or (
      requester_profile_id = p_receiver_profile_id
      and receiver_profile_id = v_profile_id
    )
  order by
    case status when 'accepted' then 0 when 'pending' then 1 else 2 end,
    updated_at desc nulls last,
    created_at desc nulls last
  limit 1;

  if v_status in ('pending', 'accepted') then
    return v_request_id;
  end if;

  if v_request_id is not null then
    update public.connection_requests
    set requester_profile_id = v_profile_id,
        receiver_profile_id = p_receiver_profile_id,
        status = 'pending',
        message = p_message,
        responded_at = null,
        updated_at = now()
    where id = v_request_id
    returning id into v_request_id;
  else
    insert into public.connection_requests (
      requester_profile_id,
      receiver_profile_id,
      message
    )
    values (v_profile_id, p_receiver_profile_id, p_message)
    returning id into v_request_id;
  end if;

  return v_request_id;
end;
$$;

grant execute on function public.request_connection_for_app(uuid, text)
  to authenticated;

create or replace function public.app_update_connection_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_one uuid;
  v_two uuid;
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    update public.profiles
    set following_count = coalesce(following_count, 0) + 1
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
    on conflict (participant_one, participant_two)
    do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_connection_request_counts on public.connection_requests;
create trigger on_connection_request_counts
  after update on public.connection_requests
  for each row execute function public.app_update_connection_counts();

create or replace function public.get_network_profiles_for_app(
  p_audience text default 'people',
  p_limit integer default 40
)
returns table (
  id uuid,
  full_name text,
  username text,
  role text,
  governorate text,
  bio text,
  experience_years integer,
  projects_count integer,
  followers_count integer,
  avatar_url text,
  is_verified boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_viewer_role public.user_role;
begin
  v_profile_id := public.app_current_profile_id();

  select p.role
  into v_viewer_role
  from public.profiles p
  where p.id = v_profile_id
  limit 1;

  if v_profile_id is null or v_viewer_role is null then
    return;
  end if;

  if v_viewer_role not in ('engineer'::public.user_role, 'contractor'::public.user_role, 'client'::public.user_role, 'admin'::public.user_role) then
    return;
  end if;

  return query
  select
    p.id,
    p.full_name,
    p.username,
    p.role::text,
    p.governorate::text,
    p.bio,
    p.experience_years,
    p.projects_count,
    p.followers_count,
    p.avatar_url,
    p.is_verified
  from public.profiles p
  where p.id <> v_profile_id
    and not exists (
      select 1
      from public.connection_requests cr
      where cr.status = 'accepted'
        and (
          (cr.requester_profile_id = v_profile_id and cr.receiver_profile_id = p.id)
          or (cr.requester_profile_id = p.id and cr.receiver_profile_id = v_profile_id)
        )
    )
    and (
      v_viewer_role = 'admin'::public.user_role
      or (
        p_audience = 'companies'
        and v_viewer_role in ('engineer'::public.user_role, 'contractor'::public.user_role, 'client'::public.user_role)
        and p.role in ('contractor'::public.user_role, 'client'::public.user_role)
      )
      or (
        p_audience <> 'companies'
        and v_viewer_role = 'engineer'::public.user_role
        and p.role in (
          'engineer'::public.user_role,
          'craftsman'::public.user_role,
          'worker'::public.user_role,
          'machinery'::public.user_role
        )
      )
      or (
        p_audience <> 'companies'
        and v_viewer_role in ('contractor'::public.user_role, 'client'::public.user_role)
        and p.role = 'engineer'::public.user_role
      )
    )
  order by p.is_verified desc, p.projects_count desc, p.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 100);
end;
$$;

grant execute on function public.get_network_profiles_for_app(text, integer)
  to authenticated;

drop function if exists public.get_user_conversations(uuid);

create or replace function public.get_user_conversations(p_profile_id uuid)
returns table (
  conversation_id uuid,
  recipient_profile_id uuid,
  recipient_name text,
  recipient_avatar_url text,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id as conversation_id,
    other_profile.id as recipient_profile_id,
    other_profile.full_name as recipient_name,
    other_profile.avatar_url as recipient_avatar_url,
    coalesce(c.last_message, '') as last_message,
    c.last_message_at,
    count(m.id) filter (
      where m.sender_id <> p_profile_id
        and coalesce(m.read_at is null, true)
        and coalesce(m.is_read, false) = false
    ) as unread_count
  from public.conversations c
  join public.profiles other_profile
    on other_profile.id = case
      when c.participant_one = p_profile_id then c.participant_two
      else c.participant_one
    end
  left join public.messages m
    on m.conversation_id = c.id
  where p_profile_id in (c.participant_one, c.participant_two)
  group by c.id, other_profile.id, other_profile.full_name, other_profile.avatar_url, c.last_message, c.last_message_at
  order by c.last_message_at desc nulls last, c.created_at desc
  limit 50
$$;

grant execute on function public.get_user_conversations(uuid)
  to authenticated;

create or replace function public.app_notify_once(
  p_profile_id uuid,
  p_title text,
  p_message text,
  p_type text,
  p_action_url text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_profile_id is null then
    return;
  end if;

  if exists (
    select 1
    from public.notifications n
    where n.profile_id = p_profile_id
      and n.type = coalesce(nullif(trim(p_type), ''), 'general')
      and n.action_url is not distinct from p_action_url
      and n.created_at > now() - interval '30 seconds'
  ) then
    return;
  end if;

  insert into public.notifications (
    profile_id,
    title,
    message,
    type,
    action_url
  )
  values (
    p_profile_id,
    coalesce(nullif(trim(p_title), ''), 'New notification'),
    coalesce(p_message, ''),
    coalesce(nullif(trim(p_type), ''), 'general'),
    p_action_url
  );
end;
$$;

create or replace function public.app_notify_on_comment()
returns trigger
language plpgsql
security definer
set search_path = public
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

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New comment',
      'Someone commented on your content.',
      'comment',
      'app://' || new.target_type || '/' || new.target_id
    );
  end if;

  if new.target_type = 'post' then
    update public.posts
    set comments_count = coalesce(comments_count, 0) + 1
    where id::text = new.target_id;
  elsif new.target_type = 'reel' then
    update public.reels
    set comments_count = coalesce(comments_count, 0) + 1
    where id::text = new.target_id;
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_comment_notify on public.app_comments;
create trigger on_app_comment_notify
  after insert on public.app_comments
  for each row execute function public.app_notify_on_comment();

create or replace function public.app_notify_on_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient uuid;
begin
  select case
      when c.participant_one = new.sender_id then c.participant_two
      else c.participant_one
    end
  into v_recipient
  from public.conversations c
  where c.id = new.conversation_id;

  if v_recipient is not null and v_recipient <> new.sender_id then
    perform public.app_notify_once(
      v_recipient,
      'New message',
      case new.message_type
        when 'voice' then 'You received a voice message.'
        when 'image' then 'You received an image.'
        when 'video' then 'You received a video.'
        when 'file' then 'You received a file.'
        else left(coalesce(new.content, 'New message'), 160)
      end,
      'message',
      'app://chat/' || new.conversation_id::text
    );
  end if;

  update public.messages
  set is_read = false
  where id = new.id
    and is_read is distinct from false;

  return new;
end;
$$;

drop trigger if exists on_app_message_notify on public.messages;
create trigger on_app_message_notify
  after insert on public.messages
  for each row execute function public.app_notify_on_message();

create or replace function public.app_notify_on_connection_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.status = 'pending' then
    perform public.app_notify_once(
      new.receiver_profile_id,
      'New connection request',
      'You received a connection request.',
      'connection',
      'app://profile/' || new.requester_profile_id::text
    );
  elsif tg_op = 'UPDATE'
    and new.status = 'accepted'
    and old.status is distinct from 'accepted' then
    perform public.app_notify_once(
      new.requester_profile_id,
      'Connection accepted',
      'You can now message this connection.',
      'connection',
      'app://chat/' || new.receiver_profile_id::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_connection_request_notify on public.connection_requests;
create trigger on_app_connection_request_notify
  after insert or update on public.connection_requests
  for each row execute function public.app_notify_on_connection_request();

create or replace function public.app_notify_on_project_application()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  select p.profile_id
  into v_owner
  from public.projects p
  where p.id = new.project_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New project proposal',
      'A user submitted a proposal to your project.',
      'project',
      'app://project/' || new.project_id::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_project_application_notify on public.project_applications;
create trigger on_app_project_application_notify
  after insert on public.project_applications
  for each row execute function public.app_notify_on_project_application();

create or replace function public.app_notify_on_post_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  select p.profile_id
  into v_owner
  from public.posts p
  where p.id = new.post_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New like',
      'Someone liked your post.',
      'like',
      'app://post/' || new.post_id::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_post_like_notify on public.post_likes;
create trigger on_app_post_like_notify
  after insert on public.post_likes
  for each row execute function public.app_notify_on_post_like();

create or replace function public.app_notify_on_reel_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  select r.profile_id
  into v_owner
  from public.reels r
  where r.id = new.reel_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New like',
      'Someone liked your reel.',
      'like',
      'app://reel/' || new.reel_id::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_reel_like_notify on public.reel_likes;
create trigger on_app_reel_like_notify
  after insert on public.reel_likes
  for each row execute function public.app_notify_on_reel_like();
