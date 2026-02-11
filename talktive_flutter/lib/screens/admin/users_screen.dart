import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_input.dart';

/// User management screen for admins
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _users = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final client = ref.read(clientProvider);
      final users = await client.admin.searchUsers(query: query);

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showUserActions(Map<String, dynamic> user) async {
    final userId = user['userId'] as String;
    final userName = user['userName'] as String;
    final isBanned = user['isBanned'] as bool;
    final isAdmin = user['isAdmin'] as bool;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Floor ${user['floor']} • ${user['creditScore']} credits',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              if (!isBanned)
                ListTile(
                  leading: const Icon(
                    Icons.volume_off,
                    color: AppTheme.duoOrange,
                  ),
                  title: const Text('Mute User'),
                  subtitle: const Text('Set credit score to 0'),
                  onTap: () {
                    Navigator.pop(context);
                    _muteUser(userId, userName);
                  },
                ),

              ListTile(
                leading: Icon(
                  isBanned ? Icons.check_circle : Icons.block,
                  color: isBanned ? AppTheme.duoGreen : AppTheme.errorColor,
                ),
                title: Text(isBanned ? 'Unban User' : 'Ban User'),
                subtitle: Text(
                  isBanned ? 'Restore access' : 'Permanently ban user',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isBanned) {
                    _unbanUser(userId, userName);
                  } else {
                    _banUser(userId, userName);
                  }
                },
              ),

              const Divider(height: 1),

              ListTile(
                leading: Icon(
                  isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                  color: AppTheme.primaryColor,
                ),
                title: Text(isAdmin ? 'Remove Admin' : 'Promote to Admin'),
                onTap: () {
                  Navigator.pop(context);
                  if (isAdmin) {
                    _demoteFromAdmin(userId, userName);
                  } else {
                    _promoteToAdmin(userId, userName);
                  }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _muteUser(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Mute User',
      'Set $userName\'s credit score to 0? They won\'t be able to send messages.',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.muteUser(userId: userId, reason: 'Admin action');

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been muted'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _banUser(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Ban User',
      'Permanently ban $userName? This will set their credit score to -1000.',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.banUser(userId: userId, reason: 'Admin action');

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been banned'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _unbanUser(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Unban User',
      'Restore access for $userName? Their credit score will be set to 50.',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.unbanUser(userId: userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been unbanned'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _promoteToAdmin(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Promote to Admin',
      'Give $userName admin privileges?',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.promoteToAdmin(userId: userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is now an admin'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _demoteFromAdmin(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Remove Admin',
      'Remove admin privileges from $userName?',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.demoteFromAdmin(userId: userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is no longer an admin'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Management',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: DuoInput(
              controller: _searchController,
              hintText: 'Search by name or user ID...',
              prefixIcon: Icons.search,
              onChanged: (value) => _searchUsers(value),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                ? DuoEmptyState(
                    emoji: '🔍',
                    title: 'Search Users',
                    subtitle: 'Enter a name or user ID to search',
                  )
                : _users.isEmpty
                ? DuoEmptyState(
                    emoji: '😕',
                    title: 'No users found',
                    subtitle: 'Try a different search term',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_users[index])
                          .animate(delay: Duration(milliseconds: index * 50))
                          .fadeIn()
                          .slideX(begin: -0.1, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userName = user['userName'] as String;
    final floor = user['floor'] as int;
    final creditScore = user['creditScore'] as int;
    final isAdmin = user['isAdmin'] as bool;
    final isBanned = user['isBanned'] as bool;
    final messageCount = user['messageCount'] as int;
    final momentCount = user['momentCount'] as int;
    final reportCount = user['reportCount'] as int;

    return DuoCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _showUserActions(user);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                        if (isBanned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BANNED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🏢 Floor $floor • ⭐ $creditScore credits',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: AppTheme.textGray),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('💬', messageCount.toString(), 'Messages'),
              _buildStatItem('📸', momentCount.toString(), 'Moments'),
              _buildStatItem('⚠️', reportCount.toString(), 'Reports'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
      ],
    );
  }
}
