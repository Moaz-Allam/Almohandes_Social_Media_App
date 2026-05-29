-- ============================================================
-- المهندس — Contact-field privacy on public.profiles.
--
-- public.profiles is intentionally world-readable (RLS USING(true) plus a
-- table-wide SELECT grant) so the network/people lists and embedded post
-- authors resolve for everyone. That blanket grant also exposed the
-- `email` and `phone` columns of EVERY user to any anon/authenticated
-- caller (e.g. `select email, phone from profiles where id = <anyone>`).
--
-- This migration narrows the SELECT grant to every column EXCEPT
-- email/phone, and adds a SECURITY DEFINER `get_my_profile()` RPC so the
-- owner can still read their own contact details. App owner-read paths
-- (current-profile load, premium checkout) call the RPC; all public reads
-- already select explicit non-sensitive columns, so they are unaffected.
-- ============================================================

do $$
declare
  v_cols text;
begin
  if to_regclass('public.profiles') is null then
    return;
  end if;

  -- Drop the blanket SELECT grant that exposed every column...
  revoke select on public.profiles from anon;
  revoke select on public.profiles from authenticated;

  -- ...and re-grant SELECT on every column except the sensitive contact
  -- fields. Built dynamically (ordered by column position) so any new
  -- non-sensitive column is covered automatically when this runs.
  select string_agg(quote_ident(column_name), ', ' order by ordinal_position)
    into v_cols
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'profiles'
    and column_name not in ('email', 'phone');

  if v_cols is not null then
    execute format(
      'grant select (%s) on public.profiles to anon, authenticated',
      v_cols
    );
  end if;
end
$$;

-- Owner-only accessor for the full profile row (including email/phone).
-- SECURITY DEFINER so it bypasses the column grant above; it can only ever
-- return the caller's own row (where user_id = auth.uid()).
create or replace function public.get_my_profile()
returns setof public.profiles
language sql
stable
security definer
set search_path = public
as $$
  select *
  from public.profiles
  where user_id = auth.uid()
  order by created_at desc nulls last
  limit 1;
$$;

revoke all on function public.get_my_profile() from public;
grant execute on function public.get_my_profile() to authenticated;
