import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../models/saved_content.dart';
import '../cache/timed_memory_cache.dart';

abstract interface class SavedContentRepository {
  Future<List<SavedContent>> fetch({bool forceRefresh = false});

  Future<void> save(SavedContent content);

  Future<void> remove(String id);
}

final class SupabaseSavedContentRepository implements SavedContentRepository {
  SupabaseSavedContentRepository({required this.client});

  static const _savedPageSize = 40;

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<SavedContent>>(
    ttl: const Duration(minutes: 1),
  );

  @override
  Future<List<SavedContent>> fetch({bool forceRefresh = false}) async {
    return _cache.read(_fetchSavedContent, forceRefresh: forceRefresh);
  }

  Future<List<SavedContent>> _fetchSavedContent() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      final rows = await remote
          .from('saved_items')
          .select('item_type,item_id,title,subtitle,detail')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false)
          .limit(_savedPageSize);
      return [
        for (final row in rows)
          _savedContentFromRow(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(SavedContent content) async {
    final remote = client;
    if (remote == null) {
      return;
    }

    try {
      await remote.rpc(
        'save_item_for_app',
        params: {
          'p_item_type': content.type.name,
          'p_item_id': content.id,
          'p_title': content.title,
          'p_subtitle': content.subtitle,
          'p_detail': content.detail,
          'p_metadata': <String, dynamic>{},
        },
      );
      _cacheSavedContent(content);
      return;
    } catch (_) {
      // Fall through to a direct table write for projects without the RPC.
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.from('saved_items').upsert({
        'profile_id': profileId,
        'item_type': content.type.name,
        'item_id': content.id,
        'title': content.title,
        'subtitle': content.subtitle,
        'detail': content.detail,
      }, onConflict: 'profile_id,item_type,item_id');
      _cacheSavedContent(content);
    } catch (_) {
      // Saving remains local when the optional migration is not installed yet.
    }
  }

  @override
  Future<void> remove(String id) async {
    final remote = client;
    if (remote == null) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote
          .from('saved_items')
          .delete()
          .eq('profile_id', profileId)
          .eq('item_id', id);
      _removeCachedContent(id);
    } catch (_) {
      // Local state is authoritative for prototype fallback.
    }
  }

  SavedContent _savedContentFromRow(Map<String, dynamic> row) {
    return SavedContent(
      id: '${row['item_id']}',
      type: _savedContentTypeFromName('${row['item_type']}'),
      title: '${row['title'] ?? ''}',
      subtitle: '${row['subtitle'] ?? ''}',
      detail: '${row['detail'] ?? ''}',
    );
  }

  SavedContentType _savedContentTypeFromName(String value) {
    return SavedContentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SavedContentType.post,
    );
  }

  void _cacheSavedContent(SavedContent content) {
    final existing = _cache.value ?? const <SavedContent>[];
    _cache.put([
      content,
      for (final item in existing)
        if (item.id != content.id) item,
    ]);
  }

  void _removeCachedContent(String id) {
    final existing = _cache.value;
    if (existing == null) {
      return;
    }
    _cache.put([
      for (final item in existing)
        if (item.id != id) item,
    ]);
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);
}
