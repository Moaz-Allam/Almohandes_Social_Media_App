-- Allow the Flutter signup flow to create the current user's profile while
-- keeping profile writes scoped to the authenticated user.

do $$
declare
  v_table text;
  v_public_policy text;
  v_manage_policy text;
begin
  if to_regtype('public.user_role') is not null then
    alter type public.user_role add value if not exists 'engineer';
    alter type public.user_role add value if not exists 'contractor';
    alter type public.user_role add value if not exists 'client';
    alter type public.user_role add value if not exists 'craftsman';
    alter type public.user_role add value if not exists 'worker';
    alter type public.user_role add value if not exists 'machinery';
    alter type public.user_role add value if not exists 'admin';
  end if;

  if to_regclass('public.profiles') is not null then
    alter table public.profiles enable row level security;

    alter table public.profiles
      add column if not exists cover_url text;

    grant select on public.profiles to anon, authenticated;
    grant insert, update, delete on public.profiles to authenticated;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'profiles'
        and policyname = 'Profiles are publicly readable'
    ) then
      create policy "Profiles are publicly readable"
        on public.profiles
        for select
        using (true);
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'profiles'
        and policyname = 'Users create their own profile'
    ) then
      create policy "Users create their own profile"
        on public.profiles
        for insert
        to authenticated
        with check (user_id = auth.uid());
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'profiles'
        and policyname = 'Users update their own profile'
    ) then
      create policy "Users update their own profile"
        on public.profiles
        for update
        to authenticated
        using (user_id = auth.uid())
        with check (user_id = auth.uid());
    end if;

    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'profiles'
        and policyname = 'Users delete their own profile'
    ) then
      create policy "Users delete their own profile"
        on public.profiles
        for delete
        to authenticated
        using (user_id = auth.uid());
    end if;
  end if;

  foreach v_table in array array[
    'engineer_details',
    'contractor_details',
    'craftsman_details',
    'machinery_details'
  ]
  loop
    if to_regclass('public.' || v_table) is not null then
      execute format('alter table public.%I enable row level security', v_table);
      execute format('grant select on public.%I to anon, authenticated', v_table);
      execute format('grant insert, update, delete on public.%I to authenticated', v_table);

      v_public_policy := 'Public read ' || v_table;
      if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = v_table
          and policyname = v_public_policy
      ) then
        execute format(
          'create policy %I on public.%I for select using (true)',
          v_public_policy,
          v_table
        );
      end if;

      v_manage_policy := 'Users manage own ' || v_table;
      if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = v_table
          and policyname = v_manage_policy
      ) then
        execute format(
          'create policy %I on public.%I for all to authenticated using (
            exists (
              select 1
              from public.profiles p
              where p.id = %I.profile_id
                and p.user_id = auth.uid()
            )
          ) with check (
            exists (
              select 1
              from public.profiles p
              where p.id = %I.profile_id
                and p.user_id = auth.uid()
            )
          )',
          v_manage_policy,
          v_table,
          v_table,
          v_table
        );
      end if;
    end if;
  end loop;
end
$$;

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
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = v_user_id
  order by p.created_at desc nulls last
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
      nullif(trim(p_full_name), ''),
      nullif(trim(p_email), ''),
      nullif(trim(p_phone), ''),
      case coalesce(p_role, '')
        when 'engineer' then 'engineer'
        when 'contractor' then 'contractor'
        when 'client' then 'client'
        when 'craftsman' then 'craftsman'
        when 'worker' then 'worker'
        when 'machinery' then 'machinery'
        when 'admin' then 'admin'
        else 'engineer'
      end::user_role,
      case coalesce(p_governorate, '')
        when 'baghdad' then 'baghdad'
        when 'basra' then 'basra'
        when 'nineveh' then 'nineveh'
        when 'erbil' then 'erbil'
        when 'sulaymaniyah' then 'sulaymaniyah'
        when 'duhok' then 'duhok'
        when 'kirkuk' then 'kirkuk'
        when 'diyala' then 'diyala'
        when 'anbar' then 'anbar'
        when 'babylon' then 'babylon'
        when 'karbala' then 'karbala'
        when 'najaf' then 'najaf'
        when 'wasit' then 'wasit'
        when 'saladin' then 'saladin'
        when 'dhi_qar' then 'dhi_qar'
        when 'maysan' then 'maysan'
        when 'muthanna' then 'muthanna'
        when 'qadisiyah' then 'qadisiyah'
        else 'baghdad'
      end::governorate,
      nullif(trim(p_bio), '')
    )
    returning id into v_profile_id;
  else
    update public.profiles
    set
      full_name = nullif(trim(p_full_name), ''),
      email = nullif(trim(p_email), ''),
      phone = nullif(trim(p_phone), ''),
      role = case coalesce(p_role, '')
        when 'engineer' then 'engineer'
        when 'contractor' then 'contractor'
        when 'client' then 'client'
        when 'craftsman' then 'craftsman'
        when 'worker' then 'worker'
        when 'machinery' then 'machinery'
        when 'admin' then 'admin'
        else 'engineer'
      end::user_role,
      governorate = case coalesce(p_governorate, '')
        when 'baghdad' then 'baghdad'
        when 'basra' then 'basra'
        when 'nineveh' then 'nineveh'
        when 'erbil' then 'erbil'
        when 'sulaymaniyah' then 'sulaymaniyah'
        when 'duhok' then 'duhok'
        when 'kirkuk' then 'kirkuk'
        when 'diyala' then 'diyala'
        when 'anbar' then 'anbar'
        when 'babylon' then 'babylon'
        when 'karbala' then 'karbala'
        when 'najaf' then 'najaf'
        when 'wasit' then 'wasit'
        when 'saladin' then 'saladin'
        when 'dhi_qar' then 'dhi_qar'
        when 'maysan' then 'maysan'
        when 'muthanna' then 'muthanna'
        when 'qadisiyah' then 'qadisiyah'
        else 'baghdad'
      end::governorate,
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

create or replace function public.delete_current_user_for_app()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid;
  v_profile_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = v_user_id
  order by p.created_at desc nulls last
  limit 1;

  if v_profile_id is not null then
    if to_regclass('public.messages') is not null then
      execute 'delete from public.messages where sender_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.conversations') is not null then
      execute 'delete from public.conversations where participant_one = $1 or participant_two = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.notifications') is not null then
      execute 'delete from public.notifications where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.saved_items') is not null then
      execute 'delete from public.saved_items where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.project_applications') is not null then
      if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'project_applications'
          and column_name = 'reviewed_by'
      ) then
        execute 'delete from public.project_applications where profile_id = $1 or reviewed_by = $1'
          using v_profile_id;
      else
        execute 'delete from public.project_applications where profile_id = $1'
          using v_profile_id;
      end if;
    end if;

    if to_regclass('public.app_comments') is not null then
      execute 'delete from public.app_comments where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.app_reposts') is not null then
      execute 'delete from public.app_reposts where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.followers') is not null then
      execute 'delete from public.followers where follower_id = $1 or following_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.connection_requests') is not null then
      execute 'delete from public.connection_requests where requester_profile_id = $1 or receiver_profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.blocked_profiles') is not null then
      execute 'delete from public.blocked_profiles where blocker_profile_id = $1 or blocked_profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.stories') is not null then
      execute 'delete from public.stories where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.reels') is not null then
      execute 'delete from public.reels where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.posts') is not null then
      execute 'delete from public.posts where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.project_details') is not null
      and to_regclass('public.projects') is not null then
      execute 'delete from public.project_details where project_id in (select id from public.projects where profile_id = $1)'
        using v_profile_id;
    end if;

    if to_regclass('public.projects') is not null then
      execute 'delete from public.projects where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.engineer_details') is not null then
      execute 'delete from public.engineer_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.contractor_details') is not null then
      execute 'delete from public.contractor_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.craftsman_details') is not null then
      execute 'delete from public.craftsman_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.machinery_details') is not null then
      execute 'delete from public.machinery_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.subscriptions') is not null then
      execute 'delete from public.subscriptions where profile_id = $1'
        using v_profile_id;
    end if;

    delete from public.profiles
    where id = v_profile_id;
  end if;

  delete from public.profiles
  where user_id = v_user_id;

  delete from auth.users
  where id = v_user_id;
end;
$$;

grant execute on function public.delete_current_user_for_app()
  to authenticated;

create or replace function public.handle_new_auth_user_for_app()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
begin
  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = new.id
  order by p.created_at desc nulls last
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
        split_part(coalesce(new.email, ''), '@', 1),
        'مستخدم'
      ),
      nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''),
      nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''),
      case coalesce(new.raw_user_meta_data->>'role', '')
        when 'engineer' then 'engineer'
        when 'contractor' then 'contractor'
        when 'client' then 'client'
        when 'craftsman' then 'craftsman'
        when 'worker' then 'worker'
        when 'machinery' then 'machinery'
        else 'engineer'
      end::user_role,
      case coalesce(new.raw_user_meta_data->>'governorate', '')
        when 'baghdad' then 'baghdad'
        when 'basra' then 'basra'
        when 'nineveh' then 'nineveh'
        when 'erbil' then 'erbil'
        when 'sulaymaniyah' then 'sulaymaniyah'
        when 'duhok' then 'duhok'
        when 'kirkuk' then 'kirkuk'
        when 'diyala' then 'diyala'
        when 'anbar' then 'anbar'
        when 'babylon' then 'babylon'
        when 'karbala' then 'karbala'
        when 'najaf' then 'najaf'
        when 'wasit' then 'wasit'
        when 'saladin' then 'saladin'
        when 'dhi_qar' then 'dhi_qar'
        when 'maysan' then 'maysan'
        when 'muthanna' then 'muthanna'
        when 'qadisiyah' then 'qadisiyah'
        else 'baghdad'
      end::governorate,
      nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), '')
    );
  else
    update public.profiles
    set
      full_name = coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        split_part(coalesce(new.email, ''), '@', 1),
        full_name
      ),
      email = nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''),
      phone = nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''),
      role = case coalesce(new.raw_user_meta_data->>'role', '')
        when 'engineer' then 'engineer'
        when 'contractor' then 'contractor'
        when 'client' then 'client'
        when 'craftsman' then 'craftsman'
        when 'worker' then 'worker'
        when 'machinery' then 'machinery'
        else 'engineer'
      end::user_role,
      governorate = case coalesce(new.raw_user_meta_data->>'governorate', '')
        when 'baghdad' then 'baghdad'
        when 'basra' then 'basra'
        when 'nineveh' then 'nineveh'
        when 'erbil' then 'erbil'
        when 'sulaymaniyah' then 'sulaymaniyah'
        when 'duhok' then 'duhok'
        when 'kirkuk' then 'kirkuk'
        when 'diyala' then 'diyala'
        when 'anbar' then 'anbar'
        when 'babylon' then 'babylon'
        when 'karbala' then 'karbala'
        when 'najaf' then 'najaf'
        when 'wasit' then 'wasit'
        when 'saladin' then 'saladin'
        when 'dhi_qar' then 'dhi_qar'
        when 'maysan' then 'maysan'
        when 'muthanna' then 'muthanna'
        when 'qadisiyah' then 'qadisiyah'
        else 'baghdad'
      end::governorate,
      bio = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), ''), bio),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'on_auth_user_created_create_app_profile'
  ) then
    create trigger on_auth_user_created_create_app_profile
      after insert on auth.users
      for each row execute function public.handle_new_auth_user_for_app();
  end if;
end
$$;
