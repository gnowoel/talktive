# Design Spec: Premium Voice Messaging Experience

## 1. Overview

This specification details the migration of the "Talktive" voice messaging system from a basic, static implementation to a high-energy, "Premium" experience inspired by modern interactive design (e.g., Duolingo).

The goal is to provide reliable cross-platform recording and playback, intuitive gestures, and robust management while maintaining extreme efficiency for the Serverpod backend.

## 2. Architecture & Data Flow

### 2.1 Core Technologies

- **Audio Playback:** `just_audio` (Handles focus management and cross-platform streaming).
- **Audio Recording:** `record` (Standardized for mobile and web support).
- **Audio Session Management:** `audio_session` (Manages system-level audio focus and proximity).
- **Backend:** Serverpod (PostgreSQL storage for message metadata).
- **Storage:** Firebase Storage (Binary file hosting).

### 2.2 Data Schema

Add the following to the `Message` model in `talktive_server/lib/src/models/message.yaml`:

```yaml
class: Message
fields:
  ...
  duration: int?,         # Duration in seconds
```

### 2.3 The Flow

1. **Recording (Client):**
   - **Mobile:** Uses `AudioEncoder.aacLc` with `.m4a` extension. "Hold-to-record" interaction.
   - **Web:** Uses `AudioEncoder.opus` with `.webm` extension. "Tap-to-toggle" interaction (browser compatibility).
   - Local file is uploaded to Firebase Storage with correct content-type (`audio/mp4` or `audio/webm`).
2. **Persistence (Server):**
   - The message is saved via Serverpod, including the `mediaUrl` and `duration`.
3. **Consumption (Client):**
   - The `VoiceMessagePlayer` widget renders a seekable progress bar.
   - `just_audio` streams the audio file from Firebase.

## 3. UI/UX Design

### 3.1 Recording (`DuoChatInput`)

- **Interaction Models:**
  - **Hold-to-Record (Mobile):** Physical-style interaction.
  - **Tap-to-Toggle (Web):** Browser-friendly interaction avoiding long-press blocks.
- **Visual Feedback:** Red pulsing indicator during active recording.
- **Gesture: Slide Left (Cancel):**
  - Horizontally sliding past a threshold (100px) cancels recording.
- **Minimum Duration:** Messages shorter than 1 second are discarded with a feedback tooltip.

### 3.2 Playback (`VoiceMessagePlayer`)

- **Visuals:** Linear progress indicator with high-contrast active states.
- **Audio Session:** Resilient playback that attempts session activation but falls back to direct play on restrictive platforms (like Web).
- **Audio Focus:** Tapping "Play" on a message pauses any other active audio in the app.

## 4. Performance & Reliability

### 4.1 Cross-Platform Robustness

- **Web Fixes:** Enforces Opus encoder and WebM container required by modern browsers.
- **Emulator Support:** Handles potential audio session activation failures gracefully.
- **Memory Safety:** Explicit disposal of audio players and cancellation of stream subscriptions.

### 4.2 Edge Case Handling

- **Missing Microphone:** Debug logs and permission guards prevent silent failures.
- **Web Crashes:** Guards against `dart:io` usage on the web platform.
- **Autofocus Logic:** Prevents the virtual keyboard from popping up after media messages to allow rapid-fire voice messaging.
