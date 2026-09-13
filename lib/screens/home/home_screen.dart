import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../contacts/contacts_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

/// Bottom nav: Home / Contacts / Calls / Profile.
/// Home shows a greeting + the user list; Contacts the full list;
/// Calls the history; Profile the profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const ContactsScreen(showAppBar: false),
      const HistoryScreen(showAppBar: false),
      const ProfileScreen(showAppBar: false),
    ];
    const titles = ['ConnectCall', 'Contacts', 'Calls', 'Profile'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<AppUser?>(
          future: user == null ? Future.value(null) : UserService().getUser(user.uid),
          builder: (context, snapshot) {
            final name = snapshot.data?.name ?? user?.displayName ?? user?.email ?? 'there';
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Hello, $name 👋\nTap 📞 for audio or 🎥 for video.',
                style: const TextStyle(fontSize: 16),
              ),
            );
          },
        ),
        const Expanded(child: ContactsScreen(showAppBar: false)),
      ],
    );
  }
}
