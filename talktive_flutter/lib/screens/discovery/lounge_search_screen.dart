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
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_lounge_card.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';

class LoungeSearchScreen extends ConsumerStatefulWidget {
  const LoungeSearchScreen({super.key});

  @override
  ConsumerState<LoungeSearchScreen> createState() => _LoungeSearchScreenState();
}

class _LoungeSearchScreenState extends ConsumerState<LoungeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<protocol.Lounge>? _searchResults;
  List<protocol.Lounge>? _recommendedLounges;
  List<protocol.Lounge>? _popularLounges;
  bool _isLoading = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _fetchLounges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLounges() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(clientProvider);
      final feed = await client.search.getDiscoveryFeed(limit: 20);
      if (mounted) {
        setState(() {
          _recommendedLounges = feed.recommendedLounges;
          _popularLounges = feed.popularLounges;
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
          _searchResults = results.lounges;
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Find Lounges',
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
              hintText: 'Search interest-based community lounges...',
              prefixEmoji: '🔍',
              iconColor: AppTheme.duoBlue,
              enabled: true,
              onChanged: (val) => _performSearch(val),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Text('❌', style: TextStyle(fontSize: 18)),
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
      body: _buildContent(),
    );
  }

  // _buildLockedState is no longer used but we can keep it as a helper or remove it. 
  // I will remove it to keep the file clean as per user's "essential for all" request.

  Widget _buildContent() {
    if (_isLoading && (_searchQuery != null || (_recommendedLounges == null && _popularLounges == null))) {
      return const Center(child: DuoLoadingIndicator());
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final lounges = _searchResults ?? [];
      if (lounges.isEmpty) return const DuoEmptyState(emoji: '🏘️', title: 'No lounges found', subtitle: 'Try searching for different interests');
      return _buildLoungeList(lounges);
    }

    final recommended = _recommendedLounges ?? [];
    final popular = _popularLounges ?? [];

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
        if (recommended.isEmpty && popular.isEmpty)
          const DuoEmptyState(emoji: '🔭', title: 'Waiting for recommendation', subtitle: 'Update your interests to find best lounges!'),
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
}
