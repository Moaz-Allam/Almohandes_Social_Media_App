-- ============================================================
-- المهندس — seed verified test accounts (no OTP needed).
--
-- Creates phone-confirmed users with a password, across different
-- user types, each with one post. Idempotent: skips phones that
-- already exist. Profiles are auto-created by the on-auth-user-created
-- triggers from raw_user_meta_data.
--
-- Login for any of them: phone (local form) + password "Test1234".
--   علي 0771 000 0011   (engineer)
--   شركة 0771 000 0012  (contractor)
--   حسن 0771 000 0013   (craftsman)
--   كريم 0771 000 0014  (worker)
--   مؤسسة 0771 000 0015 (machinery)
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

do $$
declare
  rec record;
  v_user_id uuid;
  v_profile_id uuid;
begin
  for rec in
    select * from (values
      ('9647710000011', 'علي المهندس',          'engineer',   'baghdad', 'مهندس مدني - خبرة 8 سنوات في المشاريع السكنية', 'أول منشور لي كمهندس مدني على منصة المهندس. سعيد بالانضمام!'),
      ('9647710000012', 'شركة البناء الحديث',   'contractor', 'basra',   'شركة مقاولات عامة وإنشاءات',                    'نعلن عن انطلاق مشاريع إنشائية جديدة في البصرة. تابعونا.'),
      ('9647710000013', 'حسن النجار',            'craftsman',  'najaf',   'حرفي نجارة وأثاث مخصص',                          'أعمال نجارة وأثاث بأعلى جودة وأسعار منافسة.'),
      ('9647710000014', 'كريم العامل',           'worker',     'karbala', 'عامل بناء وتشطيبات',                             'متوفر للعمل في مشاريع البناء والتشطيب في كربلاء.'),
      ('9647710000015', 'مؤسسة المعدات الثقيلة', 'machinery',  'erbil',   'تأجير آليات ومعدات ثقيلة',                       'لدينا رافعات وشفلات وحفارات متاحة للإيجار اليومي.')
    ) as t(phone, full_name, role, gov, bio, post)
  loop
    if exists (select 1 from auth.users where phone = rec.phone) then
      select id into v_user_id from auth.users where phone = rec.phone;
    else
      v_user_id := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role,
        phone, phone_confirmed_at,
        encrypted_password,
        raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at,
        confirmation_token, recovery_token,
        email_change_token_new, email_change, email_change_token_current,
        phone_change, phone_change_token, reauthentication_token
      ) values (
        '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
        rec.phone, now(),
        extensions.crypt('Test1234', extensions.gen_salt('bf')),
        jsonb_build_object('provider', 'phone', 'providers', jsonb_build_array('phone')),
        jsonb_build_object(
          'full_name', rec.full_name,
          'phone', '+' || rec.phone,
          'role', rec.role,
          'governorate', rec.gov,
          'bio', rec.bio
        ),
        now(), now(),
        '', '', '', '', '', '', '', ''
      );

      -- Phone identity so GoTrue treats the account as fully provisioned.
      insert into auth.identities (
        id, user_id, identity_data, provider, provider_id,
        created_at, updated_at, last_sign_in_at
      ) values (
        gen_random_uuid(), v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'phone', rec.phone),
        'phone', v_user_id::text,
        now(), now(), now()
      )
      on conflict (provider_id, provider) do nothing;
    end if;

    -- Profile is auto-created by the auth triggers; grab it and add a post.
    select id into v_profile_id
      from public.profiles
     where user_id = v_user_id
     order by created_at desc nulls last
     limit 1;

    if v_profile_id is not null
       and not exists (select 1 from public.posts where profile_id = v_profile_id) then
      insert into public.posts (profile_id, content, post_type, is_active)
      values (v_profile_id, rec.post, 'general', true);
    end if;
  end loop;
end $$;
