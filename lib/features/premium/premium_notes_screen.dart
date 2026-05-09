import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PremiumNotesScreen extends StatefulWidget {
  const PremiumNotesScreen({super.key});

  @override
  State<PremiumNotesScreen> createState() => _PremiumNotesScreenState();
}

class _PremiumNotesScreenState extends State<PremiumNotesScreen> {
  static const _storageKey = 'premium_engineer_notes';

  final List<_EngineerNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    final notes = <_EngineerNote>[];
    for (final value in raw) {
      final note = _EngineerNote.tryParse(value);
      if (note != null) {
        notes.add(note);
      }
    }
    setState(() {
      _notes
        ..clear()
        ..addAll(notes);
      _isLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, [
      for (final note in _notes) note.toJson(),
    ]);
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملاحظة جديدة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظتك هنا'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = note?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _notes.insert(
        0,
        _EngineerNote(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: trimmed,
          createdAt: DateTime.now(),
        ),
      );
    });
    await _saveNotes();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('تم حفظ الملاحظة')));
  }

  Future<void> _deleteNote(_EngineerNote note) async {
    setState(() => _notes.removeWhere((item) => item.id == note.id));
    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text(
          'ملاحظاتي',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const _EmptyNotes()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
              itemCount: _notes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'حذف',
                        onPressed: () => _deleteNote(note),
                        icon: const Icon(Icons.delete_outline),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.content,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(note.createdAt),
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}/${local.month}/${local.day} - ${local.hour}:$minute';
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: context.appMuted, size: 48),
            const SizedBox(height: 12),
            const Text(
              'لا توجد ملاحظات بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'احفظ الأفكار والملاحظات السريعة من لوحة Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EngineerNote {
  const _EngineerNote({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;

  static _EngineerNote? tryParse(String value) {
    try {
      final data = jsonDecode(value);
      if (data is! Map) {
        return null;
      }
      return _EngineerNote(
        id: '${data['id'] ?? ''}',
        content: '${data['content'] ?? ''}',
        createdAt:
            DateTime.tryParse('${data['createdAt'] ?? ''}') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    });
  }
}
