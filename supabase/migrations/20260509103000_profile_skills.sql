-- Persist signup/profile skills so they can appear in the profile "About" tab.

alter table if exists public.profiles
  add column if not exists skills text[] not null default '{}';
