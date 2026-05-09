import 'package:flutter/material.dart';

final class SettingsItem {
  const SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
