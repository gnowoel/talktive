# Design Spec: Global-First Lounges & Precise Discovery

This document outlines the design for shifting Talktive Lounges to a "Global First" model while enhancing discovery through a triple-scope region filter.

## 1. Problem Statement
Currently, creating a lounge requires a mandatory country selection. This creates friction for creators and implies a national limitation that doesn't align with Talktive's vision of a global community. Additionally, the search functionality lacks region-based filtering.

## 2. Proposed Changes

### 2.1 Lounge Creation & Identity
*   **Default State:** The "Create Lounge" dialog will now default to **"Global"** (represented internally as `null`).
*   **UI Update:** 
    *   The region selection in `CreateLoungeDialog` will initially show "🌍 Global".
    *   If a user selects a specific country, it will store the standard country code.
*   **Visual Badging:**
    *   `DuoLoungeCard` and `LoungeProfileScreen` will display a explicit region badge.
    *   If `country` is `null` -> Display **"🌍 Global"**.
    *   If `country` is set -> Display the country's flag and code (e.g., **"🇺🇸 US"**).

### 2.2 Triple-Scope Search Filter
The Advanced Search filter sheet will include a "Region" section with three options:
1.  **"Any Region" (Default):** No filter applied. Returns all lounges (Global + all specific countries).
2.  **"Global Only":** Specifically filters for lounges where `country` is `null`.
3.  **"Specific Country":** Allows users to pick a country. Filters strictly for that country code.

### 2.3 Backend Logic Update (`SearchService`)
The `SearchService.searchLounges` and related methods will be updated to handle a "magic string" for the `country` parameter:
*   `country == null`: Match everything (default).
*   `country == "GLOBAL"`: Match where `t.country.equals(null)`.
*   `country == [ISO_CODE]`: Match where `t.country.equals([ISO_CODE])`.

## 3. Architecture & Data Flow

### 3.1 Data Model
No schema changes are required as the `country` field in the `Lounge` table is already nullable.

### 3.2 Frontend Components
*   **`CreateLoungeDialog`**: Update state management to default to "Global" and map selection to `null` if "Global" is picked.
*   **`LoungeSearchScreen`**: 
    *   Update `_showFilterSheet` to include the triple-scope region selector.
    *   Update `_performSearch` to handle the `GLOBAL` magic string.
*   **`DuoLoungeCard`**: Add the region badge next to member count or name.
*   **`LoungeProfileScreen`**: Add the region badge to the header or status card.

### 3.3 Backend Services
*   **`LoungeEndpoint`**: Ensure `createLounge` and `updateLounge` validation allows `null` country (which it already does).
*   **`SearchService`**: Refactor `_buildLoungeFilters` to implement the logic described in 2.3.

## 4. User Experience (UX)
*   **Reduced Friction:** Users can create a group in seconds without thinking about geography.
*   **Explicit Identity:** Groups that *want* to be global are clearly labeled, giving them a distinct "vibe."
*   **Powerful Discovery:** Users in specific regions can find their local community easily, while others can find purely global spaces.

## 5. Testing Strategy
*   **Manual Testing:**
    1.  Create a lounge with the default "Global" setting and verify it shows the "🌍 Global" badge.
    2.  Create a lounge with a specific country and verify the flag and code appear.
    3.  Verify "Any Region" search returns both.
    4.  Verify "Global Only" search returns only global lounges.
    5.  Verify specific country search returns only lounges for that country.
*   **Integration Testing:** Add a test case in `talktive_server/test` for filtered lounge searches.
