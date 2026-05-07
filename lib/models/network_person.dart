import 'package:flutter/material.dart';

final class NetworkPerson {
  const NetworkPerson({
    required this.id,
    this.profileId,
    required this.name,
    required this.title,
    required this.color,
    this.badge,
    this.contextLine = 'بغداد · العراق',
    this.actionLabel = 'تواصل',
    this.isCompany = false,
  });

  final String id;
  final String? profileId;
  final String name;
  final String title;
  final Color color;
  final String? badge;
  final String contextLine;
  final String actionLabel;
  final bool isCompany;
}
