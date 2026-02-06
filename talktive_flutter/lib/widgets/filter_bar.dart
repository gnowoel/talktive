import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String? selectedGender;
  final String? selectedLanguage;
  final Function(String?) onGenderChanged;
  final Function(String?) onLanguageChanged;
  final VoidCallback onReset;

  const FilterBar({
    super.key,
    required this.selectedGender,
    required this.selectedLanguage,
    required this.onGenderChanged,
    required this.onLanguageChanged,
    required this.onReset,
  });

  static final _genderOptions = [
    {'label': 'All Genders', 'value': null},
    {'label': 'Female', 'value': 'F'},
    {'label': 'Male', 'value': 'M'},
    {'label': 'Other', 'value': 'O'},
    {'label': 'Not Specified', 'value': 'X'},
  ];

  static final _languageOptions = [
    {'label': 'All Languages', 'value': null},
    {'label': 'English', 'value': 'en'},
    {'label': 'Arabic', 'value': 'ar'},
    // {'label': 'Chinese', 'value': 'zh'},
    {'label': 'French', 'value': 'fr'},
    // {'label': 'Greek', 'value': 'el'},
    // {'label': 'Hungarian', 'value': 'hu'},
    // {'label': 'Indonesian', 'value': 'id'},
    {'label': 'Portuguese', 'value': 'pt'},
    {'label': 'Spanish', 'value': 'es'},
    // Add more languages as needed
  ];

  @override
  Widget build(BuildContext context) {
    // final hasFilters = selectedGender != null || selectedLanguage != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              context: context,
              value: selectedGender,
              items: _genderOptions,
              onChanged: onGenderChanged,
              hint: 'Gender',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterDropdown(
              context: context,
              value: selectedLanguage,
              items: _languageOptions,
              onChanged: onLanguageChanged,
              hint: 'Language',
            ),
          ),
          // if (hasFilters) ...[
          //   const SizedBox(width: 8),
          //   IconButton(
          //     icon: const Icon(Icons.clear),
          //     onPressed: canRefresh ? onReset : null,
          //     tooltip: 'Reset filters',
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String? value,
    required List<Map<String, String?>> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item['value'],
              child: Text(
                item['label']!,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
