-- The app generates duplicate notifications (one Arabic from the client,
-- one English from server-side triggers). Rewrite each trigger function to
-- emit Arabic text so the server stays the single canonical source and we
-- can stop the client-side notification inserts.

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

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'تعليق جديد',
      'تم إضافة تعليق جديد على منشورك',
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

create or replace function public.app_notify_on_connection_request() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' and new.status = 'pending' then
    perform public.app_notify_once(
      new.receiver_profile_id,
      'طلب تواصل جديد',
      'استلمت طلب تواصل جديدا',
      'connection',
      'app://profile/' || new.requester_profile_id::text
    );
  elsif tg_op = 'UPDATE'
    and new.status = 'accepted'
    and old.status is distinct from 'accepted' then
    perform public.app_notify_once(
      new.requester_profile_id,
      'تم قبول طلب التواصل',
      'يمكنك الآن مراسلة هذا الشخص',
      'connection',
      'app://chat/' || new.receiver_profile_id::text
    );
  end if;

  return new;
end;
$$;

create or replace function public.app_notify_on_message() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
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
      'رسالة جديدة',
      case new.message_type
        when 'voice' then 'استلمت رسالة صوتية'
        when 'image' then 'استلمت صورة'
        when 'video' then 'استلمت مقطع فيديو'
        when 'file' then 'استلمت ملفا'
        else left(coalesce(new.content, 'رسالة جديدة'), 160)
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

create or replace function public.app_notify_on_post_like() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
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
      'إعجاب جديد',
      'تلقى منشورك إعجابا جديدا',
      'like',
      'app://post/' || new.post_id::text
    );
  end if;

  return new;
end;
$$;

create or replace function public.app_notify_on_project_application() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
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
      'طلب جديد على مشروعك',
      'تم إرسال طلب جديد للمشاركة في مشروعك',
      'project',
      'app://project/' || new.project_id::text
    );
  end if;

  return new;
end;
$$;

create or replace function public.app_notify_on_reel_like() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
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
      'إعجاب جديد',
      'تلقى الريل إعجابا جديدا',
      'like',
      'app://reel/' || new.reel_id::text
    );
  end if;

  return new;
end;
$$;

-- One-off cleanup: delete any English notifications still sitting in the
-- table from before this migration. Heuristic matches the previous
-- canonical strings produced by these triggers.
delete from public.notifications
 where title in (
   'New comment',
   'New connection request',
   'Connection accepted',
   'New message',
   'New like',
   'New project proposal'
 )
   or message in (
     'Someone commented on your content.',
     'You received a connection request.',
     'You can now message this connection.',
     'You received a voice message.',
     'You received an image.',
     'You received a video.',
     'You received a file.',
     'Someone liked your post.',
     'Someone liked your reel.',
     'A user submitted a proposal to your project.'
   );
