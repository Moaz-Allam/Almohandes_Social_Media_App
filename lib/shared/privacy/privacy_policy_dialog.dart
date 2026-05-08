import 'package:flutter/material.dart';

void showPrivacyPolicyDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacy Policy'),
      content: const SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: SelectableText(
            _privacyPolicyText,
            style: TextStyle(height: 1.45, fontSize: 13.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

const _privacyPolicyText = '''
Last updated: May 8, 2026

This Privacy Policy explains how the app collects, uses, stores, protects, and deletes information when you create an account, use your profile, publish posts, upload media, create stories or reels, apply for projects, connect with other users, chat, or use premium features.

1. Information We Collect

Account information:
We collect the information you provide during registration and profile setup, including your name, email address, phone number, account type, location, specialization, profile bio, skills, avatar image, and cover image.

Profile and professional information:
We store the profile information you choose to publish, such as your role, project history, public profile details, connection status, profile image, background image, and other information shown to other users inside the app.

Content and media:
When you create posts, comments, stories, reels, projects, project applications, saved items, or reposts, we store the content you submit. This may include text, images, videos, audio, file names, file attachments, thumbnails, and metadata such as creation date and content type.

Messaging information:
When you use chat, we store messages, conversation participants, sent files, images, videos, voice messages, read status, timestamps, and connection-related chat records. Messages are used to deliver the chat experience and show unread counters.

Interaction information:
We store actions such as likes, comments, reposts, saved items, connection requests, accepted or rejected connections, project proposals, profile follows, notifications, and premium access state.

Technical information:
The app may process basic technical data needed to operate the service, such as session state, authentication tokens handled by Supabase, device/browser behavior necessary for media playback, and diagnostic error information.

2. How We Use Information

We use your information to:
- Create, authenticate, and manage your account.
- Show your profile, avatar, cover image, posts, stories, reels, projects, and applications.
- Let users discover each other in My Network according to account type and permissions.
- Send and receive messages, files, images, videos, and voice messages.
- Show notifications for messages, connection requests, accepted connections, project proposals, comments, likes, and reposts.
- Prevent duplicate project applications and keep connection/request states accurate.
- Save content you choose to save.
- Provide premium access and premium feature state.
- Improve app reliability, loading behavior, and user experience.
- Protect against misuse, duplicate actions, unauthorized access, and broken account states.

3. Visibility and Sharing Inside the App

Some information is visible to other users:
- Your public profile details, avatar, cover image, account type, and bio.
- Posts, reels, stories, comments, likes, reposts, and projects you publish.
- Project applications to the creator of the project.
- Connection state between you and another user.
- Messages only to conversation participants, subject to database security rules.

The app does not intentionally sell your personal data. Data is shared only as needed to provide the app features, operate the backend, enforce security, and comply with lawful requirements.

4. Files, Images, Videos, and Voice Messages

Uploaded or selected files may be stored as media content or encoded attachments depending on the app flow. Images and videos sent in chat may be shown inline. Other file types may be downloaded or opened by the receiving user. Do not upload sensitive documents unless you intend the recipient or relevant project owner to access them.

5. Authentication and Security

Authentication is handled through Supabase. Passwords are managed by Supabase authentication services and are not displayed by the app. Row Level Security policies are used to limit access to records such as profiles, messages, notifications, project applications, saved items, comments, and connections.

No system can guarantee perfect security. You are responsible for keeping your login information private and using a secure device.

6. Notifications and Counters

The app creates notifications and unread counters for events such as messages, connection requests, project proposals, comments, likes, and reposts. These records are used to update badges, message counts, chat list visibility, and sidebar notifications.

7. Account Deletion

When you delete your account, the app requests deletion of your profile and related user data, including related profile records, details, notifications, saved items, applications, comments, reposts, messages you sent, conversations, projects, stories, reels, followers, connection requests, and the authentication user where backend permissions allow it.

Some content may remain if required for legal, security, backup, or integrity reasons, or if deletion is blocked by backend configuration. If account deletion fails, the app should show an error instead of pretending the account was removed.

8. Data Retention

We keep information while your account exists or while it is needed to provide app features. Some deleted data may remain temporarily in backups or logs. Content shared with other users may remain visible until deletion is completed by the backend.

9. Your Choices

You can:
- Edit your profile bio and profile images.
- Choose what you publish.
- Delete saved items.
- Delete chats where supported.
- Block or remove connections where supported.
- Delete your account from settings.

10. Children and Sensitive Information

The app is intended for professional and project-related use. Do not submit sensitive personal information, government IDs, financial secrets, medical information, or private documents unless the feature requires it and you understand who can access it.

11. Changes to This Policy

This policy may be updated as features change. Continued use of the app after updates means you accept the updated policy.

12. Legal Basis and User Consent

By creating an account or continuing to use the app, you choose to provide the information needed for the app to operate. Some information is required to create an account, protect the platform, and deliver core features. Optional information, such as avatar, cover image, biography, skills, media, and files, is processed only when you add it or choose to send it.

13. Database Access and Row Level Security

The app relies on backend database permissions to decide which records each user can read, create, update, or delete. For example, users should only manage their own profile details, their own saved items, their own comments, their own project applications, and conversations they participate in. Project owners may see proposals submitted to their projects. Administrators may have broader visibility when needed to operate or moderate the platform.

14. Chat, Attachments, and Delivery State

Chat messages are stored with sender, conversation, content type, timestamp, read state, and attachment metadata. Images and videos may be previewed in the chat interface. Other file types may require download before opening. Delivery indicators, unread counters, and message notifications are generated from stored message records and may take a short time to update depending on connectivity.

15. Public Content, Reposts, and Saved Items

Posts, reels, stories, comments, project pages, and public profile information are intended to be visible to other users according to the app experience and database rules. Saved items are intended to be private to the saving user unless a backend rule or administrative process requires otherwise. Reposting public content may make it visible again through your profile or feed.

16. Premium Features and Payment

Premium status may be stored on your profile or subscription records so the app can decide whether to show premium dashboards, paid libraries, or payment prompts. Payment buttons may direct you to a configured payment provider. Do not enter payment details unless you trust the payment page and understand the purchase terms shown there.

17. Moderation, Blocking, and Safety

The app may store block records, reports, removed connections, deleted conversations, and moderation-related metadata. These records help reduce unwanted contact, prevent repeated abuse, and support administrative review. Blocking or deleting a chat may not remove every historical record from another participant's device or from protected backend logs.

18. Accuracy and Profile Consistency

The app attempts to keep your profile avatar, name, role, cover image, and connection state consistent across posts, reels, stories, comments, chats, notifications, project requests, and network cards. If data is cached for performance, the app may refresh it after sign in, sign out, upload, profile edit, connection changes, or other important events.

19. International and Third-Party Processing

Data may be processed by infrastructure providers used by this deployment, including Supabase and any configured storage, notification, analytics, hosting, or payment services. These services may process data in locations outside your country. Their own terms and privacy practices may apply.

20. Contact

For privacy or account deletion issues, contact the app administrator or support channel configured for this deployment.
''';
