import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../providers/lounge_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_lounge_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_empty_state.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';

class LoungeSearchScreen extends ConsumerStatefulWidget {
  const LoungeSearchScreen({super.key});

  @override
  ConsumerState<LoungeSearchScreen> createState() => _LoungeSearchScreenState();
}

class _LoungeSearchScreenState extends ConsumerState<LoungeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Lounge> _results = [];
  bool _isLoading = false;
  bool _isRecommendation = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(clientProvider);
      final results = await client.lounge.searchPublicLounges(
        '',
        limit: 10,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _isRecommendation = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _fetchRecommendations();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(clientProvider);
      final results = await client.lounge.searchPublicLounges(
        query,
        limit: 20,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _isRecommendation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        DuoSnackBarHelper.showError(context, 'Search failed: $e');
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading && _results.isEmpty
          ? const Center(child: DuoLoadingIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search Header
        Container(
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          color: Colors.white,
          child: DuoInput(
            controller: _searchController,
            hintText: 'Search by lounge name or interests...',
            prefixIcon: Icons.search,
            iconColor: AppTheme.duoBlue,
            onChanged: (val) => _performSearch(val),
            autofocus: true,
          ),
        ),
        
        // Results
        Expanded(
          child: _results.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isRecommendation) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              '💡 SUGGESTED FOR YOU',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.duoBlue,
                fontSize: 12,
              ),
            ),
          ),
        ],
        ..._results.asMap().entries.map(
          (entry) => _buildSearchResultCard(entry.value, entry.key),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(Lounge lounge, int index) {
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
                await ref
                    .read(loungeListProvider.notifier)
                    .applyToLounge(lounge.id!);
                if (mounted) {
                  DuoSnackBarHelper.showSuccess(context, 'Application sent!');
                }
              } catch (e) {
                if (mounted) {
                  DuoSnackBarHelper.showError(context, 'Failed to apply: $e');
                }
              }
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return const DuoEmptyState(
      emoji: '🔦',
      title: 'No Lounges Found',
      subtitle: 'Try a different name or interest tag!',
    );
  }
}
