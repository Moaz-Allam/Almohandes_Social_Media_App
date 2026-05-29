-- ============================================================
-- المهندس — allow a user to unfollow (delete their own `followers` row).
--
-- Follow already works (an upsert into `public.followers`), but there was
-- no path to remove the row, so following was one-way. This grants DELETE
-- to authenticated users and adds a row-scoped delete policy so a user can
-- only remove follow edges where they are the follower.
--
-- We intentionally do NOT toggle row level security here: if RLS is off on
-- this table the grant alone enables delete and the policy lies dormant; if
-- RLS is on the policy scopes the delete. Either way nothing else breaks.
-- Idempotent: safe to re-run.
-- ============================================================

do $$
begin
  if to_regclass('public.followers') is null then
    return;
  end if;

  execute 'grant delete on public.followers to authenticated';

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'followers'
      and policyname = 'Users unfollow their own follows'
  ) then
    execute $p$
      create policy "Users unfollow their own follows"
        on public.followers
        for delete
        to authenticated
        using (
          exists (
            select 1
            from public.profiles p
            where p.id = followers.follower_id
              and p.user_id = auth.uid()
          )
        )
    $p$;
  end if;
end $$;
