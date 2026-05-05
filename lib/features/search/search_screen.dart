import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../profile/profile_screen.dart';

enum SearchFilter {
  people('الأشخاص'),
  jobs('الوظائف'),
  posts('المنشورات');

  const SearchFilter(this.label);

  final String label;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  SearchFilter _filter = SearchFilter.people;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'ابحث في لينكدإن',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFE8EFF6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: AppColors.blue),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final filter = SearchFilter.values[index];
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    selectedColor: AppColors.paleBlue,
                    side: BorderSide(
                      color: _filter == filter
                          ? AppColors.blue
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: _filter == filter
                          ? AppColors.darkBlue
                          : AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = filter),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: SearchFilter.values.length,
              ),
            ),
            Expanded(
              child: _SearchResults(filter: _filter, query: _query.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.filter, required this.query});

  final SearchFilter filter;
  final String query;

  @override
  Widget build(BuildContext context) {
    final rows = switch (filter) {
      SearchFilter.people => const [
        _ResultRow(Icons.person, 'ريم حسن', 'مصممة منتجات · القاهرة'),
        _ResultRow(Icons.person, 'أحمد منصور', 'مطور Flutter · Nile Apps'),
        _ResultRow(Icons.person, 'شيرين أمين', 'مصممة UI/UX'),
      ],
      SearchFilter.jobs => const [
        _ResultRow(Icons.work, 'مصمم منتجات أول', 'NilePay · عمل هجين'),
        _ResultRow(Icons.work, 'مطور Flutter', 'Cairo Mobility · عن بعد'),
        _ResultRow(Icons.work, 'مدير منتج مساعد', 'MENA Commerce'),
      ],
      SearchFilter.posts => const [
        _ResultRow(
          Icons.article,
          'فرص تدريب UI/UX في نوفمبر',
          'منشور من Nile Labs',
        ),
        _ResultRow(
          Icons.article,
          'كيف تكتب نبذة مهنية قوية؟',
          'منشور شائع في شبكتك',
        ),
        _ResultRow(Icons.article, 'العمل عن بعد وتجارب الفرق', 'مناقشة نشطة'),
      ],
    };

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4),
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.paleBlue,
          child: Icon(rows[index].icon, color: AppColors.blue),
        ),
        title: Text(
          rows[index].title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          query.trim().isEmpty
              ? rows[index].subtitle
              : 'نتيجة مطابقة لـ "$query"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: filter == SearchFilter.people
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    name: rows[index].title,
                    headline: rows[index].subtitle,
                    color: AppColors.blue,
                  ),
                ),
              )
            : () {},
      ),
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72),
      itemCount: rows.length,
    );
  }
}

final class _ResultRow {
  const _ResultRow(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}
