import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_header.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_input.dart';
import '../profile/user_profile_screen.dart';
import '../groups/group_chat_screen.dart';

/// Duolingo-style Search & Discovery screen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _searchQuery = '';
  bool _isSearching = false;

  // Search results
  List<Map<String, dynamic>> _userResults = [];
  List<Group> _groupResults = [];
  List<Moment> _momentResults = [];

  // Discovery content
  List<Moment> _trendingMoments = [];
  List<Group> _popularGroups = [];
  List<Map<String, dynamic>> _activeUsers = [];

  bool _isLoadingDiscovery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDiscoveryContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryContent() async {
    if (_isLoadingDiscovery) return;

    setState(() {
      _isLoadingDiscovery = true;
    });

    try {
      final client = ref.read(clientProvider);

      final trending = await client.search.getTrendingMoments();
      final popular = await client.search.getPopularGroups();
      final active = await client.search.getActiveUsers();

      if (mounted) {
        setState(() {
          _trendingMoments = trending;
          _popularGroups = popular;
          _activeUsers = active;
          _isLoadingDiscovery = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading discovery content: $e');
      if (mounted) {
        setState(() {
          _isLoadingDiscovery = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _userResults = [];
        _groupResults = [];
        _momentResults = [];
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    try {
      final client = ref.read(clientProvider);
      final results = await client.search.searchAll(query);

      if (mounted) {
        setState(() {
          _userResults = List<Map<String, dynamic>>.from(
            results['users'] ?? [],
          );
          _groupResults =
              (results['groups'] as List?)
                  ?.map((g) => Group.fromJson(g as Map<String, dynamic>))
                  .toList() ??
              [];
          _momentResults =
              (results['moments'] as List?)
                  ?.map((m) => Moment.fromJson(m as Map<String, dynamic>))
                  .toList() ??
              [];
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchQuery = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            _buildHeader(),

            // Tabs
            if (hasSearchQuery) _buildSearchTabs(),
            if (!hasSearchQuery) _buildDiscoveryTabs(),

            // Content
            Expanded(
              child: hasSearchQuery
                  ? _buildSearchResults()
                  : _buildDiscoveryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search & Discover',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                    ),
                    Text(
                      'Find people, groups, and moments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search input
          DuoInput(
            controller: _searchController,
            hintText: 'Search...',
            prefixIcon: Icons.search,
            onChanged: (value) {
              _performSearch(value);
            },
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                      HapticFeedback.lightImpact();
                    },
                  )
                : null,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildSearchTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.duoPaddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        boxShadow: [AppTheme.duoShadowSmall],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textGray,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        tabs: [
          Tab(
            text:
                'All (${_userResults.length + _groupResults.length + _momentResults.length})',
          ),
          Tab(text: 'Users (${_userResults.length})'),
          Tab(text: 'Groups (${_groupResults.length})'),
          Tab(text: 'Moments (${_momentResults.length})'),
        ],
      ),
    );
  }

  Widget _buildDiscoveryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.duoPaddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        boxShadow: [AppTheme.duoShadowSmall],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textGray,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: '🔥 Trending'),
          Tab(text: '⭐ Popular'),
          Tab(text: '💬 Active'),
          Tab(text: '📸 Recent'),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(),
        _buildUserResults(),
        _buildGroupResults(),
        _buildMomentResults(),
      ],
    );
  }

  Widget _buildDiscoveryContent() {
    if (_isLoadingDiscovery) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTrendingMoments(),
        _buildPopularGroups(),
        _buildActiveUsers(),
        _buildRecentMoments(),
      ],
    );
  }

  Widget _buildAllResults() {
    final hasResults =
        _userResults.isNotEmpty ||
        _groupResults.isNotEmpty ||
        _momentResults.isNotEmpty;

    if (!hasResults) {
      return DuoEmptyState(
        emoji: '🔍',
        title: 'No results found',
        subtitle: 'Try a different search term',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
      children: [
        if (_userResults.isNotEmpty) ...[
          _buildSectionHeader('Users', _userResults.length),
          ..._userResults.take(3).map((user) => _buildUserCard(user)),
        ],
        if (_groupResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Groups', _groupResults.length),
          ..._groupResults.take(3).map((group) => _buildGroupCard(group)),
        ],
        if (_momentResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Moments', _momentResults.length),
          ..._momentResults.take(3).map((moment) => _buildMomentCard(moment)),
        ],
      ],
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty) {
      return DuoEmptyState(
        emoji: '👤',
        title: 'No users found',
        subtitle: 'Try a different search term',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_userResults[index])
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn()
            .slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildGroupResults() {
    if (_groupResults.isEmpty) {
      return DuoEmptyState(
        emoji: '👥',
        title: 'No groups found',
        subtitle: 'Try a different search term',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
      itemCount: _groupResults.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(_groupResults[index])
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn()
            .slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildMomentResults() {
    if (_momentResults.isEmpty) {
      return DuoEmptyState(
        emoji: '📸',
        title: 'No moments found',
        subtitle: 'Try a different search term',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
      itemCount: _momentResults.length,
      itemBuilder: (context, index) {
        return _buildMomentCard(_momentResults[index])
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn()
            .slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildTrendingMoments() {
    if (_trendingMoments.isEmpty) {
      return DuoEmptyState(
        emoji: '🔥',
        title: 'No trending moments',
        subtitle: 'Check back later for hot content',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscoveryContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
        itemCount: _trendingMoments.length,
        itemBuilder: (context, index) {
          return _buildMomentCard(_trendingMoments[index])
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn()
              .slideX(begin: -0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildPopularGroups() {
    if (_popularGroups.isEmpty) {
      return DuoEmptyState(
        emoji: '⭐',
        title: 'No popular groups',
        subtitle: 'Be the first to create one',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscoveryContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
        itemCount: _popularGroups.length,
        itemBuilder: (context, index) {
          return _buildGroupCard(_popularGroups[index])
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn()
              .slideX(begin: -0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildActiveUsers() {
    if (_activeUsers.isEmpty) {
      return DuoEmptyState(
        emoji: '💬',
        title: 'No active users',
        subtitle: 'Start chatting to appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscoveryContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
        itemCount: _activeUsers.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_activeUsers[index])
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn()
              .slideX(begin: -0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildRecentMoments() {
    return FutureBuilder<List<Moment>>(
      future: ref.read(clientProvider).search.getRecentMoments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return DuoEmptyState(
            emoji: '📸',
            title: 'No recent moments',
            subtitle: 'Share your first moment',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.duoPaddingMedium),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildMomentCard(snapshot.data![index])
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn()
                  .slideX(begin: -0.1, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['userId'] as int;
    final userName = user['userName'] as String? ?? 'Unknown';
    final floor = user['floor'] as int? ?? 1;
    final creditScore = user['creditScore'] as int?;
    final messageCount = user['messageCount'] as int?;

    return DuoCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: userId),
          ),
        );
      },
      child: Row(
        children: [
          DuoAvatar(name: userName, floor: floor, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '🏢 Floor $floor',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    if (creditScore != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '⭐ $creditScore',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                    if (messageCount != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '💬 $messageCount',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textGray),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return DuoCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(group: group),
          ),
        );
      },
      child: Row(
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
            child: const Center(
              child: Text('👥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.memberCount} members',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textGray),
        ],
      ),
    );
  }

  Widget _buildMomentCard(Moment moment) {
    return DuoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              DuoAvatar(name: 'User', floor: 1, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${moment.residentId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      _formatTimestamp(moment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image
          if (moment.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
              child: Image.network(
                moment.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppTheme.backgroundLight,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),

          // Caption
          if (moment.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              moment.caption,
              style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
            ),
          ],

          // Likes
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: AppTheme.errorColor),
              const SizedBox(width: 4),
              Text(
                '${moment.likesCount} likes',
                style: const TextStyle(fontSize: 14, color: AppTheme.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
