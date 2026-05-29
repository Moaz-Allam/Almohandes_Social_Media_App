-- ============================================================
-- المهندس — enable Supabase Realtime for live messages +
-- notifications.
--
-- Adds the three relevant tables to the `supabase_realtime`
-- publication so postgres_changes events are streamed to
-- subscribed clients. RLS still applies: each client only
-- receives rows its SELECT policy allows (its own messages /
-- notifications), so no extra authorization is needed.
--
-- REPLICA IDENTITY FULL makes UPDATE/DELETE events carry the
-- full old row, so client-side filters (e.g. notifications by
-- profile_id) work on updates and deletes too.
-- ============================================================

do $$
declare
  t text;
begin
  foreach t in array array['messages', 'notifications', 'conversations'] loop
    if not exists (
      select 1
        from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = t
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I', t
      );
    end if;
  end loop;
end $$;

alter table public.messages replica identity full;
alter table public.notifications replica identity full;
alter table public.conversations replica identity full;
