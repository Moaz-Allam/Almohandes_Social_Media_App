-- Restrict direct API execution of SECURITY DEFINER helpers.
-- Anonymous signup still needs OTP verification checks, but service/internal
-- helpers should not be callable from the public API.

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.proname not in (
        'verify_otp_token',
        'has_verified_signup_phone'
      )
  loop
    execute format(
      'revoke execute on function %s from public, anon',
      fn.signature
    );
  end loop;
end
$$;

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'app_normalize_conversation_participants',
        'app_notify_on_comment',
        'app_notify_on_connection_request',
        'app_notify_on_message',
        'app_notify_on_post_like',
        'app_notify_on_project_application',
        'app_notify_on_reel_like',
        'app_notify_once',
        'app_sync_profile_cover_columns',
        'app_touch_conversation',
        'app_update_connection_counts',
        'check_rate_limit',
        'cleanup_expired_otps',
        'cleanup_old_rate_limits',
        'create_notification',
        'create_signup_otp',
        'handle_new_auth_user_for_app',
        'handle_new_user',
        'mark_signup_phone_verified',
        'notify_admins_on_report',
        'notify_craftsman_on_contact',
        'notify_on_follow',
        'rls_auto_enable',
        'sync_profile_email',
        'update_follower_counts',
        'update_post_comments_count',
        'update_post_likes_count',
        'update_reel_comments_count',
        'update_reel_likes_count',
        'update_updated_at_column'
      )
  loop
    execute format(
      'revoke execute on function %s from public, anon, authenticated',
      fn.signature
    );
    execute format(
      'grant execute on function %s to service_role',
      fn.signature
    );
  end loop;
end
$$;

grant execute on function public.verify_otp_token(text, text)
  to anon, authenticated;
grant execute on function public.has_verified_signup_phone(text)
  to anon, authenticated;
