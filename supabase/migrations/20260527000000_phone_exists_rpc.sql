-- ============================================================
-- المهندس — phone_exists RPC (mirrors alqafila)
-- Lets the signup phone screen short-circuit before asking for a
-- password when the number is already registered, and lets the
-- login phone screen short-circuit before asking for a password
-- when the number is NOT registered. The same info is already
-- exposed by signUp's error message, so this just moves the
-- check earlier in the UX.
-- ============================================================

create or replace function public.phone_exists(p_phone text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from auth.users where phone = p_phone
  );
$$;

revoke all on function public.phone_exists(text) from public;
grant execute on function public.phone_exists(text) to anon, authenticated;
