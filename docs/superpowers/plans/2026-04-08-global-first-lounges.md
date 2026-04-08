# Global-First Lounges & Precise Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transition Lounge creation to a "Global" default and add a triple-scope region filter to search.

**Architecture:**
- **Backend:** Refactor `SearchService` to interpret the `country` search parameter with magic string logic: `null` (Any), `"GLOBAL"` (strict `null`), or `[ISO_CODE]` (strict match).
- **Frontend:** Update the creation dialog to default to Global, add Region badges to cards/profiles, and implement a new triple-option region filter in the search screen.

**Tech Stack:**
- Serverpod (Backend)
- Flutter / Riverpod (Frontend)
- PostgreSQL (Database)

---

### Task 1: Backend Search Logic Refinement

**Files:**
- Modify: `talktive_server/lib/src/services/search_service.dart`
- Test: `talktive_server/test/search_test.dart` (or create if not existing)

- [ ] **Step 1: Write integration test for triple-scope region filtering**

```dart
// talktive_server/test/search_test.dart
import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'package:talktive_server/src/services/search_service.dart';
import 'package:serverpod/serverpod.dart';

void main() {
  group('Lounge Search Region Filtering', () {
    test('filters by GLOBAL specifically', () async {
      // Logic to insert mock lounges (one global, one local)
      // Call SearchService.searchLounges(session, '', country: 'GLOBAL')
      // Expect only global lounge
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd talktive_server && dart test test/search_test.dart`
Expected: FAIL (currently "GLOBAL" magic string is not handled and will likely return nothing or match a literal "GLOBAL" code)

- [ ] **Step 3: Refactor `_buildLoungeFilters` in `search_service.dart`**

```dart
// talktive_server/lib/src/services/search_service.dart

static Expression _buildLoungeFilters(
  protocol.LoungeTable t, {
  String? query,
  String? interest,
  String? language,
  String? country,
}) {
  var expr = t.isPublic.equals(true);

  if (query != null && query.trim().isNotEmpty) {
    final q = query.trim();
    final escapedQuery = q.replaceAll("'", "''");
    expr &= (t.name.ilike('%$escapedQuery%') |
        t.description.ilike('%$escapedQuery%') |
        Expression("interests::text ilike '%$escapedQuery%'"));
  }

  // UPDATED LOGIC
  if (country == 'GLOBAL') {
    expr &= t.country.equals(null);
  } else if (country != null) {
    expr &= t.country.equals(country);
  }

  if (interest != null) {
    expr &= Expression('interests::jsonb ? \'${interest.replaceAll("'", "''")}\'');
  }
  if (language != null) {
    expr &= Expression('languages::jsonb ? \'${language.replaceAll("'", "''")}\'');
  }
  return expr;
}
```

- [ ] **Step 4: Update `getPopularLounges` and `getRecommendedLounges` to use consistent filtering**

Ensure they also use the logic where `country == 'GLOBAL'` means `t.country.equals(null)`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd talktive_server && dart test test/search_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add talktive_server/lib/src/services/search_service.dart
git commit -m "feat(backend): implement triple-scope region filtering logic in SearchService"
```

---

### Task 2: Creation Dialog - "Global First" Defaults

**Files:**
- Modify: `talktive_flutter/lib/screens/lounges/create_lounge_dialog.dart`

- [ ] **Step 1: Update initial state and reset logic**

```dart
// talktive_flutter/lib/screens/lounges/create_lounge_dialog.dart

// Change default label
String _selectedCountry = 'Global'; 
String _selectedCountryFlag = '🌍';

// In initState, handle existing null country
_selectedCountry = g.country ?? 'Global';
if (_selectedCountry == 'Global') {
  _selectedCountryFlag = '🌍';
} else {
  // standard parse logic
}
```

- [ ] **Step 2: Update UI labels and clear option**

Update the Region section to show "Global" by default and ensure the picker can be reset or "Global" can be selected as an option. Actually, keeping "Global" as the fallback when no country is picked is best.

- [ ] **Step 3: Update `_saveLounge` data mapping**

```dart
// talktive_flutter/lib/screens/lounges/create_lounge_dialog.dart

country: _selectedCountry == 'Global' ? null : _selectedCountry,
```

- [ ] **Step 4: Commit**

```bash
git add talktive_flutter/lib/screens/lounges/create_lounge_dialog.dart
git commit -m "ui(lounges): default new lounges to Global region"
```

---

### Task 3: Visual Badging - Identity Component

**Files:**
- Modify: `talktive_flutter/lib/widgets/duo/duo_lounge_card.dart`
- Modify: `talktive_flutter/lib/screens/lounges/lounge_profile_screen.dart`

- [ ] **Step 1: Create a reusable `_buildRegionBadge` helper**

```dart
Widget _buildRegionBadge(String? countryCode) {
  final isGlobal = countryCode == null || countryCode == 'Global';
  final label = isGlobal ? 'Global' : countryCode;
  final emoji = isGlobal ? '🌍' : '🚩'; // Could use a flag parser if available

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Add badge to `DuoLoungeCard`**

Insert next to the member count in `_buildInfo`.

- [ ] **Step 3: Add badge to `LoungeProfileScreen` status card**

- [ ] **Step 4: Commit**

```bash
git add talktive_flutter/lib/widgets/duo/duo_lounge_card.dart talktive_flutter/lib/screens/lounges/lounge_profile_screen.dart
git commit -m "ui(lounges): add Region badges to cards and profiles"
```

---

### Task 4: Advanced Search - Triple-Scope Filter UI

**Files:**
- Modify: `talktive_flutter/lib/screens/discovery/lounge_search_screen.dart`

- [ ] **Step 1: Update state to handle "GLOBAL" magic string**

```dart
// talktive_flutter/lib/screens/discovery/lounge_search_screen.dart
String? _selectedCountry; // null = Any, 'GLOBAL' = Global Only, 'US' = Specific
```

- [ ] **Step 2: Implement Triple-Option UI in Filter Sheet**

```dart
// Inside _showFilterSheet
_buildFilterSection(
  'Region',
  ['Any Region', 'Global Only', 'Specific Country'],
  _selectedCountry == null ? 'Any Region' : (_selectedCountry == 'GLOBAL' ? 'Global Only' : 'Specific Country'),
  (val) {
    if (val == 'Any Region') {
      _selectedCountry = null;
    } else if (val == 'Global Only') {
      _selectedCountry = 'GLOBAL';
    } else {
      _showCountryPicker(); // Opens actual picker and sets _selectedCountry to ISO code
    }
  }
)
```

- [ ] **Step 3: Update `_performSearch` to pass the value through**

- [ ] **Step 4: Commit**

```bash
git add talktive_flutter/lib/screens/discovery/lounge_search_screen.dart
git commit -m "feat(search): implement triple-scope region filter in discovery"
```
