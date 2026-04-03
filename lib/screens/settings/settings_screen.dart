import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_screen.dart';
import 'reminder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Manage Reminders'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReminderScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}