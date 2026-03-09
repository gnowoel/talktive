import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_group_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../helpers/snackbar_helper.dart';
import 'group_profile_screen.dart';

class GroupSearchScreen extends ConsumerStatefulWidget {
  const GroupSearchScreen({super.key});

  @override
  ConsumerState<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends ConsumerState<GroupSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Group> _results = [];
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
      final results = await client.group.searchPublicGroups('', limit: 10, offset: 0);
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
      final results = await client.group.searchPublicGroups(query, limit: 20, offset: 0);
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
        SnackBarHelper.showError(context, 'Search failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search Clubs...',
            border: InputBorder.none,
          ),
          onChanged: (val) => _performSearch(val),
        ),
      ),
      body: _isLoading
          ? const Center(child: DuoLoadingIndicator())
          : _results.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
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
        ..._results.asMap().entries.map((entry) => _buildSearchResultCard(entry.value, entry.key)),
      ],
    );
  }

  Widget _buildSearchResultCard(Group group, int index) {
    return DuoGroupCard(
      group: group,
      showInterests: true,
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(
          '/groups/profile/${group.id!}',
          extra: group,
        );
      },
      bottomActions: [
        SizedBox(
          width: double.infinity,
          child: DuoButton(
            text: 'Apply to Join',
            onPressed: () async {
              try {
                await ref.read(groupListProvider.notifier).applyToGroup(group.id!);
                if (mounted) {
                  SnackBarHelper.showSuccess(context, 'Application sent!');
                }
              } catch (e) {
                if (mounted) {
                  SnackBarHelper.showError(context, 'Failed to apply: $e');
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
      title: 'No Clubs Found',
      subtitle: 'Try a different name or interest tag!',
    );
  }
}

