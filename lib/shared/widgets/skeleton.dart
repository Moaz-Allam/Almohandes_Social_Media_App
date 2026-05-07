import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .52, end: .9),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOut,
        builder: (context, opacity, child) {
          return Opacity(opacity: opacity, child: child);
        },
        onEnd: () {},
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: .08)
                : AppColors.line,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, required this.width, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, radius: height / 2);
  }
}

class FeedPostSkeleton extends StatelessWidget {
  const FeedPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBox(width: 48, height: 48, radius: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 140, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: 220, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonLine(width: double.infinity, height: 13),
          const SizedBox(height: 8),
          const SkeletonLine(width: 280, height: 13),
          const SizedBox(height: 14),
          SkeletonBox(
            width: MediaQuery.sizeOf(context).width,
            height: 170,
            radius: 8,
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 68, height: 12),
              SkeletonLine(width: 88, height: 12),
              SkeletonLine(width: 72, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 210, height: 18),
          SizedBox(height: 10),
          SkeletonLine(width: double.infinity, height: 12),
          SizedBox(height: 7),
          SkeletonLine(width: 260, height: 12),
          SizedBox(height: 16),
          Row(
            children: [
              SkeletonBox(width: 72, height: 28, radius: 14),
              SizedBox(width: 8),
              SkeletonBox(width: 82, height: 28, radius: 14),
              SizedBox(width: 8),
              SkeletonBox(width: 64, height: 28, radius: 14),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 44, radius: 22),
        ],
      ),
    );
  }
}

class NetworkCardSkeleton extends StatelessWidget {
  const NetworkCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SkeletonBox(
            width: MediaQuery.sizeOf(context).width,
            height: 64,
            radius: 0,
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: 78, height: 78, radius: 39),
          const SizedBox(height: 14),
          const SkeletonLine(width: 104, height: 16),
          const SizedBox(height: 8),
          const SkeletonLine(width: 126, height: 12),
          const Spacer(),
          const SkeletonLine(width: 116, height: 11),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SkeletonBox(width: double.infinity, height: 34, radius: 18),
          ),
        ],
      ),
    );
  }
}

class ReelSkeleton extends StatelessWidget {
  const ReelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkBlue.withValues(alpha: .9),
                    AppColors.black,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SkeletonBox(
              width: MediaQuery.sizeOf(context).width * .68,
              height: 220,
              radius: 28,
            ),
          ),
          const Positioned(
            right: 16,
            bottom: 88,
            child: Column(
              children: [
                SkeletonBox(width: 42, height: 42, radius: 21),
                SizedBox(height: 18),
                SkeletonBox(width: 42, height: 42, radius: 21),
                SizedBox(height: 18),
                SkeletonBox(width: 42, height: 42, radius: 21),
              ],
            ),
          ),
          const Positioned(
            left: 16,
            right: 78,
            bottom: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 160, height: 18),
                SizedBox(height: 10),
                SkeletonLine(width: 240, height: 13),
                SizedBox(height: 16),
                SkeletonLine(width: double.infinity, height: 14),
                SizedBox(height: 8),
                SkeletonLine(width: 220, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
