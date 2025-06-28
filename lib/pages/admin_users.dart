import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/firedata.dart';
import '../services/user_cache.dart';
import '../widgets/layout.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  // ignore: prefer_final_fields
  List<User> _users = [];
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you'd fetch users from your database
      // For now, this is a placeholder
      // final users = await context.read<Firedata>().fetchAllUsers();
      // setState(() {
      //   _users = users;
      // });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<User> get _filteredUsers {
    var filtered = _users.where((user) {
      final matchesSearch = user.displayName
              ?.toLowerCase()
              .contains(_searchQuery.toLowerCase()) ??
          false;

      final matchesRole = _selectedRoleFilter == 'all' ||
          (_selectedRoleFilter == 'admin' && user.isAdmin) ||
          (_selectedRoleFilter == 'moderator' && user.isModerator) ||
          (_selectedRoleFilter == 'user' && user.role == null);

      return matchesSearch && matchesRole;
    }).toList();

    // Sort by role priority, then by display name
    filtered.sort((a, b) {
      final aRolePriority = _getRolePriority(a.role);
      final bRolePriority = _getRolePriority(b.role);

      if (aRolePriority != bRolePriority) {
        return aRolePriority.compareTo(bRolePriority);
      }

      return (a.displayName ?? '').compareTo(b.displayName ?? '');
    });

    return filtered;
  }

  int _getRolePriority(String? role) {
    switch (role) {
      case 'admin':
        return 0;
      case 'moderator':
        return 1;
      default:
        return 2;
    }
  }

  Future<void> _updateUserRole(User user, String? newRole) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await context.read<Firedata>().updateUserRole(user.id, newRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated ${user.displayName}\'s role to ${newRole ?? 'user'}',
            ),
          ),
        );

        // Update the local user list
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = User(
              id: user.id,
              createdAt: user.createdAt,
              updatedAt: user.updatedAt,
              languageCode: user.languageCode,
              photoURL: user.photoURL,
              displayName: user.displayName,
              description: user.description,
              gender: user.gender,
              fcmToken: user.fcmToken,
              revivedAt: user.revivedAt,
              messageCount: user.messageCount,
              reportCount: user.reportCount,
              role: newRole,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user role: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRoleUpdateDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => _RoleUpdateDialog(
        user: user,
        onRoleUpdate: _updateUserRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userCache = context.watch<UserCache>();
    final currentUser = userCache.user;

    // Check if current user is admin
    if (currentUser?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('You do not have permission to access this page.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Layout(
          child: Column(
            children: [
              // Search and filter section
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search users',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Filter by role: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedRoleFilter,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRoleFilter = value;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Admins')),
                            DropdownMenuItem(
                                value: 'moderator', child: Text('Moderators')),
                            DropdownMenuItem(
                                value: 'user', child: Text('Users')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Users list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return _UserCard(
                                user: user,
                                onRoleUpdate: () => _showRoleUpdateDialog(user),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onRoleUpdate;

  const _UserCard({
    required this.user,
    required this.onRoleUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            user.photoURL ?? '👤',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(user.displayName ?? 'Unknown User'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user.id}'),
            if (user.role != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role!, theme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.role!.toUpperCase(),
                  style: TextStyle(
                    color: _getRoleTextColor(user.role!, theme),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRoleUpdate,
          tooltip: 'Update role',
        ),
      ),
    );
  }

  Color _getRoleColor(String role, ThemeData theme) {
    switch (role) {
      case 'admin':
        return theme.colorScheme.errorContainer;
      case 'moderator':
        return theme.colorScheme.primaryContainer;
      default:
        return theme.colorScheme.surfaceContainerHigh;
    }
  }

  Color _getRoleTextColor(String role, ThemeData theme) {
    switch (role) {
      case 'admin':
        return theme.colorScheme.onErrorContainer;
      case 'moderator':
        return theme.colorScheme.onPrimaryContainer;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}

class _RoleUpdateDialog extends StatefulWidget {
  final User user;
  final Future<void> Function(User user, String? role) onRoleUpdate;

  const _RoleUpdateDialog({
    required this.user,
    required this.onRoleUpdate,
  });

  @override
  State<_RoleUpdateDialog> createState() => _RoleUpdateDialogState();
}

class _RoleUpdateDialogState extends State<_RoleUpdateDialog> {
  String? _selectedRole;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Role for ${widget.user.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String?>(
            title: const Text('Regular User'),
            value: null,
            groupValue: _selectedRole,
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
          ),
          RadioListTile<String?>(
            title: const Text('Moderator'),
            value: 'moderator',
            groupValue: _selectedRole,
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
          ),
          RadioListTile<String?>(
            title: const Text('Admin'),
            value: 'admin',
            groupValue: _selectedRole,
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateRole,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateRole() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onRoleUpdate(widget.user, _selectedRole);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error handling is done in the parent widget
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
