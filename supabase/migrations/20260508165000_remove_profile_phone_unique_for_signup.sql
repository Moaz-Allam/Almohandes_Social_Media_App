-- Public signup can create multiple test or business accounts that reuse the
-- same phone number. The auth trigger writes that phone into public.profiles,
-- so a unique profile-phone constraint turns signup into a 500 before the app
-- can show a useful message. Auth-level phone uniqueness remains untouched.
alter table if exists public.profiles
  drop constraint if exists profiles_phone_key;
