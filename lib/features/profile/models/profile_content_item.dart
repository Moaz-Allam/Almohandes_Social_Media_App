import 'package:flutter/material.dart';

final class ProfileContentItem {
  const ProfileContentItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
}

final class ProfileContentTabData {
  const ProfileContentTabData({required this.label, required this.items});

  final String label;
  final List<ProfileContentItem> items;
}
