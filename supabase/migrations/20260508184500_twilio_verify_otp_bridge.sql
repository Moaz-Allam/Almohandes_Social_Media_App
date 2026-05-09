-- Allow the verify-otp Edge Function to persist a successful Twilio Verify check.

create or replace function public.mark_signup_phone_verified(p_phone text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text;
begin
  v_phone := public.normalize_iraqi_phone_local10(p_phone);

  if v_phone is null then
    return false;
  end if;

  insert into public.signup_phone_verifications (
    phone_local10,
    verified_at,
    expires_at
  )
  values (
    v_phone,
    now(),
    now() + interval '30 minutes'
  )
  on conflict (phone_local10)
  do update set
    verified_at = excluded.verified_at,
    expires_at = excluded.expires_at;

  return true;
end;
$$;

revoke all on function public.mark_signup_phone_verified(text) from public;
grant execute on function public.mark_signup_phone_verified(text) to service_role;
