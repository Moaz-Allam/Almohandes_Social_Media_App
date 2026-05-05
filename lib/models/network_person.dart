import 'package:flutter/material.dart';

final class NetworkPerson {
  const NetworkPerson({
    required this.name,
    required this.title,
    required this.color,
    this.badge,
  });

  final String name;
  final String title;
  final Color color;
  final String? badge;
}
