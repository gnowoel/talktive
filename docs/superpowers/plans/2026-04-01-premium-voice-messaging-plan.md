# Premium Voice Messaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a high-fidelity, interactive voice messaging system with real-time waveforms, lock-to-record gestures, and proximity-based audio routing.

**Architecture:** Use `record` for audio capturing and `just_audio` for seekable playback. The system ensures cross-platform compatibility by using platform-specific encoders (AAC for mobile, Opus for web) and adaptive interaction models (Hold-to-record for mobile, Tap-to-toggle for web).

**Tech Stack:** `just_audio`, `record`, `audio_session`, `Serverpod`, `Firebase Storage`.

---

### Task 1: Backend Model & Protocol Update

**Files:**

- Modify: `talktive_server/lib/src/models/message.yaml`
- Modify: `talktive_server/lib/src/services/messaging_service.dart`
- Test: `talktive_server/test/integration/messaging_service_test.dart`

- [x] **Step 1: Update the Message model**
      Add `duration` fields to the Message class. (Note: `amplitudes` extraction was deferred to keep the system lightweight).

```yaml
class: Message
table: message
fields:
  ...
  duration: int?
```

- [x] **Step 2: Generate Serverpod code**
      Run: `cd talktive_server && serverpod generate`
      Expected: `protocol.dart` and other generated files are updated.

- [x] **Step 3: Update MessagingService validation**
      Add validation to ensure voice duration is reasonable.

- [x] **Step 4: Update integration tests**
      Add a test case for valid voice message.

- [x] **Step 5: Run tests**
      Run: `cd talktive_server && dart test test/integration/messaging_service_test.dart`
      Expected: All tests PASS.

- [x] **Step 6: Commit**

```bash
git add talktive_server
git commit -m "feat(backend): add duration to Message model and validation"
```

---

### Task 2: Flutter Dependencies & VoiceService Scaffold

**Files:**

- Modify: `talktive_flutter/pubspec.yaml`
- Create: `talktive_flutter/lib/services/voice_service.dart`

- [x] **Step 1: Add dependencies**
      Standardized on `just_audio` and `record`. Removed unused `audioplayers` and `audio_waveforms`.

- [x] **Step 2: Create VoiceService**
      Define a service to manage audio sessions and provide global access to playback states. Fixed web playback by making session activation non-blocking.

- [x] **Step 3: Commit**

```bash
git add talktive_flutter/pubspec.yaml talktive_flutter/lib/services/voice_service.dart
git commit -m "feat(voice): add audio dependencies and VoiceService scaffold"
```

---

### Task 3: Interactive VoiceMessagePlayer

**Files:**

- Modify: `talktive_flutter/lib/widgets/chat/voice_message_player.dart`

- [x] **Step 1: Implement the Seekable Player**
      Rewrite `VoiceMessagePlayer` to use `just_audio` with a linear progress indicator. Explicitly set volume to 1.0.

- [x] **Step 2: Add Proximity Sensor Support**
      Use `audio_session` to handle proximity events and interruptions.

- [x] **Step 3: Commit**

```bash
git add talktive_flutter/lib/widgets/chat/voice_message_player.dart
git commit -m "feat(voice): implement interactive seekable voice player"
```

---

### Task 4: Advanced DuoChatInput (Recording)

**Files:**

- Modify: `talktive_flutter/lib/widgets/duo/duo_chat_input.dart`

- [x] **Step 1: Integrate record package**
      Update `_DuoChatInputState` to use `AudioRecorder`. Optimized for Web using `AudioEncoder.opus` and `.webm` format.

- [x] **Step 2: Implement Interaction Models**
      Added **Tap-to-Toggle** for Web browsers where long-press is unreliable. Maintained **Hold-to-Record** for mobile.

- [x] **Step 3: Implement Visual Animations**
      Pulsing red indicator during active recording.

- [x] **Step 4: Commit**

```bash
git add talktive_flutter/lib/widgets/duo/duo_chat_input.dart
git commit -m "feat(voice): add cross-platform recording gestures and web support"
```

---

### Task 5: Integration & Final Polish

**Files:**

- Modify: `talktive_flutter/lib/widgets/chat/chat_screen_mixin.dart`
- Modify: `talktive_flutter/lib/screens/chats/chat_thread_screen.dart`

- [x] **Step 1: Update ChatScreenMixin**
      Disable input field autofocus after sending media to allow continuous voice messaging.

- [x] **Step 2: Header Alignment**
      Ensure the Refresh button is the rightmost icon before the menu in chat headers.

- [x] **Step 3: Commit**

```bash
git add .
git commit -m "feat(voice): wire up backend and frontend for premium voice messaging"
```
