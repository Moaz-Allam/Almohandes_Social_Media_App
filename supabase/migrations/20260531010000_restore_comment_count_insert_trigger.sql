-- ============================================================
-- المهندس — restore the missing INSERT trigger that bumps
-- posts.comments_count (and notifies the owner) on app_comments.
--
-- Symptom: the feed badge always read 0 comments. Adding a comment bumped
-- it optimistically, then a feed reload reset it to the DB value (0).
--
-- Root cause: on the remote DB the delete-side counter trigger
-- (on_app_comment_delete_decrement -> app_after_comment_delete) survived,
-- but its INSERT counterpart (on_app_comment_notify -> app_notify_on_comment)
-- had been dropped. With no insert trigger, app_comments rows were created
-- but posts.comments_count was never incremented — and post owners stopped
-- receiving "تعليق جديد" notifications.
--
-- app_notify_on_comment() is already the canonical version on the remote
-- (top-level notify + comments_count bump), so we only need to (re)attach
-- the trigger and reconcile the existing counters with reality. Idempotent.
-- ============================================================

drop trigger if exists on_app_comment_notify on public.app_comments;
create trigger on_app_comment_notify
  after insert on public.app_comments
  for each row execute function public.app_notify_on_comment();

-- Reconcile post comment counters with the live top-level comment rows
-- (replies live inside replies_count on their parent, not the post badge).
update public.posts p
set comments_count = coalesce(sub.value, 0)
from (
  select target_id, count(*) as value
  from public.app_comments
  where target_type = 'post' and parent_id is null
  group by target_id
) sub
where p.id::text = sub.target_id;

-- Reset posts that have no top-level comments but still carry a stale count.
update public.posts p
set comments_count = 0
where coalesce(p.comments_count, 0) <> 0
  and not exists (
    select 1 from public.app_comments c
    where c.target_type = 'post'
      and c.parent_id is null
      and c.target_id = p.id::text
  );

-- Same reconciliation for reels.
update public.reels r
set comments_count = coalesce(sub.value, 0)
from (
  select target_id, count(*) as value
  from public.app_comments
  where target_type = 'reel' and parent_id is null
  group by target_id
) sub
where r.id::text = sub.target_id;

update public.reels r
set comments_count = 0
where coalesce(r.comments_count, 0) <> 0
  and not exists (
    select 1 from public.app_comments c
    where c.target_type = 'reel'
      and c.parent_id is null
      and c.target_id = r.id::text
  );
