-- ============================================================
-- المهندس — story "seen" state + accurate view counts.
--
-- The story_views table, the increment_story_view() RPC, and
-- stories.views_count already exist on the remote, but three things were
-- missing/incorrect for the "seen by me" + "who viewed my story" UX:
--
--   1. story_views had no created_at, so the viewer list couldn't be ordered
--      by view time.
--   2. Only the story owner could SELECT story_views, so a viewer could not
--      learn which stories they had already seen — the "seen" ring never
--      persisted across app sessions.
--   3. increment_story_view() bumped views_count on EVERY call, even when the
--      (story, viewer) pair already existed, inflating the counter on re-views
--      (increment_reel_view() already guards this with IF FOUND).
-- ============================================================

------------------------------------------------------------------------------
-- 1. created_at so the viewer list can be ordered newest-first
------------------------------------------------------------------------------

alter table if exists public.story_views
  add column if not exists created_at timestamptz not null default now();

------------------------------------------------------------------------------
-- 2. Let a viewer read their own view rows (drives the persisted "seen" ring).
--    The existing "viewable by story owner" policy is kept untouched, so the
--    creator still sees every viewer while a viewer only ever sees their own
--    rows.
------------------------------------------------------------------------------

drop policy if exists "Viewers can read their own story views"
  on public.story_views;
create policy "Viewers can read their own story views"
  on public.story_views for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = story_views.viewer_profile_id
        and p.user_id = auth.uid()
    )
  );

------------------------------------------------------------------------------
-- 3. Only count a view once per (story, viewer).
--    Signature (uuid, uuid) matches the existing function so this replaces it
--    in place and preserves its EXECUTE grants.
------------------------------------------------------------------------------

create or replace function public.increment_story_view(
  "p_story_id" uuid,
  "p_viewer_profile_id" uuid
) returns void
  language plpgsql
  security definer
  set search_path to 'public'
as $$
begin
  if p_viewer_profile_id is not null then
    insert into public.story_views (story_id, viewer_profile_id)
    values (p_story_id, p_viewer_profile_id)
    on conflict (story_id, viewer_profile_id) do nothing;

    -- Only bump the counter when this was a genuinely new view.
    if found then
      update public.stories
      set views_count = coalesce(views_count, 0) + 1
      where id = p_story_id;
    end if;
  else
    -- Anonymous view (no profile) — keep the legacy increment behaviour.
    update public.stories
    set views_count = coalesce(views_count, 0) + 1
    where id = p_story_id;
  end if;
end;
$$;

------------------------------------------------------------------------------
-- 4. Re-derive views_count from the source of truth so any counters that were
--    inflated by the old unconditional increment are healed. Only writes rows
--    whose stored count actually differs.
------------------------------------------------------------------------------

update public.stories s
set views_count = coalesce((
  select count(*) from public.story_views v where v.story_id = s.id
), 0)
where coalesce(s.views_count, 0) <> coalesce((
  select count(*) from public.story_views v where v.story_id = s.id
), 0);
