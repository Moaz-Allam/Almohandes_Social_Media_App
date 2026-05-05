import 'package:flutter/material.dart';

final class NetworkPerson {
  const NetworkPerson({
    required this.name,
    required this.title,
    required this.color,
    this.badge,
    this.contextLine = 'جامعة القاهرة',
    this.actionLabel = 'تواصل',
    this.isCompany = false,
  });

  final String name;
  final String title;
  final Color color;
  final String? badge;
  final String contextLine;
  final String actionLabel;
  final bool isCompany;
}
