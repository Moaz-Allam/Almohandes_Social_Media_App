-- Tighten privacy defaults without changing the authenticated app flow.

-- Public buckets can serve public object URLs without broad storage.objects
-- SELECT policies. Dropping these policies prevents clients from listing every
-- file path in the bucket.
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
drop policy if exists "avatars_public_read" on storage.objects;
drop policy if exists "Chat images are publicly accessible" on storage.objects;
drop policy if exists "covers_public_read" on storage.objects;
drop policy if exists "posts_public_read" on storage.objects;
drop policy if exists "Anyone can view project attachments" on storage.objects;
drop policy if exists "reels_public_read" on storage.objects;
drop policy if exists "Anyone can view stories files" on storage.objects;
drop policy if exists "Story images are publicly accessible" on storage.objects;
drop policy if exists "stories_public_read" on storage.objects;
drop policy if exists "voice_public_read" on storage.objects;

-- Anonymous users should not be able to execute app runtime RPCs directly.
-- The OTP verification RPCs intentionally remain available before signup.
revoke execute on function public.complete_signup_profile_for_app(text, text, text, text, text, text)
  from public, anon;
grant execute on function public.complete_signup_profile_for_app(text, text, text, text, text, text)
  to authenticated;

revoke execute on function public.create_project_for_app(
  text, text, text, text, text, text, text, text, text, text, text,
  text[], text[], text[], text[], text, integer, text[], integer,
  text[], jsonb, text, text[], text, text, jsonb, text, text, text,
  text, text, numeric, numeric
) from public, anon;
grant execute on function public.create_project_for_app(
  text, text, text, text, text, text, text, text, text, text, text,
  text[], text[], text[], text[], text, integer, text[], integer,
  text[], jsonb, text, text[], text, text, jsonb, text, text, text,
  text, text, numeric, numeric
) to authenticated;

revoke execute on function public.apply_to_project_for_app(uuid, text, text, jsonb)
  from public, anon;
grant execute on function public.apply_to_project_for_app(uuid, text, text, jsonb)
  to authenticated;

revoke execute on function public.delete_current_user_for_app()
  from public, anon;
grant execute on function public.delete_current_user_for_app()
  to authenticated;

revoke execute on function public.get_home_feed(uuid, integer, integer)
  from public, anon;
grant execute on function public.get_home_feed(uuid, integer, integer)
  to authenticated;

revoke execute on function public.get_network_profiles_for_app(text, integer)
  from public, anon;
grant execute on function public.get_network_profiles_for_app(text, integer)
  to authenticated;

revoke execute on function public.get_projects_for_app(integer)
  from public, anon;
grant execute on function public.get_projects_for_app(integer)
  to authenticated;

revoke execute on function public.get_user_conversations(uuid)
  from public, anon;
grant execute on function public.get_user_conversations(uuid)
  to authenticated;

revoke execute on function public.request_connection_for_app(uuid, text)
  from public, anon;
grant execute on function public.request_connection_for_app(uuid, text)
  to authenticated;

revoke execute on function public.save_item_for_app(text, text, text, text, text, jsonb)
  from public, anon;
grant execute on function public.save_item_for_app(text, text, text, text, text, jsonb)
  to authenticated;

do $$
begin
  if to_regprocedure('public.activate_subscription_p(uuid)') is not null then
    execute 'revoke execute on function public.activate_subscription_p(uuid) from public, anon';
    execute 'grant execute on function public.activate_subscription_p(uuid) to authenticated';
  end if;

  if to_regprocedure('public.has_active_subscription(uuid)') is not null then
    execute 'revoke execute on function public.has_active_subscription(uuid) from public, anon';
    execute 'grant execute on function public.has_active_subscription(uuid) to authenticated';
  end if;
end
$$;

grant execute on function public.verify_otp_token(text, text)
  to anon, authenticated;
grant execute on function public.has_verified_signup_phone(text)
  to anon, authenticated;

-- Keep app notifications usable, but remove the policy that allowed an
-- unrestricted INSERT check. This still expects notification creation to happen
-- from authenticated app events.
drop policy if exists "Authenticated users create notifications" on public.notifications;
drop policy if exists "Authenticated users create scoped app notifications" on public.notifications;
create policy "Authenticated users create scoped app notifications"
  on public.notifications
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and profile_id is not null
    and coalesce(type, '') in (
      'message',
      'connection',
      'project',
      'comment',
      'like',
      'repost',
      'system'
    )
  );

do $$
begin
  if to_regclass('public.admin_audit_logs') is not null then
    execute 'drop policy if exists "System can insert audit logs" on public.admin_audit_logs';
  end if;
end
$$;

-- Pin mutable function search paths reported by the schema advisor.
do $$
begin
  if to_regprocedure('public.activate_subscription_p(uuid)') is not null then
    execute 'alter function public.activate_subscription_p(uuid) set search_path = public';
  end if;
  if to_regprocedure('public.get_admin_system_stats()') is not null then
    execute 'alter function public.get_admin_system_stats() set search_path = public';
  end if;
  if to_regprocedure('public.sync_user_email()') is not null then
    execute 'alter function public.sync_user_email() set search_path = public';
  end if;
  if to_regprocedure('public.get_admin_chat_monitor(integer)') is not null then
    execute 'alter function public.get_admin_chat_monitor(integer) set search_path = public';
  end if;
  if to_regprocedure('public.sync_profile_email()') is not null then
    execute 'alter function public.sync_profile_email() set search_path = public';
  end if;
  if to_regprocedure('public.log_admin_action(text,text,text,jsonb,jsonb)') is not null then
    execute 'alter function public.log_admin_action(text, text, text, jsonb, jsonb) set search_path = public';
  end if;
  if to_regprocedure('public.log_admin_action(text,text,uuid,jsonb,jsonb,jsonb)') is not null then
    execute 'alter function public.log_admin_action(text, text, uuid, jsonb, jsonb, jsonb) set search_path = public';
  end if;
  if to_regprocedure('public.is_super_admin()') is not null then
    execute 'alter function public.is_super_admin() set search_path = public';
  end if;
  if to_regprocedure('public.cleanup_expired_otps()') is not null then
    execute 'alter function public.cleanup_expired_otps() set search_path = public';
  end if;
end
$$;
