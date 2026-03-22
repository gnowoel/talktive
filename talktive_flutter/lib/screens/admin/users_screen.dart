import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../helpers/resident_ext.dart';
import '../../providers/current_resident_provider.dart';
import 'package:talktive_client/talktive_client.dart' as protocol;

/// User management screen for admins
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<protocol.AdminUserSummary> _users = [];
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
      final users = await client.admin.searchUsers(
        query: query,
        limit: 20,
        offset: 0,
      );

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
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _showUserActions(protocol.AdminUserSummary user) async {
    final userId = user.userId;
    final userName = user.userName ?? 'Unknown';
    final isBanned = user.suspended;
    final isAdmin = user.role == protocol.ResidentRole.admin;
    final isModerator = user.role == protocol.ResidentRole.moderator;

    final currentResidentVal = ref.read(currentResidentProvider).value;
    final isCurrentUserAdmin = currentResidentVal?.isAdmin ?? false;

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
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
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
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level ${user.level} • ⭐ ${user.trustScore} reputation',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Text('🧹', style: TextStyle(fontSize: 24)),
                title: const Text('Reset Trust Score'),
                subtitle: const Text('Reset trust score to 100'),
                onTap: () {
                  Navigator.pop(context);
                  _resetReputation(userId, userName);
                },
              ),

              ListTile(
                leading: Text(
                  isBanned ? '✅' : '🚫',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(isBanned ? 'Unsuspend User' : 'Suspend User'),
                subtitle: Text(
                  isBanned ? 'Restore access' : 'Suspend user account',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isBanned) {
                    _unsuspendUser(userId, userName);
                  } else {
                    _suspendUser(userId, userName);
                  }
                },
              ),

              if (isCurrentUserAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Text(
                    isAdmin ? '👤' : '🛡️',
                    style: const TextStyle(fontSize: 24),
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
                ListTile(
                  leading: Text(
                    isModerator ? '👤' : '🛡️',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    isModerator ? 'Remove Moderator' : 'Promote to Moderator',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (isModerator) {
                      _demoteFromModerator(userId, userName);
                    } else {
                      _promoteToModerator(userId, userName);
                    }
                  },
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetReputation(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Reset Trust Score',
      'Reset $userName\'s trust score to 100?',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.resetReputation(
        userId: userId,
        reason: 'Admin action',
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName\'s trust score was reset'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _suspendUser(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Suspend User',
      'Suspend $userName? This will disable their account.',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.suspendUser(userId: userId, reason: 'Admin action');

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been suspended'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _unsuspendUser(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Unsuspend User',
      'Restore access for $userName? Their trust score will be reset to 50.',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.unsuspendUser(userId: userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been unsuspended'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
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
        DuoSnackBarHelper.showError(context, e);
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
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _promoteToModerator(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Promote to Moderator',
      'Give $userName moderator privileges?',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.promoteToModerator(userId: userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is now a moderator'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _demoteFromModerator(String userId, String userName) async {
    final confirmed = await _showConfirmDialog(
      'Remove Moderator',
      'Remove moderator privileges from $userName?',
    );

    if (!confirmed) return;

    try {
      final client = ref.read(clientProvider);
      await client.admin.demoteFromModerator(userId: userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName is no longer a moderator'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
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
          DuoButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            variant: DuoButtonVariant.ghost,
            size: DuoButtonSize.small,
          ),
          DuoButton(
            text: 'Confirm',
            onPressed: () => Navigator.pop(context, true),
            color: AppTheme.errorColor,
            size: DuoButtonSize.small,
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Management',
          style: TextStyle(
            color: AppTheme.textPrimary,
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
              prefixEmoji: '🔍',
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

  Widget _buildUserCard(protocol.AdminUserSummary user) {
    final userName = user.userName ?? 'Unknown';
    final floor = user.floor;
    final reputation = user.trustScore;
    final isAdmin = user.role == protocol.ResidentRole.admin;
    final isModerator = user.role == protocol.ResidentRole.moderator;
    final isBanned = user.suspended;
    final messageCount = user.messageCount;
    final momentCount = user.momentCount;
    final reportCount = user.reportCount;

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
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin || isModerator) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isAdmin
                                          ? AppTheme.primaryColor
                                          : AppTheme.secondaryColor)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAdmin ? 'ADMIN' : 'MODERATOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAdmin
                                    ? AppTheme.primaryColor
                                    : AppTheme.secondaryColor,
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
                              color: AppTheme.errorColor.withValues(alpha: 0.1),
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
                      'Level $floor • ⭐ $reputation reputation',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: AppTheme.textSecondary),
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
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
