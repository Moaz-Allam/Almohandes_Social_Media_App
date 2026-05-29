-- ============================================================
-- المهندس — phone_exists RPC: normalize the leading '+'.
--
-- Supabase's GoTrue backend stores auth.users.phone WITHOUT the
-- leading '+' (e.g. '9647712345678'), but the Flutter app sends
-- the full E.164 string ('+9647712345678'). The previous RPC did
-- a literal equality check, so every registered phone looked
-- "missing" and the login screen short-circuited to signup.
--
-- Stripping '+' on both sides makes the check work regardless of
-- which form the caller passes.
-- ============================================================

create or replace function public.phone_exists(p_phone text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from auth.users
     where phone = ltrim(coalesce(p_phone, ''), '+')
  );
$$;

revoke all on function public.phone_exists(text) from public;
grant execute on function public.phone_exists(text) to anon, authenticated;
