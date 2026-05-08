// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<String?> requestNotificationPermission() {
  return html.Notification.requestPermission();
}

bool get supportsNativeNotificationPermission => true;
