import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_item.dart';
import '../../../shared/widgets/app_avatar.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onApply,
    this.canApply = true,
    this.actionLabel,
  });

  final ProjectItem project;
  final VoidCallback onApply;
  final bool canApply;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: project.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _categoryIcon(project.category),
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProjectMetaChip(label: project.category),
              _ProjectMetaChip(label: project.type),
              _ProjectMetaChip(label: project.workMode),
              _ProjectMetaChip(label: project.stage),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.skills.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${project.location} · ${project.commitment} · ${project.budget}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.appMuted, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(
                      name: project.postedBy,
                      radius: 16,
                      color: project.color,
                      imageUrl: project.creatorAvatarUrl,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.postedBy,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: canApply ? onApply : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  disabledBackgroundColor: context.appSoft,
                  disabledForegroundColor: context.appMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(actionLabel ?? (canApply ? 'تقديم' : 'مشروعك')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'مدني' => Icons.apartment_outlined,
    'معماري' => Icons.architecture_outlined,
    'كهرباء' => Icons.electrical_services_outlined,
    'ميكانيك' => Icons.precision_manufacturing_outlined,
    'آليات' => Icons.local_shipping_outlined,
    'تشطيبات' => Icons.format_paint_outlined,
    'سلامة' => Icons.health_and_safety_outlined,
    _ => Icons.folder_special_outlined,
  };
}

class _ProjectMetaChip extends StatelessWidget {
  const _ProjectMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
