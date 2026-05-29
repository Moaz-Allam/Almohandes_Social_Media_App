-- ============================================================
-- المهندس — fix comment reply/like double-counting.
--
-- A pre-existing trigger was also maintaining replies_count, so each
-- reply incremented it twice. Drop any non-canonical trigger that
-- touches the counters, then reconcile existing rows to the true
-- counts.
-- ============================================================

-- Drop duplicate reply-count triggers (keep the canonical one).
do $$
declare
  r record;
begin
  for r in
    select t.tgname
      from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      join pg_proc p on p.oid = t.tgfoid
     where n.nspname = 'public'
       and c.relname = 'app_comments'
       and not t.tgisinternal
       and t.tgname <> 'trg_app_comments_replies'
       and pg_get_functiondef(p.oid) ilike '%replies_count%'
  loop
    execute format('drop trigger if exists %I on public.app_comments', r.tgname);
  end loop;
end $$;

-- Drop duplicate like-count triggers on app_comment_likes.
do $$
declare
  r record;
begin
  for r in
    select t.tgname
      from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      join pg_proc p on p.oid = t.tgfoid
     where n.nspname = 'public'
       and c.relname = 'app_comment_likes'
       and not t.tgisinternal
       and t.tgname <> 'trg_app_comment_likes'
       and pg_get_functiondef(p.oid) ilike '%likes_count%'
  loop
    execute format('drop trigger if exists %I on public.app_comment_likes', r.tgname);
  end loop;
end $$;

-- Reconcile existing counts to reality.
update public.app_comments p
   set replies_count = (
     select count(*) from public.app_comments c where c.parent_id = p.id
   );

update public.app_comments p
   set likes_count = (
     select count(*) from public.app_comment_likes l where l.comment_id = p.id
   );
