import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../helpers/helpers.dart';
import '../models/admin.dart';
import '../services/firedata.dart';
import '../services/user_cache.dart';
import '../widgets/layout.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firedata = context.read<Firedata>();
    final userCache = context.watch<UserCache>();
    final user = userCache.user;

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
        ],
      ),
      body: SafeArea(
        child: Layout(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar section
                          Text(
                            user?.photoURL ?? '',
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 24),

                          // Name and description
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

                          // Badges
                          if (user != null) ...[
                            const SizedBox(height: 24),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Badge(
                                    label: 'Level ${user.level}',
                                    borderColor:
                                        theme.colorScheme.outlineVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  _Badge(
                                    label:
                                        getLongGenderName(user.gender!) ?? '',
                                    borderColor:
                                        theme.colorScheme.outlineVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  _Badge(
                                    label:
                                        getLanguageName(user.languageCode!) ??
                                            '',
                                    borderColor:
                                        theme.colorScheme.outlineVariant,
                                  ),
                                ],
                              ),
                            ),
                            // Status and reputation tags
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Show single most relevant status tag (priority-based)
                                  ...() {
                                    final userStatus = user.status;
                                    final widgets = <Widget>[];

                                    // Priority order: warning > alert > very_poor > poor > newcomer > excellent > good
                                    if (userStatus == 'warning') {
                                      widgets.add(_Badge(
                                        label: 'Warning',
                                        backgroundColor:
                                            theme.colorScheme.errorContainer,
                                        textColor:
                                            theme.colorScheme.onErrorContainer,
                                      ));
                                    } else if (userStatus == 'alert') {
                                      widgets.add(_Badge(
                                        label: 'Alert',
                                        backgroundColor:
                                            theme.colorScheme.tertiaryContainer,
                                        textColor: theme
                                            .colorScheme.onTertiaryContainer,
                                      ));
                                    } else if (user.reputationLevel ==
                                        'very_poor') {
                                      widgets.add(_Badge(
                                        label: 'Poor Reputation',
                                        backgroundColor:
                                            theme.colorScheme.errorContainer,
                                        textColor:
                                            theme.colorScheme.onErrorContainer,
                                      ));
                                    } else if (user.reputationLevel == 'poor') {
                                      widgets.add(_Badge(
                                        label: 'Caution',
                                        backgroundColor: theme
                                            .colorScheme.errorContainer
                                            .withValues(alpha: 0.7),
                                        textColor:
                                            theme.colorScheme.onErrorContainer,
                                      ));
                                    } else if (userStatus == 'newcomer') {
                                      widgets.add(_Badge(
                                        label: 'New User',
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        textColor: theme
                                            .colorScheme.onPrimaryContainer,
                                      ));
                                      // } else if (user.reputationLevel ==
                                      //     'excellent') {
                                      //   widgets.add(_Badge(
                                      //     label: 'Trusted User',
                                      //     backgroundColor: theme
                                      //         .colorScheme.secondaryContainer,
                                      //     textColor: theme
                                      //         .colorScheme.onSecondaryContainer,
                                      //   ));
                                      // } else if (user.reputationLevel == 'good') {
                                      //   widgets.add(_Badge(
                                      //     label: 'Good Reputation',
                                      //     backgroundColor: theme
                                      //         .colorScheme.surfaceContainerHigh,
                                      //     textColor: theme.colorScheme.onSurface,
                                      //   ));
                                    }

                                    if (widgets.isNotEmpty) {
                                      widgets.add(const SizedBox(width: 8));
                                    }
                                    return widgets;
                                  }(),
                                ],
                              ),
                            ),
                          ],

                          // Backup account button
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () => context.push('/profile/backup'),
                            child: const Text('Backup Account'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<Admin?>(
        future: firedata.fetchAdmin(user?.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return FloatingActionButton(
              onPressed: () => context.push('/admin/reports'),
              tooltip: 'Admin Panel',
              heroTag: "profile_admin_fab",
              child: const Icon(Icons.admin_panel_settings),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const _Badge({
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: textColor),
      ),
    );
  }
}
