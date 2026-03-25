import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart' as protocol;
import '../../config/interests.dart';

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

  // Search Filters
  String? _selectedGender;
  String? _selectedAgeRange;
  String? _selectedLanguage;
  String? _selectedInterest;
  String? _selectedCountry;
  bool _onlyPremium = false;

  final List<Map<String, String>> _genderOptions = [
    {'label': 'Male', 'value': 'male'},
    {'label': 'Female', 'value': 'female'},
    {'label': 'Non-binary', 'value': 'non-binary'},
    {'label': 'Private', 'value': 'prefer-not-to-say'},
  ];
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
  final List<String> _ageRanges = ['Under 18', '18-24', '25-34', '35-44', '45-54', '55+'];

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
      // Fetch recommendations (empty search)
      final results = await client.search.searchUsers(null, limit: 20);
      if (mounted) {
        setState(() {
          _suggestedUsers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    final hasFilters = _selectedGender != null || 
                      _selectedAgeRange != null || 
                      _selectedLanguage != null || 
                      _selectedInterest != null || 
                      _selectedCountry != null ||
                      _onlyPremium;

    if (query.trim().isEmpty && !hasFilters) {
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
      final results = await client.search.searchUsers(
        query.isEmpty ? null : query,
        gender: _selectedGender,
        ageRange: _selectedAgeRange,
        language: _selectedLanguage,
        interest: _selectedInterest,
        country: _selectedCountry,
        isPremium: _onlyPremium ? true : null,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
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
            child: Row(
              children: [
                Expanded(
                  child: DuoInput(
                    controller: _searchController,
                    hintText: 'Search Neighbors...',
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isPremium ? _showFilterSheet : null,
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: (_selectedGender != null || 
                            _selectedAgeRange != null || 
                            _selectedLanguage != null || 
                            _selectedInterest != null || 
                            _selectedCountry != null ||
                            _onlyPremium)
                        ? AppTheme.primaryColor
                        : Colors.grey[600],
                  ),
                ),
              ],
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
          const Text('🔒', style: TextStyle(fontSize: 80)),
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
          emoji: '👥',
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
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
                        'Search Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedGender = null;
                            _selectedAgeRange = null;
                            _selectedLanguage = null;
                            _selectedInterest = null;
                            _selectedCountry = null;
                            _onlyPremium = false;
                          });
                          setState(() {
                             _selectedGender = null;
                            _selectedAgeRange = null;
                            _selectedLanguage = null;
                            _selectedInterest = null;
                            _selectedCountry = null;
                            _onlyPremium = false;
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
                        'Gender',
                        _genderOptions.map((e) => e['label']!).toList(),
                        _genderOptions.firstWhere((e) => e['value'] == _selectedGender, orElse: () => {'label': ''})['label'],
                        (label) => setSheetState(() {
                          _selectedGender = label == null ? null : _genderOptions.firstWhere((e) => e['label'] == label)['value'];
                          setState(() {});
                        }),
                      ),
                      const SizedBox(height: 24),
                      _buildFilterSection(
                        'Age Range',
                        _ageRanges,
                        _selectedAgeRange,
                        (val) => setSheetState(() {
                          _selectedAgeRange = val;
                          setState(() {});
                        }),
                      ),
                      const SizedBox(height: 24),
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
                        'Interests',
                        AppInterests.all,
                        _selectedInterest,
                        (val) => setSheetState(() {
                          _selectedInterest = val;
                          setState(() {});
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Premium Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Talktive Plus Only',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Find premium neighbors',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _onlyPremium,
                            activeTrackColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              setSheetState(() {
                                _onlyPremium = val;
                                setState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      DuoButton(
                        text: 'Apply Filters',
                        onPressed: () {
                          Navigator.pop(context);
                          _performSearch(_searchController.text);
                        },
                        width: double.infinity,
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
              color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
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
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      width: 2,
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
                        const Text('⚡', style: TextStyle(fontSize: 14)),
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
