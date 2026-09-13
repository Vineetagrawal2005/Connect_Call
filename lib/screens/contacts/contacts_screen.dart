import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/user_tile.dart';

/// Req 3: StreamBuilder on the `users` collection listing every other
/// registered user. Shared by the Home tab and the Contacts tab.
class ContactsScreen extends StatelessWidget {
  final bool showAppBar;

  const ContactsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final selfUid = FirebaseAuth.instance.currentUser?.uid;
    final body = StreamBuilder<List<AppUser>>(
      stream: UserService().streamAllUsers(),
      builder: (context, snapshot) {
        // Loading state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Error state (minimum bar: SnackBar-worthy message inline).
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load contacts. Check your connection and try again.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        // Exclude self; empty state.
        final users = (snapshot.data ?? []).where((u) => u.uid != selfUid).toList();
        if (users.isEmpty) {
          return const Center(child: Text('No contacts yet'));
        }
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => UserTile(user: users[i]),
        );
      },
    );

    if (!showAppBar) return body;
    return Scaffold(appBar: AppBar(title: const Text('Contacts')), body: body);
  }
}
