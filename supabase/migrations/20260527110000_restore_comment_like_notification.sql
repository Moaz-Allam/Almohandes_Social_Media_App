-- ============================================================
-- المهندس — restore the "someone liked your comment" notification.
--
-- The original combined trigger (count + notification) was dropped
-- during the duplicate-counter cleanup. Re-add it as a
-- notification-ONLY trigger so it doesn't touch likes_count (that's
-- handled by trg_app_comment_likes) and can't re-introduce
-- double-counting. The notifications insert also fans out to push
-- via the existing send-push trigger.
-- ============================================================

create or replace function public.tg_app_comment_like_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
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

drop trigger if exists trg_app_comment_like_notify on public.app_comment_likes;
create trigger trg_app_comment_like_notify
  after insert on public.app_comment_likes
  for each row execute function public.tg_app_comment_like_notify();
