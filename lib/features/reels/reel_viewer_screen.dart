import 'package:flutter/material.dart';

import '../../models/reel_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';

/// Full-screen vertical viewer for a list of reels.
///
/// Opened from places that show reels in a grid (e.g. the profile page) so a
/// tapped reel plays full screen. When [canManage] is true (the reels belong
/// to the signed-in user) a delete action is shown in the top bar that removes
/// the current reel through the owner-only repository method.
class ReelViewerScreen extends StatefulWidget {
  const ReelViewerScreen({
    super.key,
    required this.reels,
    required this.initialIndex,
    this.canManage = false,
  });

  final List<ReelItem> reels;
  final int initialIndex;
  final bool canManage;

  @override
  State<ReelViewerScreen> createState() => _ReelViewerScreenState();
}

class _ReelViewerScreenState extends State<ReelViewerScreen> {
  late final PageController _pageController;
  late final List<ReelItem> _reels;
  late int _index;
  bool _muted = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reels = List.of(widget.reels);
    final maxIndex = _reels.isEmpty ? 0 : _reels.length - 1;
    _index = widget.initialIndex.clamp(0, maxIndex);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrent() async {
    if (_busy || _reels.isEmpty) return;
    final reel = _reels[_index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف reel'),
        content: const Text(
          'سيتم حذف هذا reel نهائياً. هل تريد المتابعة؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final app = AppScope.read(context);
    try {
      await app.repositories.reels.deleteReel(reel.id);
      app.notifyReelsChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.error(context, error, fallback: 'تعذر حذف reel الآن');
      return;
    }
    if (!mounted) return;
    setState(() {
      _reels.removeAt(_index);
      _busy = false;
      if (_index >= _reels.length) {
        _index = _reels.isEmpty ? 0 : _reels.length - 1;
      }
    });
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('تم حذف reel')));
    if (_reels.isEmpty) {
      navigator.pop();
    } else {
      _pageController.jumpToPage(_index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_reels.isEmpty)
            const Center(
              child: Text(
                'لا توجد reels',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = _reels[index];
                return _ReelViewerPage(
                  key: ValueKey('reel-view-${item.id}'),
                  item: item,
                  isActive: index == _index,
                  muted: _muted,
                  onToggleMute: () => setState(() => _muted = !_muted),
                );
              },
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'رجوع',
                  ),
                  const Spacer(),
                  if (widget.canManage && _reels.isNotEmpty)
                    IconButton(
                      onPressed: _busy ? null : _deleteCurrent,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                      tooltip: 'حذف reel',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelViewerPage extends StatelessWidget {
  const _ReelViewerPage({
    super.key,
    required this.item,
    required this.isActive,
    required this.muted,
    required this.onToggleMute,
  });

  final ReelItem item;
  final bool isActive;
  final bool muted;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = item.videoUrl ?? item.thumbnailUrl ?? '';
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mediaUrl.isNotEmpty)
            Positioned.fill(
              child: MediaPreview(
                mediaUrl: mediaUrl,
                mediaType: 'reel',
                fallbackLabel: 'reel',
                autoplay: isActive,
                showVideoControls: true,
                muted: muted,
                releaseController: !isActive,
              ),
            ),
          Positioned(
            right: 8,
            bottom: 90,
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                onTap: onToggleMute,
                radius: 28,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 72,
            bottom: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(
                      name: item.name,
                      radius: 25,
                      color: item.color,
                      imageUrl: item.avatarUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (item.headline.isNotEmpty)
                            Text(
                              item.headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.caption.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    item.caption,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
