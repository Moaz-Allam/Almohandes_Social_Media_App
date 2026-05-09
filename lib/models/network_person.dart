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
    this.avatarUrl,
    this.connectionStatus = 'none',
    this.isFollowed = false,
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
  final String? avatarUrl;
  final String connectionStatus;
  final bool isFollowed;

  bool get isPendingConnection => connectionStatus == 'pending';
  bool get isConnected => connectionStatus == 'accepted';
}
