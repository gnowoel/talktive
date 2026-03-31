# Design Spec: Premium Voice Messaging Experience

## 1. Overview
This specification details the migration of the "Talktive" voice messaging system from a basic, static implementation to a high-energy, "Premium" experience inspired by modern interactive design (e.g., Duolingo). 

The goal is to provide real-time audio visualization, intuitive recording gestures, and robust playback management while maintaining extreme efficiency for the Serverpod backend (10K+ users on 2 vCPUs).

## 2. Architecture & Data Flow

### 2.1 Core Technologies
- **Audio Playback:** `just_audio` (Replaces `audioplayers` for better focus management and earpiece switching).
- **Audio Recording & Visualization:** `audio_waveforms` (Handles real-time amplitude extraction).
- **Audio Session Management:** `audio_session` (Manages system-level audio focus).
- **Backend:** Serverpod (PostgreSQL with JSONB for amplitude storage).
- **Storage:** Firebase Storage (Retained for binary file hosting).

### 2.2 Data Schema
Add the following to the `Message` model in `talktive_server/lib/src/models/message.yaml`:
```yaml
class: Message
fields:
  ...
  amplitudes: List<int>?, # Normalized amplitude data (0-100)
  duration: int?,         # Duration in seconds
```

### 2.3 The Flow
1. **Recording (Client):** 
   - `audio_waveforms` captures the mic and extracts a stream of amplitudes.
   - Upon completion, the list is normalized to exactly 50 integers (0-100).
   - The `.m4a` file is uploaded to Firebase Storage.
2. **Persistence (Server):**
   - The message is saved via Serverpod, including the `amplitudes` list and `duration`.
   - `MessagingService` validates that `amplitudes.length <= 100` to prevent DB bloat.
3. **Consumption (Client):**
   - The `VoiceMessagePlayer` widget renders the waveform **instantly** using the provided `amplitudes` list.
   - `just_audio` streams the audio file from Firebase.

## 3. UI/UX Design

### 3.1 Recording (`DuoChatInput`)
- **Visual Pulse:** The mic button pulses (scale + shadow glow) based on real-time amplitude data.
- **Gesture: Slide Up (Lock):**
  - Vertically sliding transitions the recording to a "Hands-Free" state.
  - UI displays a "Locked" status with separate Send/Delete buttons.
- **Gesture: Slide Left (Cancel):**
  - Horizontally sliding past a threshold (80px) reveals a "Trash Can" animation.
  - Releasing deletes the local file and cancels the upload.
- **Minimum Duration:** Messages shorter than 1 second trigger a "Hold to record" tooltip and are discarded.

### 3.2 Playback (`VoiceMessagePlayer`)
- **Interactive Waveform:**
  - Real audio profile visualization.
  - Color-filled progress overlay during playback.
  - **Tappable Seek:** Users can tap the waveform to jump to a specific timestamp.
- **Proximity Sensor:** Automatic switch to earpiece when the device is held to the ear (Privacy Mode).
- **Audio Focus:** Tapping "Play" on a message pauses any other active audio in the app or system.

## 4. Performance & Reliability

### 4.1 Scalability (The 10K Target)
- **Zero Backend Processing:** No audio manipulation happens on the VPS. All normalization and extraction are client-side.
- **DB Optimization:** JSONB column storage for amplitudes is compact and indexed naturally in PostgreSQL.
- **UI Performance:** Use `RepaintBoundary` on each waveform widget to prevent parent list rebuilds from triggering expensive re-paints.

### 4.2 Edge Case Handling
- **Interruptions:** Automatic "Save & Stop" on incoming calls or app backgrounding.
- **Permission Denied:** Clean fallback UI with a snackbar directing the user to system settings.
- **Network Failure:** Retry logic for uploads with local file cleanup on definitive failure.

## 5. Implementation Phases
1. **Phase 1 (Backend):** Update models, generate Serverpod code, and update `MessagingService` validation.
2. **Phase 2 (Core Services):** Implement `just_audio` service and integrate `audio_waveforms` recorder.
3. **Phase 3 (UI - Player):** Build the interactive seekable waveform player.
4. **Phase 4 (UI - Recorder):** Build the advanced `DuoChatInput` with gestures and pulse animations.
5. **Phase 5 (Refinement):** Add proximity sensor support and audio focus logic.
