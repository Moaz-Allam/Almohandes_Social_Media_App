-- Wipe legacy social-content rows. Most of these tables were filled with
-- base64-encoded media stored as text, which made the app extremely slow.
-- We're starting clean and keeping only the business-critical data:
-- profiles, projects, subscriptions/payments, courses, admin tables, and
-- system tables. Per-user role details (engineer/contractor/etc.) stay.
--
-- Many of the FK relations cascade, so deleting the top-level rows in a
-- single transaction is enough. We `truncate ... restart identity cascade`
-- for the heavy tables to also drop any orphan child rows in one shot.

begin;

-- Social feed content
truncate table
  public.post_likes,
  public.post_comments,
  public.post_reports,
  public.posts,
  public.story_likes,
  public.story_comments,
  public.story_views,
  public.stories,
  public.saved_reels,
  public.reel_likes,
  public.reel_comments,
  public.reel_reports,
  public.reel_views,
  public.reels,
  public.app_comments,
  public.app_reposts,
  public.comment_likes,
  public.saved_items
restart identity cascade;

-- Messaging
truncate table
  public.messages,
  public.muted_conversations,
  public.conversations
restart identity cascade;

-- Notifications + social graph + misc social signals
truncate table
  public.notifications,
  public.followers,
  public.connection_requests,
  public.ai_messages,
  public.ai_conversations,
  public.reviews,
  public.engineer_notes,
  public.badge_requests,
  public.user_reports
restart identity cascade;

-- Belt-and-braces: clear any remaining base64 references on the columns we
-- intentionally kept (profile avatars/covers, project images). These are
-- nullable, so we just null them out.
update public.profiles
   set avatar_url = null
 where avatar_url like 'data:%';

update public.profiles
   set cover_url = null
 where cover_url like 'data:%';

update public.profiles
   set cover_photo_url = null
 where cover_photo_url like 'data:%';

update public.projects
   set image_url = null
 where image_url like 'data:%';

commit;
