import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../helpers/helpers.dart';
import '../models/admin.dart';
import '../services/cache.dart';
import '../services/firedata.dart';
import '../widgets/layout.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firedata = context.read<Firedata>();
    final user = context.select((Cache cache) => cache.user);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: user == null
                ? null
                : () => context.push('/profile/edit', extra: user),
            tooltip: 'Edit profile',
          ),
          FutureBuilder<Admin?>(
            future: firedata.fetchAdmin(user?.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    context.push('/admin/reports');
                  },
                  tooltip: 'Admin Panel',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Layout(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      user?.photoURL ?? '',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? '',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.description ?? '',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  getLongGenderDescription(user?.gender ?? '') ?? '',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
