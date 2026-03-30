# Talktive Design System

## 🏛️ Core Philosophy: The Apartment Building Metaphor

Talktive is not just a chat app; it is a digital residence. This metaphor guides every UI decision:

- **Plaza (Lobby)**: Public, bustling, and open. The building's social heart.
- **Moments (Bulletin Board)**: Visual, community-driven, and shared.
- **Chats (Private Units)**: Intimate, secure, and personal.
- **Lounges (Clubhouse)**: The primary term for interest-based communities. They feel like relaxed shared spaces where residents hang out.
- **Profile (My Unit)**: Your personal identity and sanctuary.

These structural elements are unified by an **inviting, friendly tone**—using soft typography, warm emojis, and community-centric language to make the building feel like home.

---

## 🎭 Live & Transparent Discovery

Talktive is a "Live Residence." To ensure the building feels vibrant and provides maximum value to our community, we follow a **"Live First"** philosophy:

- **Always Visible**: Outbound privacy toggles (hiding your own status) have been removed. Every resident contributes to the "Live" feel of the building.
- **Universal Discovery**: All residents are searchable by default. This encourages spontaneous encounters in the Plaza and Lounges.
- **Inbound Premium Controls**: While visibility is universal, **Talktive Plus** members have the exclusive ability to control their _own_ view of the building (e.g., toggling their visibility of others' online status, read receipts, and typing indicators).
- **The Global Lobby**: New residents are always guided back to the **Plaza** and the **Global Lounge**—the digital "front door" where the community meets.

### Tiered Content Ephemerality

To ensure the building remains fresh and private, we follow a strict tiered ephemerality policy:

- **Plaza (Public)**: 24-hour lifespan to keep the social heart energetic.
- **Lounges (Clubhouse)**: 14-day lifespan for interest-based hangouts.
- **Private Chats (Units)**: 30-day lifespan for personal security.
- **Moments (Bulletin Board)**: 7-day lifespan for ephemeral snapshots.

---

### Tiered Content Ephemerality

To ensure the building remains fresh and private, we follow a strict tiered ephemerality policy:

- **Plaza (Public)**: 24-hour lifespan to keep the social heart energetic.
- **Lounges (Clubhouse)**: 14-day lifespan for interest-based hangouts.
- **Private Chats (Units)**: 30-day lifespan for personal security.
- **Moments (Bulletin Board)**: 7-day lifespan for ephemeral snapshots.

---

## 🎨 Visual Identity: Duolingo-Inspired UX

We embrace a playful, high-energy aesthetic that makes interaction feel like a game rather than a chore.

### 1. Color Palette

- **Primary Purple** (`#6C63FF`): The core brand color, used for primary actions and branding.
- **Secondary Pink** (`#FF6584`): Used for accents and "Moments" branding.
- **Accent Cyan** (`#00D9FF`): Used for highlights and "Lounges" branding.
- **Duo Signature Colors**:
  - **Green** (`#58CC02`): Success, active states, and "Start" actions.
  - **Red** (`#FF4B4B`): Errors, destructive actions, and alerts.
  - **Orange** (`#FF9600`): Progress, warnings, and highlighting.
  - **Yellow** (`#FFD93D`): Stars, trust levels, and premium indicators.

### 2. Typography

We use a dual-font approach to balance brand playfulness with readability:

- **Poppins (Sans-Serif)**: Used for titles, headers, and primary buttons. Provides a bold, geometric, and modern feel.
- **Rubik (Sans-Serif)**: Used for body text, subtitles, and input fields. Offers excellent legibility with slightly rounded shapes that complement the icon-heavy design.
- **Header Casing**: We favor **Sentence Case** or **Title Case** over all-caps for headers and titles. This creates a softer, more approachable, and "youthful" feel that aligns with modern social apps. All-caps is reserved for extremely critical, tactical labels only.

---

## 🧭 Navigation Architecture: Persistent Tabs

Talktive uses a **Stateful Navigation** model to ensure that the resident's journey through the building feels seamless and persistent:

- **StatefulShellRoute**: Each of the five main tabs (Plaza, Moments, Chats, Lounges, Activity) is implemented as a separate navigation branch.
- **Persistent State**: This architecture ensures that scroll positions, input field text, and nested navigation states (e.g., being halfway through a chat thread) are preserved when switching between tabs.
- **Deep Linking**: All notification-driven actions (push/in-app) are mapped to absolute paths (e.g., `/my-profile`, `/chats/thread/:id`) to ensure consistent entry points regardless of the current tab.

---

## 🏗️ Structural Pattern: Destinations vs. Actions

To maintain consistency while optimizing for usability, we divide all screens into two categories:

### 1. Immersive Destinations

Used for primary hub screens and entry points (e.g., Plaza, Moments feed, Chat list, Lounges hub, Activity feed).

- **Widget**: `DuoPageScaffold`
- **Key Features**:
  - Vibrant gradient header with a large thematic emoji.
  - Transparent status bar logic (light icons on dark gradients).
  - The **"Immersive Curve"**: Content sits in a white sheet with large rounded top corners (`DuoRadiusLarge * 1.5`).
  - Supports `trailingHeader` for settings and `bottomNavigationBar` for primary navigation.

### 2. Focused Utility & Detail Screens

Used for high-throughput activity (e.g., Chat Threads, Moment Details) or information-dense sub-screens (e.g., Resident Profiles, Lounge/Club Profiles, Search/Discovery, Member Lists).

- **Widget**: Standard `Scaffold` with a lightweight `AppBar`.
- **Key Features**:
  - Solid white backgrounds to improve readability and focus.
  - Standard `AppBar` with **Poppins Bold** titles and optional emojis.
  - Use of `close_rounded` or `arrow_back` based on navigation depth.
  - Maximized screen real-estate for messages, stats, or search results.
  - Custom input/utility layouts (e.g., `DuoChatInputLayout`).

---

## 🧩 Component Library (`lib/widgets/duo/`)

Always prefer these components over standard Material widgets to maintain the brand:

- **DuoButton**: Heavy 3D-shadow effect, distinct "secondary" and "destructive" variants.
- **DuoCard**: Consistent shadows and border-radius (`DuoRadiusMedium`).
- **DuoAvatar**: Integrated mood emojis, trust-score rings, and floor-level badges.
- **DuoHeader**: Used inside `DuoPageScaffold` to present identity consistently.
- **DuoStatCard**: Compact, colorful cards for displaying XP, level, and trust metrics.
- **DuoPageScaffold**: The foundation for all destination screens.
- **DuoChatInputLayout**: The standardized layout for chat-based interactions, incorporating `DuoChatInput`.
- **Smart Chat Input**: A specialized input field that automatically handles "Loading" and "Sending" states via its internal logic. It prioritizes stability (keeping the keyboard open) over locking the UI, but prevents multiple submissions.

---

## ✨ Micro-interactions & Celebrations

Talktive should feel alive.

- **Animations**: Use `flutter_animate` for entrance transitions. Stagger list items slightly.
- **Haptics**: Always provide `lightImpact` for taps and `medium/heavyImpact` for significant actions (sending messages, joining lounges).
- **Celebrations**: Use the `ConfettiAnimation` for level-ups or significant achievements.
- **Satisfying States**: Buttons should visibly "press down" (built into `DuoButton`).
- **Aesthetic Feedback**: SnackBars (via `SnackBarHelper`) must be **floating**, with rounded corners and consistent padding, ensuring they don't block core navigation while providing satisfying visual reinforcement.

---

## ⚡ Background Performance & Efficiency

To provide an "Instant-In" experience without overwhelming our 2 vCPU infrastructure, we use an intelligent, background pre-warming system:

### 1. Intelligent Foreground Pre-warmer

The `TalktivePrewarmer` sits in the app Shell and proactively "warms up" the top 2 most active private threads.

- **Delayed Activation**: Pre-warming only activates 10 seconds after the app is mounted. This avoids initial server spikes and prioritizes the current active screen.
- **Head-only Synchronization**: The system checks the `lastMessageAt` timestamp from the local cache against the server list. If they match, it skips the expensive message history fetch.
- **WebSocket Continuity**: While history fetching is skipped if fresh, the WebSocket subscription is still established. This ensures that when the user enters the chat, it is already "live" and receiving real-time events.
- **Resource Capping**: We limit pre-warming to the **top 2** private chats to balance UX fluidity with server load, supporting 10,000+ concurrent users on modest hardware.

---

## ⚖️ UI Standardization Patterns

To ensure a predictable experience across the diverse "floors" of the building, we follow strict placement rules for common actions:

### 1. Refresh Button Placement

The `DuoRefreshButton` provides manual state synchronization. It must be consistently placed:

- **Location**: Always the **rightmost** element in a header's primary action group.
- **Standard Grouping**: `[Functional Icons (Search, Profile, Settings)] [Refresh Button] [Overflow Menu (...)]`.
- **Rationale**: Placing the utility action (Refresh) at the end of the functional list provides a consistent anchor point across all dynamic screens.

### 2. Search & Discovery

Community discovery is a primary action.

- **Icon**: `Icons.search` (Outline or Rounded).
- **Action**: Consistently navigates to `/discovery/lounges` or `/discovery/people`.
- **Placement**: Positioned as a primary header action, typically preceding the Refresh button.

### 3. Discovery-First & Filter Integration

Discovery is active from the moment you open a search screen, encouraging exploration without typing.

- **Initial Feed**: Search screens provide a dynamic, filtered feed of active neighbors or popular lounges even before a search term is entered.
- **Filter-First Interaction**: Selected filters (Gender, Interest, Language, etc.) immediately refine the discovery feed, allowing for zero-typing discovery.
- **Unified Criteria**: All filtering is additive (`default + options + terms`), ensuring search terms further narrow down the already filtered discovery feed.

---

## 💎 Premium Strategy: "Benefit Visibility" UX

Talktive follows a "Benefit Visibility" philosophy to ensure residents understand the value of Talktive Plus while maintaining a premium, non-intrusive experience:

- **Showcase, Don't Nag**: Premium benefits are listed in the **Activity > Settings** screen for all users. This allows residents to see the value proposition of Talktive Plus without being constantly interrupted by upgrade prompts during their core experience.
- **Visual Gating**:
  - **Settings**: For non-premium users, the "Premium Features" section displays descriptions and icons for each Plus benefit, but the toggle switches are locked and grayed out.
  - **Voice Messages**: The microphone action is hidden from the chat UI for free users, keeping the interface clean.
  - **Resident Discovery**: While Lounge Discovery is open to all, searching for specific neighbors (Resident Search) is a dedicated Plus feature.
- **Feature Reordering**: Premium features are ordered by their impact on identity and utility:
  1. **Custom Avatar** (🖼️)
  2. **Voice Messages** (🎙️)
  3. **Neighbors Discovery** (🔍)
  4. **Online Indicator** (🟢)
  5. **Read Receipts** (✔️)
  6. **Typing Indicators** (✍️)
