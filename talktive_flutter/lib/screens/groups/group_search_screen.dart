import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../helpers/snackbar_helper.dart';

class GroupSearchScreen extends ConsumerStatefulWidget {
  const GroupSearchScreen({super.key});

  @override
  ConsumerState<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends ConsumerState<GroupSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Group> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    
    try {
      final client = ref.read(clientProvider);
      final results = await client.group.searchPublicGroups(query, limit: 50, offset: 0);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to search groups');
      }
    }
  }

  Future<void> _applyToGroup(int groupId) async {
    HapticFeedback.mediumImpact();
    
    // Optimistically update UI to show applied loading state
    final originalResults = List<Group>.from(_searchResults);
    
    try {
      await ref.read(groupListProvider.notifier).applyToGroup(groupId);
      
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Application sent!');
        // Ideally we would want to reflect the "Applied" status, but since the
        // search endpoint returns pure groups, we can just remove it from search
        setState(() {
          _searchResults.removeWhere((g) => g.id == groupId);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : 'Could not apply');
        setState(() {
          _searchResults = originalResults;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Find a Club', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter an interest, e.g. "Bikes"',
                hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                prefixIcon: Icon(Icons.search, color: AppTheme.duoBlue),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: DuoLoadingIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: DuoEmptyState(
          emoji: '🔍',
          title: 'Search Clubs',
          subtitle: 'Find public groups to join',
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: DuoEmptyState(
          emoji: '🤔',
          title: 'No groups found',
          subtitle: 'Try a different search term',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        return _buildSearchResultCard(group, index);
      },
    );
  }

  Widget _buildSearchResultCard(Group group, int index) {
    return DuoCard(
      margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.duoYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      group.emoji ?? '👥',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberCount}/${group.maxMembers} members',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description != null && group.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                group.description!,
                style: TextStyle(color: Colors.grey[800]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: DuoButton(
                text: 'Apply to Join',
                color: AppTheme.duoGreen,
                onPressed: () => _applyToGroup(group.id!),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
