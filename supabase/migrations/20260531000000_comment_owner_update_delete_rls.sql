-- ============================================================
-- المهندس — allow comment authors to edit & delete their own comments.
--
-- app_comments shipped with only SELECT ("Comments are readable") and
-- INSERT ("Users create own comments") policies. With RLS enabled and no
-- UPDATE/DELETE policy, owner edits/deletes from the app affected zero rows
-- and surfaced as "تعذر تعديل/حذف التعليق". These two owner-scoped policies
-- close that gap. Deleting a parent also cascades to its replies and the
-- existing count triggers keep posts.comments_count / replies_count in sync.
-- ============================================================

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'app_comments'
      and policyname = 'Users update own comments'
  ) then
    create policy "Users update own comments"
      on public.app_comments for update to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = app_comments.profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = app_comments.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'app_comments'
      and policyname = 'Users delete own comments'
  ) then
    create policy "Users delete own comments"
      on public.app_comments for delete to authenticated
      using (
        exists (
          select 1 from public.profiles p
          where p.id = app_comments.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;
end $$;
