import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart' as protocol;
import '../../config/interests.dart';

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

  // Search Filters
  String? _selectedLanguage;
  String? _selectedInterest;
  String? _selectedCountry;

  final List<Map<String, String>> _languageOptions = [
    {'label': 'English', 'value': 'en'},
    {'label': 'Spanish', 'value': 'es'},
    {'label': 'French', 'value': 'fr'},
    {'label': 'German', 'value': 'de'},
    {'label': 'Chinese', 'value': 'zh'},
    {'label': 'Japanese', 'value': 'ja'},
    {'label': 'Arabic', 'value': 'ar'},
    {'label': 'Portuguese', 'value': 'pt'},
  ];

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final client = ref.read(clientProvider);
      
      if (query.trim().isEmpty) {
        // No query, fetch filtered discovery feed
        final feed = await client.search.getDiscoveryFeed(
          interest: _selectedInterest,
          language: _selectedLanguage,
          country: _selectedCountry,
          limit: 20,
        );
        if (mounted) {
          setState(() {
            _recommendedLounges = feed.recommendedLounges;
            _popularLounges = feed.popularLounges;
            _searchResults = null;
            _isLoading = false;
          });
        }
      } else {
        // Query provided, perform search with filters
        final results = await client.search.searchLounges(
          query.trim(),
          interest: _selectedInterest,
          language: _selectedLanguage,
          country: _selectedCountry,
          limit: 20,
        );
        if (mounted) {
          setState(() {
            _searchResults = results;
            _recommendedLounges = null;
            _popularLounges = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(currentResidentProvider).value?.isPremium ?? false;

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
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isPremium ? null : _showUpgradePrompt,
                    child: DuoInput(
                      controller: _searchController,
                      hintText: isPremium ? 'Search Lounges...' : 'Advanced Search (Plus)',
                      prefixIcon: isPremium ? Icons.search : Icons.lock_outline,
                      iconColor: AppTheme.duoBlue,
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isPremium ? _showFilterSheet : _showUpgradePrompt,
                  icon: Icon(
                    isPremium ? Icons.filter_list_rounded : Icons.lock_outline,
                    color: _hasActiveFilters
                        ? AppTheme.duoBlue
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_hasActiveFilters) _buildActiveFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedLanguage != null ||
      _selectedInterest != null ||
      _selectedCountry != null;

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (_selectedLanguage != null)
            _buildFilterPill(
              _languageOptions.firstWhere((e) => e['value'] == _selectedLanguage)['label']!,
              () => setState(() {
                _selectedLanguage = null;
                _performSearch(_searchController.text);
              }),
            ),
          if (_selectedInterest != null)
            _buildFilterPill(
              _selectedInterest!,
              () => setState(() {
                _selectedInterest = null;
                _performSearch(_searchController.text);
              }),
            ),
          if (_selectedCountry != null)
            _buildFilterPill(
              _selectedCountry!,
              () => setState(() {
                _selectedCountry = null;
                _performSearch(_searchController.text);
              }),
            ),
          // Clear All link
          GestureDetector(
            onTap: () => setState(() {
              _selectedLanguage = null;
              _selectedInterest = null;
              _selectedCountry = null;
              _performSearch(_searchController.text);
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, VoidCallback onRemove) {
    const pillColor = AppTheme.duoBlue;
    return Material(
      color: pillColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pillColor.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: pillColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.close, size: 12, color: pillColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildContent() {
    if (_isLoading &&
        (_searchQuery == null ||
            (_recommendedLounges == null && _popularLounges == null && _searchResults == null))) {
      return const Center(child: DuoLoadingIndicator());
    }

    if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
      final lounges = _searchResults ?? [];
      if (lounges.isEmpty) {
        if (_isLoading) return const Center(child: DuoLoadingIndicator());
        return const DuoEmptyState(
          emoji: '🏘️',
          title: 'No lounges found',
          subtitle: 'Try searching for different interests',
        );
      }
      return _buildLoungeList(lounges);
    }

    final recommended = _recommendedLounges ?? [];
    final popular = _popularLounges ?? [];

    if (recommended.isEmpty && popular.isEmpty) {
      if (_isLoading) return const Center(child: DuoLoadingIndicator());
      return const DuoEmptyState(
        emoji: '🔍',
        title: 'No lounges found',
        subtitle: 'Try adjusting your filters!',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recommended.isNotEmpty) ...[
          _buildSectionHeader('RECOMMENDED FOR YOU', emoji: '✨'),
          ...recommended.asMap().entries.map(
            (e) => _buildLoungeCard(e.value, e.key),
          ),
          const SizedBox(height: 24),
        ],
        if (popular.isNotEmpty) ...[
          _buildSectionHeader('POPULAR LOUNGES', emoji: '🔥'),
          ...popular.asMap().entries.map(
            (e) => _buildLoungeCard(e.value, e.key + 10),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, String? emoji}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 16))
          else if (icon != null)
            Icon(icon, size: 16, color: AppTheme.duoBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.duoBlue,
              fontSize: 12,
            ),
          ),
        ],
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
                await ref
                    .read(loungeListProvider.notifier)
                    .applyToLounge(lounge.id!);
                if (mounted) {
                  DuoSnackBarHelper.showSuccess(context, 'Application sent!');
                }
              } catch (e) {
                if (mounted) DuoSnackBarHelper.showError(context, 'Failed: $e');
              }
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lounge Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedLanguage = null;
                            _selectedInterest = null;
                            _selectedCountry = null;
                          });
                          setState(() {
                            _selectedLanguage = null;
                            _selectedInterest = null;
                            _selectedCountry = null;
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildFilterSection(
                        'Language',
                        _languageOptions.map((e) => e['label']!).toList(),
                        _languageOptions.firstWhere((e) => e['value'] == _selectedLanguage, orElse: () => {'label': ''})['label'],
                        (label) => setSheetState(() {
                          _selectedLanguage = label == null ? null : _languageOptions.firstWhere((e) => e['label'] == label)['value'];
                          setState(() {});
                        }),
                      ),
                      const SizedBox(height: 24),
                      _buildFilterSection(
                        'Primary Interest',
                        AppInterests.all,
                        _selectedInterest,
                        (val) => setSheetState(() {
                          _selectedInterest = val;
                          setState(() {});
                        }),
                      ),
                      const SizedBox(height: 40),
                      DuoButton(
                        text: 'Apply Filters',
                        onPressed: () {
                          Navigator.pop(context);
                          _performSearch(_searchController.text);
                        },
                        width: double.infinity,
                        color: AppTheme.duoBlue,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selectedValue,
    Function(String?) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return Material(
              color: isSelected ? AppTheme.duoBlue : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelected(isSelected ? null : option);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.duoBlue : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  void _showUpgradePrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Advanced Discovery',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Searching for specific lounges and applying advanced filters is a Talktive Plus feature.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            DuoButton(
              text: 'Upgrade to Plus',
              onPressed: () {
                Navigator.pop(context);
                context.push('/activity/settings');
              },
              width: double.infinity,
              color: AppTheme.duoBlue,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Lounges'),
            ),
          ],
        ),
      ),
    );
  }
}
