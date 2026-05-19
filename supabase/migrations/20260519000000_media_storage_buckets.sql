-- Ensure media storage buckets exist with limits/MIME types that match the
-- Flutter MediaUploadService. The app was previously inlining base64 data URLs
-- into TEXT columns (posts.image_url, stories.media_url, reels.video_url,
-- messages.image_url/audio_url), which caused severe lag. New uploads now go
-- to these buckets and we only persist the public URL.
--
-- This migration is idempotent — safe to re-run.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880, -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'covers',
  'covers',
  true,
  10485760, -- 10 MB (cover photos can be a bit bigger)
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'posts',
  'posts',
  true,
  20971520, -- 20 MB for post images
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- The "stories" bucket is shared by stories, reels, and chat file attachments,
-- so MIME and size limits have to cover all three.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'stories',
  'stories',
  true,
  104857600, -- 100 MB so reels/videos fit
  array[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif',
    'video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v',
    'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/webm', 'audio/ogg',
    'application/pdf'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'voice-messages',
  'voice-messages',
  true,
  20971520, -- 20 MB
  array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/webm', 'audio/ogg']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- RLS policies on storage.objects. All uploads follow the "<auth.uid>/..."
-- folder convention from MediaUploadService. We drop and recreate so the
-- migration converges to a known good state regardless of what existed before.

do $$
declare
  bucket_name text;
begin
  foreach bucket_name in array array['avatars', 'covers', 'posts', 'stories', 'voice-messages']
  loop
    execute format(
      'drop policy if exists "tradeflow_read_%1$s" on storage.objects',
      bucket_name
    );
    execute format(
      'drop policy if exists "tradeflow_insert_%1$s" on storage.objects',
      bucket_name
    );
    execute format(
      'drop policy if exists "tradeflow_update_%1$s" on storage.objects',
      bucket_name
    );
    execute format(
      'drop policy if exists "tradeflow_delete_%1$s" on storage.objects',
      bucket_name
    );

    execute format($p$
      create policy "tradeflow_read_%1$s" on storage.objects
      for select to public
      using (bucket_id = %1$L)
    $p$, bucket_name);

    execute format($p$
      create policy "tradeflow_insert_%1$s" on storage.objects
      for insert to authenticated
      with check (
        bucket_id = %1$L
        and (storage.foldername(name))[1] = auth.uid()::text
      )
    $p$, bucket_name);

    execute format($p$
      create policy "tradeflow_update_%1$s" on storage.objects
      for update to authenticated
      using (
        bucket_id = %1$L
        and (storage.foldername(name))[1] = auth.uid()::text
      )
    $p$, bucket_name);

    execute format($p$
      create policy "tradeflow_delete_%1$s" on storage.objects
      for delete to authenticated
      using (
        bucket_id = %1$L
        and (storage.foldername(name))[1] = auth.uid()::text
      )
    $p$, bucket_name);
  end loop;
end $$;
