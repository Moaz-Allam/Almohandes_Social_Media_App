import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/network_person.dart';
import '../../shared/widgets/app_avatar.dart';
import 'profile_screen.dart';

/// Generic list of people (followers / following / connections), opened from
/// the profile stat counters.
class PeopleListScreen extends StatelessWidget {
  const PeopleListScreen({
    super.key,
    required this.title,
    required this.future,
    this.emptyLabel = 'لا يوجد أشخاص لعرضهم',
  });

  final String title;
  final Future<List<NetworkPerson>> future;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<List<NetworkPerson>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final people = snapshot.data ?? const <NetworkPerson>[];
          if (people.isEmpty) {
            return Center(
              child: Text(emptyLabel, style: TextStyle(color: context.appMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: people.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, indent: 76, color: context.appBorder),
            itemBuilder: (context, index) {
              final person = people[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: AppAvatar(
                  name: person.name,
                  radius: 24,
                  color: person.color,
                  imageUrl: person.avatarUrl,
                ),
                title: Text(
                  person.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  person.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMuted),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      profileId: person.profileId ?? person.id,
                      name: person.name,
                      headline: person.title,
                      color: person.color,
                      avatarUrl: person.avatarUrl,
                      initialConnectionStatus: person.connectionStatus,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
