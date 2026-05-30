import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_content.dart';
import '../../state/app_scope.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  SavedContentType? _filter;
  late Future<List<SavedContent>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = Future.value(const <SavedContent>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _itemsFuture = _loadItems();
  }

  Future<List<SavedContent>> _loadItems({bool forceRefresh = false}) async {
    final app = AppScope.read(context);
    final remote = await app.repositories.savedContent.fetch(
      forceRefresh: forceRefresh,
    );
    final byId = <String, SavedContent>{};
    for (final item in app.savedItems) {
      byId['${item.type.name}:${item.id}'] = item;
    }
    for (final item in remote) {
      byId['${item.type.name}:${item.id}'] = item;
    }
    return byId.values.toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = _loadItems(forceRefresh: true);
    });
    await _itemsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'المحفوظات',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SavedFilterChip(
                  label: 'الكل',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final type in SavedContentType.values)
                  _SavedFilterChip(
                    label: _typeLabel(type),
                    selected: _filter == type,
                    onTap: () => setState(() => _filter = type),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SavedContent>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                final items = (snapshot.data ?? const <SavedContent>[])
                    .where((item) => _filter == null || item.type == _filter)
                    .toList();
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return const _SavedItemsEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _SavedItemTile(item: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(SavedContentType type) {
    return switch (type) {
      SavedContentType.post => 'منشورات',
      SavedContentType.reel => 'reels',
      SavedContentType.project => 'مشاريع',
      SavedContentType.company => 'شركات',
      SavedContentType.story => 'قصص',
    };
  }
}

class _SavedFilterChip extends StatelessWidget {
  const _SavedFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8, top: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.blue,
        labelStyle: TextStyle(
          color: selected ? AppColors.white : context.appText,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _SavedItemTile extends StatelessWidget {
  const _SavedItemTile({required this.item});

  final SavedContent item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.appBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.appSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_iconFor(item.type), color: AppColors.blue),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${_typeName(item.type)} · ${item.subtitle}\n${item.detail}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.appMuted, height: 1.35),
        ),
      ),
    );
  }

  IconData _iconFor(SavedContentType type) {
    return switch (type) {
      SavedContentType.post => Icons.article_outlined,
      SavedContentType.reel => Icons.smart_display_outlined,
      SavedContentType.project => Icons.folder_special_outlined,
      SavedContentType.company => Icons.business_outlined,
      SavedContentType.story => Icons.auto_stories_outlined,
    };
  }

  String _typeName(SavedContentType type) {
    return switch (type) {
      SavedContentType.post => 'منشور',
      SavedContentType.reel => 'reel',
      SavedContentType.project => 'مشروع',
      SavedContentType.company => 'شركة',
      SavedContentType.story => 'قصة',
    };
  }
}

class _SavedItemsEmptyState extends StatelessWidget {
  const _SavedItemsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline, color: AppColors.muted, size: 46),
            SizedBox(height: 12),
            Text(
              'لا توجد عناصر محفوظة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
