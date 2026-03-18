# Talktive Design System

## 🏛️ Core Philosophy: The Apartment Building Metaphor

Talktive is not just a chat app; it is a digital residence. This metaphor guides every UI decision:

*   **Plaza (Lobby)**: Public, bustling, and open. The building's social heart.
*   **Moments (Bulletin Board)**: Visual, community-driven, and shared.
*   **Chats (Private Units)**: Intimate, secure, and personal.
*   **Lounges (Clubhouse)**: The primary term for interest-based communities. They feel like relaxed shared spaces where residents hang out.
*   **Profile (My Unit)**: Your personal identity and sanctuary.

These structural elements are unified by an **inviting, friendly tone**—using soft typography, warm emojis, and community-centric language to make the building feel like home.

---

## 🎨 Visual Identity: Duolingo-Inspired UX

We embrace a playful, high-energy aesthetic that makes interaction feel like a game rather than a chore.

### 1. Color Palette
*   **Primary Purple** (`#6C63FF`): The core brand color, used for primary actions and branding.
*   **Secondary Pink** (`#FF6584`): Used for accents and "Moments" branding.
*   **Accent Cyan** (`#00D9FF`): Used for highlights and "Lounges" branding.
*   **Duo Signature Colors**:
    *   **Green** (`#58CC02`): Success, active states, and "Start" actions.
    *   **Red** (`#FF4B4B`): Errors, destructive actions, and alerts.
    *   **Orange** (`#FF9600`): Progress, warnings, and highlighting.
    *   **Yellow** (`#FFD93D`): Stars, trust levels, and premium indicators.

### 2. Typography
We use a dual-font approach to balance brand playfulness with readability:
*   **Poppins (Sans-Serif)**: Used for titles, headers, and primary buttons. Provides a bold, geometric, and modern feel.
*   **Rubik (Sans-Serif)**: Used for body text, subtitles, and input fields. Offers excellent legibility with slightly rounded shapes that complement the icon-heavy design.
*   **Header Casing**: We favor **Sentence Case** or **Title Case** over all-caps for headers and titles. This creates a softer, more approachable, and "youthful" feel that aligns with modern social apps. All-caps is reserved for extremely critical, tactical labels only.

---

## 🏗️ Structural Pattern: Destinations vs. Actions

To maintain consistency while optimizing for usability, we divide all screens into two categories:

### 1. Immersive Destinations
Used for primary hub screens and entry points (e.g., Plaza, Moments feed, Chat list, Lounges hub, Activity feed).
*   **Widget**: `DuoPageScaffold`
*   **Key Features**:
    *   Vibrant gradient header with a large thematic emoji.
    *   Transparent status bar logic (light icons on dark gradients).
    *   The **"Immersive Curve"**: Content sits in a white sheet with large rounded top corners (`DuoRadiusLarge * 1.5`).
    *   Supports `trailingHeader` for settings and `bottomNavigationBar` for primary navigation.

### 2. Focused Utility & Detail Screens
Used for high-throughput activity (e.g., Chat Threads, Moment Details) or information-dense sub-screens (e.g., Resident Profiles, Lounge/Club Profiles, Search/Discovery, Member Lists).
*   **Widget**: Standard `Scaffold` with a lightweight `AppBar`.
*   **Key Features**:
    *   Solid white backgrounds to improve readability and focus.
    *   Standard `AppBar` with **Poppins Bold** titles and optional emojis.
    *   Use of `close_rounded` or `arrow_back` based on navigation depth.
    *   Maximized screen real-estate for messages, stats, or search results.
    *   Custom input/utility layouts (e.g., `DuoChatInputLayout`).

---

## 🧩 Component Library (`lib/widgets/duo/`)

Always prefer these components over standard Material widgets to maintain the brand:

*   **DuoButton**: Heavy 3D-shadow effect, distinct "secondary" and "destructive" variants.
*   **DuoCard**: Consistent shadows and border-radius (`DuoRadiusMedium`).
*   **DuoAvatar**: Integrated mood emojis, trust-score rings, and floor-level badges.
*   **DuoHeader**: Used inside `DuoPageScaffold` to present identity consistently.
*   **DuoStatCard**: Compact, colorful cards for displaying XP, level, and trust metrics.
*   **DuoPageScaffold**: The foundation for all destination screens.
*   **DuoChatInputLayout**: The standardized layout for chat-based interactions, incorporating `DuoChatInput`.
*   **Smart Chat Input**: A specialized input field that automatically handles "Loading" and "Sending" states via its internal logic. It prioritizes stability (keeping the keyboard open) over locking the UI, but prevents multiple submissions.

---

## ✨ Micro-interactions & Celebrations

Talktive should feel alive.
*   **Animations**: Use `flutter_animate` for entrance transitions. Stagger list items slightly.
*   **Haptics**: Always provide `lightImpact` for taps and `medium/heavyImpact` for significant actions (sending messages, joining lounges).
*   **Celebrations**: Use the `ConfettiAnimation` for level-ups or significant achievements.
*   **Satisfying States**: Buttons should visibly "press down" (built into `DuoButton`).
*   **Aesthetic Feedback**: SnackBars (via `SnackBarHelper`) must be **floating**, with rounded corners and consistent padding, ensuring they don't block core navigation while providing satisfying visual reinforcement.

---

## ⚖️ UI Standardization Patterns

To ensure a predictable experience across the diverse "floors" of the building, we follow strict placement rules for common actions:

### 1. Refresh Button Placement
The `DuoRefreshButton` provides manual state synchronization. It must be consistently placed:
*   **Location**: Always the **rightmost** element in a header's primary action group.
*   **Standard Grouping**: `[Functional Icons (Search, Profile, Settings)] [Refresh Button] [Overflow Menu (...)]`.
*   **Rationale**: Placing the utility action (Refresh) at the end of the functional list provides a consistent anchor point across all dynamic screens.

### 2. Search & Discovery
Community discovery is a primary action.
*   **Icon**: `Icons.search` (Outline or Rounded).
*   **Action**: Consistently navigates to `/lounges/search` (which routes to the unified Discovery screen).
*   **Placement**: Positioned as a primary header action, typically preceding the Refresh button.
