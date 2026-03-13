# Talktive Design System

## 🏛️ Core Philosophy: The Apartment Building Metaphor

Talktive is not just a chat app; it is a digital residence. This metaphor guides every UI decision:

*   **Plaza (Lobby)**: Public, bustling, and open. High activity.
*   **Moments (Bulletin Board)**: Visual, community-driven, and shared.
*   **Chats (Private Units)**: Intimate, secure, and personal.
*   **Lounges (Clubhouse)**: Interest-based, community-led, and moderated. Also referred to as "Clubs".
*   **Profile (My Unit)**: Your personal identity and sanctuary.

---

## 🎨 Visual Identity: Duolingo-Inspired UX

We embrace a playful, high-energy aesthetic that makes interaction feel like a game rather than a chore.

### 1. Color Palette
*   **Primary Purple** (`#6C63FF`): The core brand color, used for primary actions and branding.
*   **Secondary Pink** (`#FF6584`): Used for accents and "Moments" branding.
*   **Accent Cyan** (`#00D9FF`): Used for highlights and "Groups" branding.
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
Used for "Places" and "Entities" (e.g., Profiles, Search Pages, Member Lists).
*   **Widget**: `DuoPageScaffold`
*   **Key Features**:
    *   Vibrant gradient header with a large thematic emoji.
    *   Transparent white status bar logic.
    *   The **"Immersive Curve"**: Content sits in a white sheet with large rounded top corners (`DuoRadiusLarge * 1.5`).
    *   Supports `trailingHeader` for settings/actions and `bottomNavigationBar` for status-based controls (like invite bars).

### 2. Focused Action Screens
Used for high-throughput activity where content is king (e.g., Chat Threads, Moment Details).
*   **Widget**: Standard `Scaffold` with custom `AppBar`.
*   **Key Features**:
    *   Solid white backgrounds to minimize distraction.
    *   Standard `AppBar` with **Poppins Bold** titles for brand consistency.
    *   Maximized screen real-estate for messages or media.
    *   Custom input layouts (e.g., `DuoChatInputLayout`).

---

## 🧩 Component Library (`lib/widgets/duo/`)

Always prefer these components over standard Material widgets to maintain the brand:

*   **DuoButton**: Heavy 3D-shadow effect, distinct "secondary" and "destructive" variants.
*   **DuoCard**: Consistent shadows and border-radius (`DuoRadiusMedium`).
*   **DuoAvatar**: Integrated mood emojis, trust-score rings, and floor-level badges.
*   **DuoHeader**: Used inside `DuoPageScaffold` to present identity consistently.
*   **DuoStatCard**: Compact, colorful cards for displaying XP, level, and trust metrics.
*   **DuoPageScaffold**: The foundation for all destination screens.

---

## ✨ Micro-interactions & Celebrations

Talktive should feel alive.
*   **Animations**: Use `flutter_animate` for entrance transitions. Stagger list items slightly.
*   **Haptics**: Always provide `lightImpact` for taps and `medium/heavyImpact` for significant actions (sending messages, joining groups).
*   **Celebrations**: Use the `ConfettiAnimation` for level-ups or significant achievements.
*   **Satisfying States**: Buttons should visibly "press down" (built into `DuoButton`).
*   **Aesthetic Feedback**: SnackBars (via `SnackBarHelper`) must be **floating**, with rounded corners and consistent padding, ensuring they don't block core navigation while providing satisfying visual reinforcement.
