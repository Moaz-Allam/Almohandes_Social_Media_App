-- Temporarily accept Egyptian phone numbers in the signup OTP flow too.
-- The function name is kept for compatibility with existing RPCs.

create or replace function public.normalize_iraqi_phone_local10(p_phone text)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  v_phone text;
begin
  v_phone := regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g');

  if v_phone ~ '^\+9647[3-9][0-9]{8}$' then
    return '0' || substring(v_phone from 5);
  end if;

  if v_phone ~ '^009647[3-9][0-9]{8}$' then
    return '0' || substring(v_phone from 6);
  end if;

  if v_phone ~ '^07[3-9][0-9]{8}$' then
    return v_phone;
  end if;

  if v_phone ~ '^\+201[0125][0-9]{8}$' then
    return '0' || substring(v_phone from 4);
  end if;

  if v_phone ~ '^00201[0125][0-9]{8}$' then
    return '0' || substring(v_phone from 5);
  end if;

  if v_phone ~ '^01[0125][0-9]{8}$' then
    return v_phone;
  end if;

  return null;
end;
$$;
