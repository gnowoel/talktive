import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart' as protocol;
import '../../config/interests.dart';
import '../../config/languages.dart';

import '../../config/theme.dart';
import '../../providers/client_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../helpers/resident_ext.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_floor_badge.dart';
import '../../helpers/duo_snackbar_helper.dart';

class PeopleSearchScreen extends ConsumerStatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  ConsumerState<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends ConsumerState<PeopleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<protocol.UserSummary>? _users;
  bool _isLoading = false;
  String? _errorMessage;

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
  final List<String> _ageRanges = [
    'Under 18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    _performSearch('');
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(clientProvider);
      final results = await client.search.searchUsers(
        query.trim().isEmpty ? null : query.trim(),
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
          _users = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        DuoSnackBarHelper.showError(context, 'Search failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentResident = ref.watch(currentResidentProvider).value;
    final bool isPlus = currentResident?.isPlus ?? false;
    final bool hasAdvancedSearch =
        isPlus && (currentResident?.showAdvancedDiscovery ?? true);

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
                  child: GestureDetector(
                    onTap: hasAdvancedSearch
                        ? null
                        : () {
                            if (!isPlus) {
                              _showUpgradePrompt();
                            } else {
                              DuoSnackBarHelper.showActionRequired(
                                context,
                                'Please enable Advanced Search in Settings. ⚙️',
                              );
                            }
                          },
                    child: DuoInput(
                      controller: _searchController,
                      hintText: hasAdvancedSearch
                          ? 'Search Neighbors...'
                          : 'Advanced Search (Plus)',
                      prefixIcon: hasAdvancedSearch
                          ? Icons.search
                          : Icons.lock_outline,
                      iconColor: AppTheme.duoOrange,
                      enabled: hasAdvancedSearch,
                      onChanged: _onSearchChanged,
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
                  onPressed: hasAdvancedSearch
                      ? _showFilterSheet
                      : () {
                          if (!isPlus) {
                            _showUpgradePrompt();
                          } else {
                            DuoSnackBarHelper.showActionRequired(
                              context,
                              'Please enable Advanced Search in Settings. ⚙️',
                            );
                          }
                        },
                  icon: Icon(
                    hasAdvancedSearch
                        ? Icons.filter_list_rounded
                        : Icons.lock_outline,
                    color: _hasActiveFilters
                        ? AppTheme.primaryColor
                        : Colors.grey[600],
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
      _selectedGender != null ||
      _selectedAgeRange != null ||
      _selectedLanguage != null ||
      _selectedInterest != null ||
      _selectedCountry != null ||
      _onlyPremium;

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (_selectedGender != null)
            _buildFilterPill(
              _genderOptions.firstWhere(
                (e) => e['value'] == _selectedGender,
              )['label']!,
              () => setState(() {
                _selectedGender = null;
                _performSearch(_searchController.text);
              }),
            ),
          if (_selectedAgeRange != null)
            _buildFilterPill(
              _selectedAgeRange!,
              () => setState(() {
                _selectedAgeRange = null;
                _performSearch(_searchController.text);
              }),
            ),
          if (_selectedLanguage != null)
            _buildFilterPill(
              _languageOptions.firstWhere(
                (e) => e['value'] == _selectedLanguage,
              )['label']!,
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
          if (_onlyPremium)
            _buildFilterPill(
              'Plus Only',
              () => setState(() {
                _onlyPremium = false;
                _performSearch(_searchController.text);
              }),
              icon: Icons.star_rounded,
              color: AppTheme.duoOrange,
            ),
          // Clear All link
          GestureDetector(
            onTap: () => setState(() {
              _selectedGender = null;
              _selectedAgeRange = null;
              _selectedLanguage = null;
              _selectedInterest = null;
              _selectedCountry = null;
              _onlyPremium = false;
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

  Widget _buildFilterPill(
    String label,
    VoidCallback onRemove, {
    IconData? icon,
    Color? color,
  }) {
    final pillColor = color ?? AppTheme.primaryColor;
    return Material(
      color: pillColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pillColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: pillColor),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: pillColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 12,
                color: pillColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
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
              'Searching for specific neighbors and applying advanced filters is a Talktive Plus feature.',
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
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Neighbors'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _users == null) {
      return const Center(child: DuoLoadingIndicator());
    }

    final list = _users ?? [];

    if (list.isEmpty) {
      if (_isLoading) return const Center(child: DuoLoadingIndicator());

      return const DuoEmptyState(
        emoji: '👥',
        title: 'No neighbors found',
        subtitle: 'Try a different name or interest',
      );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
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
                        _genderOptions.firstWhere(
                          (e) => e['value'] == _selectedGender,
                          orElse: () => {'label': ''},
                        )['label'],
                        (label) => setSheetState(() {
                          _selectedGender = label == null
                              ? null
                              : _genderOptions.firstWhere(
                                  (e) => e['label'] == label,
                                )['value'];
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
                        _languageOptions.firstWhere(
                          (e) => e['value'] == _selectedLanguage,
                          orElse: () => {'label': ''},
                        )['label'],
                        (label) => setSheetState(() {
                          _selectedLanguage = label == null
                              ? null
                              : _languageOptions.firstWhere(
                                  (e) => e['label'] == label,
                                )['value'];
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
    // Determine gender symbol
    String? genderSymbol;
    if (user.gender != null && user.gender != 'prefer-not-to-say') {
      genderSymbol = switch (user.gender) {
        'male' => '♂️',
        'female' => '♀️',
        'non-binary' => '⚧️',
        _ => null,
      };
    }

    // Determine age display
    final ageDisplay = user.ageRange != null && user.ageRange != 'Not Specified'
        ? user.ageRange
        : null;

    // Determine languages display
    final languages = user.languages ?? [];
    final languagesDisplay = languages.isNotEmpty
        ? (languages.length > 2
              ? '${languages.take(2).map((c) => AppLanguages.getName(c)).join(', ')} +${languages.length - 2}'
              : languages.map((c) => AppLanguages.getName(c)).join(', '))
        : null;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DuoAvatar(
              imageUrl: user.userAvatar,
              size: 56,
              isOnline: user.isOnline,
              showMood: false,
              showFloor: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row: Name + Mood + Floor
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.userName ?? 'Resident',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.userMood != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          user.userMood!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      const SizedBox(width: 8),
                      DuoFloorBadge(floor: user.floor),
                      if (user.matchScore != null) ...[
                        const Spacer(),
                        Text(
                          '${user.matchScore}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.duoGreen,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text('⚡', style: TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),

                  // Bio on the second line
                  if (user.userBio != null && user.userBio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        user.userBio!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontFamily: 'Rubik',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Metadata Row: Gender/Age · Languages
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Rubik',
                    ),
                    child: Row(
                      children: [
                        if (genderSymbol != null || ageDisplay != null) ...[
                          Text([?genderSymbol, ?ageDisplay].join(' ')),
                          if (languagesDisplay != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text('·'),
                            ),
                        ],
                        if (languagesDisplay != null) ...[
                          const Icon(
                            Icons.language_rounded,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              languagesDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
