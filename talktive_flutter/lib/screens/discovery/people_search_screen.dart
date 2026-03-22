import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart' as protocol;

import '../../config/theme.dart';
import '../../providers/client_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_avatar.dart';

class PeopleSearchScreen extends ConsumerStatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  ConsumerState<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends ConsumerState<PeopleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<protocol.UserSummary>? _searchResults;
  List<protocol.UserSummary>? _suggestedUsers;
  bool _isLoading = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    final isPremium =
        ref.read(currentResidentProvider).value?.isPremium ?? false;
    if (!isPremium) return;

    setState(() => _isLoading = true);
    try {
      final client = ref.read(clientProvider);
      final feed = await client.search.getDiscoveryFeed(limit: 10);
      if (mounted) {
        setState(() {
          _suggestedUsers = [
            ...feed.usersByInterests,
            ...feed.usersByLanguages,
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = null;
        _searchQuery = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final client = ref.read(clientProvider);
      final results = await client.search.searchAll(query, limit: 20);
      if (mounted) {
        setState(() {
          _searchResults = results.users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentResident = ref.watch(currentResidentProvider).value;
    final isPremium = currentResident?.isPremium ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Find People',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DuoInput(
              controller: _searchController,
              hintText: 'Search by name or interests...',
              prefixIcon: Icons.search,
              iconColor: AppTheme.duoOrange,
              enabled: isPremium,
              onChanged: (val) => _performSearch(val),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: !isPremium ? _buildLockedState() : _buildContent(),
    );
  }

  Widget _buildLockedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.lock, size: 80, color: AppTheme.duoOrange),
          const SizedBox(height: 24),
          const Text(
            'Neighbor Discovery',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Finding specific neighbors is a Talktive Plus feature. Unlock the building map to find people by name or shared interests!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),
          DuoButton(
            text: 'Upgrade to Plus',
            onPressed: () => context.push('/activity/settings'),
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Maybe Later'),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildContent() {
    if (_isLoading && (_searchQuery != null)) {
      return const Center(child: DuoLoadingIndicator());
    }

    final list = (_searchQuery != null && _searchQuery!.isNotEmpty)
        ? _searchResults
        : _suggestedUsers;

    if (list == null || list.isEmpty) {
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        return const DuoEmptyState(
          icon: Icons.people,
          title: 'No neighbors found',
          subtitle: 'Try a different name or interest',
        );
      }
      return const Center(child: DuoLoadingIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildUserCard(list[index], index),
    );
  }

  Widget _buildUserCard(protocol.UserSummary user, int index) {
    return DuoCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(
          '/user/${user.userId}',
          extra: {
            'userName': user.userName,
            'userAvatar': user.userAvatar,
            'userFloor': user.floor,
          },
        );
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (user.userMood != null)
                    Text(
                      user.userMood!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Floor ${user.floor}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.duoBlue,
                        ),
                      ),
                      if (user.matchScore != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.bolt, size: 14, color: AppTheme.duoGreen),
                        Text(
                          '${user.matchScore}% Match',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.duoGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
