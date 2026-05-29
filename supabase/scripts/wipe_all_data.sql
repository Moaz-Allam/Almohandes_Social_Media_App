-- ============================================================
-- WIPE ALL DATA — destructive, irreversible.
--
-- Removes every row from:
--   - every table in the `public` schema (78 tables — profiles,
--     posts, comments, projects, reels, stories, messages,
--     notifications, payments, admin_*, …).
--   - `auth.users` (cascades to identities / sessions /
--     refresh_tokens / one_time_tokens automatically).
--   - `storage.objects` (all uploaded media).
--
-- The schema itself, RLS policies, RPCs, edge functions, triggers
-- and the Twilio Verify config stay intact — only data is removed.
--
-- This is NOT a migration. Do NOT place it under
-- supabase/migrations/ — it would re-run on every db push and
-- silently destroy fresh data.
--
-- How to run (pick one):
--
--   A) Supabase dashboard → SQL Editor → paste this whole file → Run.
--   B) psql with the project's connection string:
--        psql "$SUPABASE_DB_URL" -f supabase/scripts/wipe_all_data.sql
--   C) supabase CLI:
--        supabase db execute --file supabase/scripts/wipe_all_data.sql
-- ============================================================

begin;

-- 1. Truncate every public table at once via dynamic SQL.
--    CASCADE handles all FKs between them.
do $$
declare
  stmt text;
begin
  select 'truncate table '
       || string_agg(format('%I.%I', schemaname, tablename), ', ')
       || ' restart identity cascade'
    into stmt
    from pg_tables
   where schemaname = 'public';

  if stmt is not null then
    execute stmt;
  end if;
end $$;

-- 2. Remove every auth user. The auth schema has on-delete cascades
--    onto identities/sessions/refresh_tokens/one_time_tokens, so
--    this single delete clears the whole login surface.
delete from auth.users;

-- 3. Empty storage. Supabase ships a `storage.protect_delete` trigger
--    that blocks DELETE on storage.objects to prevent accidents. We
--    flip session_replication_role to `replica` so user-defined
--    triggers (including protect_delete) are skipped for this
--    statement, then restore the default. Physical files on S3 are
--    GC'd by the storage worker shortly after.
set local session_replication_role = replica;
delete from storage.objects;
set local session_replication_role = default;

commit;

-- Sanity check: every count below should be 0.
select 'auth.users'      as table, count(*) from auth.users
union all
select 'storage.objects' as table, count(*) from storage.objects
union all
select 'profiles'        as table, count(*) from public.profiles
union all
select 'posts'           as table, count(*) from public.posts
union all
select 'messages'        as table, count(*) from public.messages;
