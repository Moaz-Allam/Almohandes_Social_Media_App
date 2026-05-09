-- Allow the app to create phone-first accounts without leaking the internal
-- synthetic auth email into public profile rows.

create or replace function public.complete_signup_profile_for_app(
  p_full_name text,
  p_email text,
  p_phone text,
  p_role text,
  p_governorate text,
  p_bio text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_profile_id uuid;
  v_profile_email text;
begin
  v_user_id := auth.uid();
  v_profile_email := nullif(trim(coalesce(p_email, '')), '');

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = v_user_id
  order by p.created_at desc nulls last, p.id
  limit 1;

  if v_profile_id is null then
    insert into public.profiles (
      user_id,
      full_name,
      email,
      phone,
      role,
      governorate,
      bio
    )
    values (
      v_user_id,
      coalesce(nullif(trim(p_full_name), ''), 'User'),
      v_profile_email,
      nullif(trim(p_phone), ''),
      public.app_safe_user_role(p_role),
      public.app_safe_governorate(p_governorate),
      nullif(trim(p_bio), '')
    )
    returning id into v_profile_id;
  else
    update public.profiles
    set
      full_name = coalesce(nullif(trim(p_full_name), ''), full_name),
      email = v_profile_email,
      phone = nullif(trim(p_phone), ''),
      role = public.app_safe_user_role(p_role),
      governorate = public.app_safe_governorate(p_governorate),
      bio = nullif(trim(p_bio), ''),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return v_profile_id;
end;
$$;

grant execute on function public.complete_signup_profile_for_app(
  text,
  text,
  text,
  text,
  text,
  text
) to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_email text;
begin
  v_profile_email := nullif(trim(coalesce(new.raw_user_meta_data->>'email', '')), '');
  if v_profile_email is null
     and nullif(trim(coalesce(new.email, '')), '') is not null
     and new.email not ilike '%@phone.engineer.local' then
    v_profile_email := nullif(trim(new.email), '');
  end if;

  insert into public.profiles (
    user_id,
    email,
    full_name,
    role,
    governorate
  )
  values (
    new.id,
    v_profile_email,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      split_part(coalesce(nullif(v_profile_email, ''), new.email, ''), '@', 1),
      'User'
    ),
    public.app_safe_user_role(new.raw_user_meta_data->>'role'),
    public.app_safe_governorate(new.raw_user_meta_data->>'governorate')
  )
  on conflict (user_id)
  do update set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    role = coalesce(public.profiles.role, excluded.role),
    governorate = coalesce(public.profiles.governorate, excluded.governorate),
    updated_at = now();

  return new;
end;
$$;

create or replace function public.handle_new_auth_user_for_app()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_profile_email text;
begin
  v_profile_email := nullif(trim(coalesce(new.raw_user_meta_data->>'email', '')), '');
  if v_profile_email is null
     and nullif(trim(coalesce(new.email, '')), '') is not null
     and new.email not ilike '%@phone.engineer.local' then
    v_profile_email := nullif(trim(new.email), '');
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = new.id
  order by p.created_at desc nulls last, p.id
  limit 1;

  if v_profile_id is null then
    insert into public.profiles (
      user_id,
      full_name,
      email,
      phone,
      role,
      governorate,
      bio
    )
    values (
      new.id,
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        split_part(coalesce(nullif(v_profile_email, ''), new.email, ''), '@', 1),
        'User'
      ),
      v_profile_email,
      nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''),
      public.app_safe_user_role(new.raw_user_meta_data->>'role'),
      public.app_safe_governorate(new.raw_user_meta_data->>'governorate'),
      nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), '')
    );
  else
    update public.profiles
    set
      full_name = coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        full_name
      ),
      email = v_profile_email,
      phone = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''), phone),
      role = public.app_safe_user_role(coalesce(new.raw_user_meta_data->>'role', role::text)),
      governorate = public.app_safe_governorate(coalesce(new.raw_user_meta_data->>'governorate', governorate::text)),
      bio = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), ''), bio),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return new;
end;
$$;

create or replace function public.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set email = case
      when new.email ilike '%@phone.engineer.local' then null
      else new.email
    end
  where user_id = new.id;

  return new;
end;
$$;

create or replace function public.sync_user_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set email = case
      when new.email ilike '%@phone.engineer.local' then null
      else new.email
    end
  where user_id = new.id or id = new.id;

  return new;
end;
$$;
