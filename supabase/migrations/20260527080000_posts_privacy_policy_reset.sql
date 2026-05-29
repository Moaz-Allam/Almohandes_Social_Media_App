-- ============================================================
-- المهندس — enforce post privacy definitively.
--
-- Some legacy "USING (true)" SELECT policies on posts survived under
-- names not covered by earlier drops, so private profiles' posts were
-- still visible to everyone. Drop ALL select-capable broad policies
-- dynamically and install a single privacy-aware SELECT policy.
--
-- Owner FOR-ALL policies (scoped to the author) are left intact so
-- authors still see/manage their own posts.
-- ============================================================

do $$
declare
  r record;
begin
  for r in
    select policyname
      from pg_policies
     where schemaname = 'public'
       and tablename = 'posts'
       and (cmd = 'SELECT' or (cmd = 'ALL' and qual = 'true'))
  loop
    execute format('drop policy if exists %I on public.posts', r.policyname);
  end loop;
end $$;

create policy "Posts visible per profile privacy" on public.posts
for select using (
  -- author sees all of their own posts (incl. archived)
  profile_id in (
    select id from public.profiles where user_id = auth.uid()
  )
  or (
    -- everyone else: only active posts of profiles they may view
    (((is_archived = false) or (is_archived is null)) and (is_active = true))
    and public.can_view_profile_content(profile_id)
  )
);
