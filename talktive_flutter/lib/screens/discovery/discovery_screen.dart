import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart' as protocol;

import '../../config/theme.dart';
import '../../providers/client_provider.dart';
import '../../providers/lounge_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_lounge_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';

/// Comprehensive Discovery screen combining Users, Lounges, and Moments search
class DiscoveryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const DiscoveryScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  protocol.DiscoveryFeed? _discoveryFeed;
  protocol.SearchAllResults? _searchResults;
  
  bool _isLoadingFeed = true;
  bool _isSearching = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTabIndex,
    );
    _fetchDiscoveryFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiscoveryFeed() async {
    setState(() => _isLoadingFeed = true);
    try {
      final client = ref.read(clientProvider);
      final feed = await client.search.getDiscoveryFeed(limit: 20);
      if (mounted) {
        setState(() {
          _discoveryFeed = feed;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching discovery feed: $e');
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
        _searchQuery = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final client = ref.read(clientProvider);
      final results = await client.search.searchAll(query, limit: 20);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Discovery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DuoInput(
                  controller: _searchController,
                  hintText: 'Search people, lounges, or moments...',
                  prefixIcon: Icons.search,
                  iconColor: AppTheme.duoBlue,
                  onChanged: (val) => _performSearch(val),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.duoBlue,
                indicatorWeight: 3,
                labelColor: AppTheme.duoBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'People'),
                  Tab(text: 'Lounges'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPeopleTab(),
          _buildLoungeTab(),
        ],
      ),
    );
  }

  Widget _buildLoungeTab() {
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      if (_isSearching) return const Center(child: DuoLoadingIndicator());
      final lounges = _searchResults?.lounges ?? [];
      if (lounges.isEmpty) return const DuoEmptyState(emoji: '🏘️', title: 'No lounges found', subtitle: 'Try searching for different interests');
      return _buildLoungeList(lounges);
    }

    if (_isLoadingFeed) return const Center(child: DuoLoadingIndicator());
    
    final recommended = _discoveryFeed?.recommendedLounges ?? [];
    final popular = _discoveryFeed?.popularLounges ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recommended.isNotEmpty) ...[
          _buildSectionHeader('💡 RECOMMENDED FOR YOU'),
          ...recommended.asMap().entries.map((e) => _buildLoungeCard(e.value, e.key)),
          const SizedBox(height: 24),
        ],
        if (popular.isNotEmpty) ...[
          _buildSectionHeader('🔥 POPULAR LOUNGES'),
          ...popular.asMap().entries.map((e) => _buildLoungeCard(e.value, e.key + 10)),
        ],
      ],
    );
  }

  Widget _buildPeopleTab() {
    final currentResident = ref.watch(currentResidentProvider).value;
    final isPremium = currentResident?.isPremium ?? false;

    if (!isPremium) {
      return DuoEmptyState(
        emoji: '💎',
        title: 'Neighbors Discovery',
        subtitle: 'Finding specific neighbors is a Premium feature. Unlock the building map today!',
        actionLabel: 'Upgrade to Pro',
        onActionPressed: () {
          HapticFeedback.heavyImpact();
          context.push('/activity/settings'); // To upgrade
        },
      );
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      if (_isSearching) return const Center(child: DuoLoadingIndicator());
      final users = _searchResults?.users ?? [];
      if (users.isEmpty) return const DuoEmptyState(emoji: '👥', title: 'No residents found', subtitle: 'Try a different name');
      return _buildUserList(users);
    }

    if (_isLoadingFeed) return const Center(child: DuoLoadingIndicator());

    final byInterests = _discoveryFeed?.usersByInterests ?? [];
    final byLanguages = _discoveryFeed?.usersByLanguages ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (byInterests.isNotEmpty) ...[
          _buildSectionHeader('🤝 SHARED INTERESTS'),
          ...byInterests.asMap().entries.map((e) => _buildUserCard(e.value, e.key)),
          const SizedBox(height: 24),
        ],
        if (byLanguages.isNotEmpty) ...[
          _buildSectionHeader('🗣️ SPEAK YOUR LANGUAGE'),
          ...byLanguages.asMap().entries.map((e) => _buildUserCard(e.value, e.key + 10)),
        ],
      ],
    );
  }



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.duoBlue,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLoungeList(List<protocol.Lounge> lounges) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lounges.length,
      itemBuilder: (context, index) => _buildLoungeCard(lounges[index], index),
    );
  }

  Widget _buildLoungeCard(protocol.Lounge lounge, int index) {
    return DuoLoungeCard(
      lounge: lounge,
      showInterests: true,
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/lounges/profile/${lounge.id!}', extra: lounge);
      },
      bottomActions: [
        SizedBox(
          width: double.infinity,
          child: DuoButton(
            text: 'Apply to Join',
            onPressed: () async {
              try {
                await ref.read(loungeListProvider.notifier).applyToLounge(lounge.id!);
                if (mounted) DuoSnackBarHelper.showSuccess(context, 'Application sent!');
              } catch (e) {
                if (mounted) DuoSnackBarHelper.showError(context, 'Failed: $e');
              }
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildUserList(List<protocol.UserSummary> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index], index),
    );
  }

  Widget _buildUserCard(protocol.UserSummary user, int index) {
    return DuoCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/user/${user.userId}', extra: {
          'userName': user.userName,
          'userAvatar': user.userAvatar,
          'userFloor': user.floor,
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DuoAvatar(
              imageUrl: user.userAvatar,
              size: 48,
              floorLevel: user.floor,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName ?? 'Resident',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (user.userMood != null)
                    Text(
                      user.userMood!,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Floor ${user.floor}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.duoBlue)),
                      if (user.matchScore != null) ...[
                        const SizedBox(width: 8),
                        Text('⚡ ${user.matchScore}% Match', style: const TextStyle(fontSize: 12, color: AppTheme.duoGreen, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
