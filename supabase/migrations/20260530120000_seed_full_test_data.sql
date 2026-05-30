-- ============================================================
-- المهندس — full seed of verified test data (no OTP needed).
--
-- Creates 12 phone-confirmed users: TWO of every account type,
-- all verified. The two engineers differ on entitlement: the first
-- has an active subscription (sees the Premium dashboard), the
-- second is inactive (sees the Premium access/upsell screen).
--
-- It also seeds:
--   * projects for both companies AND both engineers
--   * jobs for both companies
--   * posts for every user type, five of them with images
--     (uploaded to the public 'posts' bucket under seed/)
--
-- Idempotent: skips phones / rows that already exist. Profiles are
-- auto-created by the on-auth-user-created triggers from
-- raw_user_meta_data.
--
-- Login for any of them: phone (local form) + password "Test1234".
--   م. أحمد       0771 000 0021  engineer  (active subscription)
--   م. سارة       0771 000 0022  engineer  (no subscription)
--   شركة الإعمار  0771 000 0023  contractor
--   شركة دجلة     0771 000 0024  contractor
--   حسين الحداد   0771 000 0025  craftsman
--   علي النجار    0771 000 0026  craftsman
--   كرار العامل   0771 000 0027  worker
--   محمد العامل   0771 000 0028  worker
--   مؤسسة الرافدين 0771 000 0029 machinery (equipment)
--   شركة المعدات  0771 000 0030  machinery (equipment)
--   إدارة المنصة  0771 000 0031  admin
--   مشرف المنصة   0771 000 0032  admin
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

-- ---- 1) Users + profiles + one post each --------------------
do $$
declare
  rec record;
  v_user_id uuid;
  v_profile_id uuid;
  v_img_base text := 'https://gwuzlcmuxcokfpnaofjc.supabase.co/storage/v1/object/public/posts/seed/';
begin
  for rec in
    select * from (values
      -- phone,            full_name,                role,         gov,       bio,                                            post,                                                                          image,      sub_active
      ('9647710000021', 'م. أحمد الجبوري',          'engineer',   'baghdad', 'مهندس مدني - خبرة 10 سنوات في الأبراج السكنية',  'بدأنا اليوم تنفيذ برج سكني من 15 طابقاً في بغداد. فخور بالفريق الهندسي.',        'img4.jpg', true ),
      ('9647710000022', 'م. سارة العبيدي',          'engineer',   'basra',   'مهندسة معمارية - تصاميم حديثة ومستدامة',         'تصميم معماري جديد لواجهة مبنى إداري في البصرة. آراؤكم تهمني.',                    'img7.jpg', false),
      ('9647710000023', 'شركة الإعمار العراقية',    'contractor', 'baghdad', 'شركة مقاولات عامة وإنشاءات كبرى',                'نعلن عن إنجاز المرحلة الأولى من مجمعنا التجاري في بغداد.',                        NULL,       false),
      ('9647710000024', 'شركة دجلة للمقاولات',       'contractor', 'basra',   'مقاولات وبنى تحتية ومشاريع إسكان',               'مشاريع إسكان جديدة قادمة في البصرة خلال الأشهر المقبلة.',                          NULL,       false),
      ('9647710000025', 'حسين الحداد',              'craftsman',  'najaf',   'حرفي حدادة وأعمال معدنية',                       'أعمال حدادة وأبواب ونوافذ بأعلى جودة. شاهدوا آخر أعمالنا.',                        'img6.jpg', false),
      ('9647710000026', 'علي النجار',               'craftsman',  'karbala', 'حرفي نجارة وأثاث مخصص',                          'أثاث خشبي مصنوع يدوياً حسب الطلب في كربلاء.',                                      NULL,       false),
      ('9647710000027', 'كرار العامل',              'worker',     'baghdad', 'عامل بناء وتشطيبات',                             'متوفر للعمل في مشاريع البناء والتشطيب في بغداد.',                                  NULL,       false),
      ('9647710000028', 'محمد عامل البناء',          'worker',     'basra',   'عامل بناء وصب خرسانة',                           'خبرة في صب الخرسانة والأعمال الإنشائية. جاهز للعمل.',                              NULL,       false),
      ('9647710000029', 'مؤسسة الرافدين للمعدات',    'machinery',  'erbil',   'تأجير آليات ومعدات ثقيلة',                       'رافعات وحفارات وشفلات متاحة للإيجار اليومي في أربيل.',                            'img8.jpg', false),
      ('9647710000030', 'شركة المعدات الثقيلة',      'machinery',  'baghdad', 'بيع وتأجير المعدات الإنشائية',                   'وصلت دفعة جديدة من المعدات الثقيلة. تواصلوا معنا.',                                NULL,       false),
      ('9647710000031', 'إدارة منصة المهندس',        'admin',      'baghdad', 'الحساب الرسمي لإدارة المنصة',                    'مرحباً بكم في منصة المهندس. نعمل على تطوير تجربتكم باستمرار.',                     'img5.jpg', false),
      ('9647710000032', 'مشرف المنصة',              'admin',      'najaf',   'فريق الإشراف والدعم',                            'لأي استفسار أو دعم تقني تواصلوا مع فريق الإشراف.',                                 NULL,       false)
    ) as t(phone, full_name, role, gov, bio, post, image, sub_active)
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

    -- Profile is auto-created by the auth triggers; grab the freshest one.
    select id into v_profile_id
      from public.profiles
     where user_id = v_user_id
     order by created_at desc nulls last
     limit 1;

    if v_profile_id is not null then
      -- Everyone is verified.
      update public.profiles
         set is_verified = true
       where id = v_profile_id;

      -- Entitlement: only the active engineer gets Premium.
      if rec.sub_active then
        update public.profiles
           set subscription_status = 'active',
               has_pro_badge = true
         where id = v_profile_id;

        -- Best-effort real subscription row (table lives in the base
        -- project and may carry extra columns); never block the seed on it.
        if to_regclass('public.subscriptions') is not null then
          begin
            if not exists (
              select 1 from public.subscriptions
               where profile_id = v_profile_id and status = 'active'
            ) then
              insert into public.subscriptions (profile_id, status, expires_at)
              values (v_profile_id, 'active', now() + interval '365 days');
            end if;
          exception when others then
            null; -- schema mismatch: profiles flags already grant access
          end;
        end if;
      end if;

      -- One post per user; image post when an image is assigned.
      if not exists (
        select 1 from public.posts
         where profile_id = v_profile_id and content = rec.post
      ) then
        if rec.image is not null then
          insert into public.posts (profile_id, content, image_url, post_type, is_active)
          values (v_profile_id, rec.post, v_img_base || rec.image, 'image', true);
        else
          insert into public.posts (profile_id, content, post_type, is_active)
          values (v_profile_id, rec.post, 'general', true);
        end if;
      end if;
    end if;
  end loop;
end $$;

-- ---- 2) Projects: both companies AND both engineers ---------
do $$
declare
  rec record;
  v_profile_id uuid;
begin
  for rec in
    select * from (values
      -- phone,            title,                        description,                                              gov,       budget_min, budget_max
      ('9647710000021', 'تصميم برج سكني - 15 طابق',     'تصميم وإشراف هندسي على برج سكني حديث في قلب بغداد.',         'baghdad', 80000000,  150000000),
      ('9647710000022', 'واجهة مبنى إداري',             'تصميم معماري لواجهة زجاجية مستدامة لمبنى إداري في البصرة.',  'basra',   30000000,  60000000 ),
      ('9647710000023', 'مجمع تجاري متعدد الطوابق',      'تنفيذ مجمع تجاري بمساحة 5000 م2 مع مواقف سيارات.',           'baghdad', 200000000, 400000000),
      ('9647710000023', 'تطوير بنية تحتية لحي سكني',     'شبكات مياه ومجاري وطرق داخلية لحي سكني جديد.',               'baghdad', 120000000, 250000000),
      ('9647710000024', 'مشروع إسكان - 200 وحدة',        'بناء مجمع إسكان متكامل يضم 200 وحدة سكنية في البصرة.',       'basra',   300000000, 600000000),
      ('9647710000024', 'جسر معلق فوق نهر',              'دراسة وتنفيذ جسر معلق يربط ضفتي النهر في البصرة.',           'basra',   500000000, 900000000)
    ) as t(phone, title, description, gov, budget_min, budget_max)
  loop
    select p.id into v_profile_id
      from public.profiles p
      join auth.users u on u.id = p.user_id
     where u.phone = rec.phone
     order by p.created_at desc nulls last
     limit 1;

    if v_profile_id is not null
       and not exists (
         select 1 from public.projects
          where profile_id = v_profile_id and title = rec.title
       ) then
      insert into public.projects (
        profile_id, title, description, governorate, budget_min, budget_max, status
      ) values (
        v_profile_id, rec.title, rec.description, rec.gov, rec.budget_min, rec.budget_max, 'planning'
      );
    end if;
  end loop;
end $$;

-- ---- 3) Jobs: both companies --------------------------------
do $$
declare
  rec record;
  v_profile_id uuid;
begin
  for rec in
    select * from (values
      -- phone,            title,                description,                                                   company_name,            location, job_type,    category,  salary_range,            requirements
      ('9647710000023', 'مهندس موقع',          'مطلوب مهندس موقع للإشراف على تنفيذ المجمع التجاري في بغداد.',    'شركة الإعمار العراقية',  'بغداد',  'full-time', 'مدني',    '1,500,000 - 2,500,000 د.ع', 'خبرة 3 سنوات في الإشراف على مواقع البناء.'),
      ('9647710000023', 'مشرف تنفيذ',          'الإشراف على فرق العمل ومتابعة سير المشاريع وفق الجداول.',        'شركة الإعمار العراقية',  'بغداد',  'contract',  'مدني',    '1,200,000 - 1,800,000 د.ع', 'القدرة على إدارة فرق العمل ومتابعة الجداول الزمنية.'),
      ('9647710000024', 'عامل بناء',           'مطلوب عمال بناء للعمل في مشاريع الإسكان الجديدة في البصرة.',     'شركة دجلة للمقاولات',     'البصرة', 'full-time', 'مدني',    '900,000 - 1,300,000 د.ع',   'خبرة في أعمال البناء والصب. الالتزام بالدوام.'),
      ('9647710000024', 'سائق معدات ثقيلة',     'تشغيل وقيادة المعدات الثقيلة في مواقع العمل بالبصرة.',           'شركة دجلة للمقاولات',     'البصرة', 'part-time', 'معدات',   '1,000,000 - 1,500,000 د.ع', 'إجازة سوق نافذة وخبرة في قيادة الشفلات والحفارات.')
    ) as t(phone, title, description, company_name, location, job_type, category, salary_range, requirements)
  loop
    select p.id into v_profile_id
      from public.profiles p
      join auth.users u on u.id = p.user_id
     where u.phone = rec.phone
     order by p.created_at desc nulls last
     limit 1;

    if v_profile_id is not null
       and not exists (
         select 1 from public.jobs
          where profile_id = v_profile_id and title = rec.title
       ) then
      insert into public.jobs (
        profile_id, title, description, company_name, location,
        job_type, category, salary_range, requirements, is_active
      ) values (
        v_profile_id, rec.title, rec.description, rec.company_name, rec.location,
        rec.job_type, rec.category, rec.salary_range, rec.requirements, true
      );
    end if;
  end loop;
end $$;
