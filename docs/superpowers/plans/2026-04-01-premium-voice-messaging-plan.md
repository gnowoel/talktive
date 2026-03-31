# Premium Voice Messaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a high-fidelity, interactive voice messaging system with real-time waveforms, lock-to-record gestures, and proximity-based audio routing.

**Architecture:** Use `audio_waveforms` for real-time amplitude extraction and visualization during recording, and `just_audio` for seekable playback. Waveform data (amplitudes) is stored as a JSON list in the Serverpod database to allow instant rendering for recipients.

**Tech Stack:** `just_audio`, `audio_waveforms`, `audio_session`, `Serverpod`, `Firebase Storage`.

---

### Task 1: Backend Model & Protocol Update

**Files:**
- Modify: `talktive_server/lib/src/models/message.yaml`
- Modify: `talktive_server/lib/src/services/messaging_service.dart`
- Test: `talktive_server/test/integration/messaging_service_test.dart`

- [ ] **Step 1: Update the Message model**
Add `amplitudes` and `duration` fields to the Message class.
```yaml
class: Message
table: message
fields:
  ...
  amplitudes: List<int>?
  duration: int?
```

- [ ] **Step 2: Generate Serverpod code**
Run: `cd talktive_server && serverpod generate`
Expected: `protocol.dart` and other generated files are updated.

- [ ] **Step 3: Update MessagingService validation**
Add validation to ensure `amplitudes` is not excessively large.
```dart
// talktive_server/lib/src/services/messaging_service.dart
if (mediaType == 'voice' && amplitudes != null && amplitudes.length > 100) {
  throw protocol.TalktiveException(
    message: 'Invalid waveform data.',
    code: 'INVALID_INPUT',
  );
}
```

- [ ] **Step 4: Update integration tests**
Add a test case for valid voice message with amplitudes.
```dart
// talktive_server/test/integration/messaging_service_test.dart
test('allows voice message with valid amplitudes', () async {
  final session = sessionBuilder.build();
  testUser.isPremium = true;
  await protocol.Resident.db.updateRow(session, testUser);

  final result = await MessagingService.validateMessage(
    session,
    sender: testUser,
    channel: plazaChannel,
    mediaType: 'voice',
    mediaUrl: 'https://example.com/voice.m4a',
    duration: 5,
    fileSize: 1024,
    amplitudes: List.generate(50, (i) => i),
  );

  expect(result, isNull);
});
```

- [ ] **Step 5: Run tests**
Run: `cd talktive_server && dart test test/integration/messaging_service_test.dart`
Expected: All tests PASS.

- [ ] **Step 6: Commit**
```bash
git add talktive_server
git commit -m "feat(backend): add amplitudes to Message model and validation"
```

---

### Task 2: Flutter Dependencies & VoiceService Scaffold

**Files:**
- Modify: `talktive_flutter/pubspec.yaml`
- Create: `talktive_flutter/lib/services/voice_service.dart`

- [ ] **Step 1: Add dependencies**
Run: `cd talktive_flutter && flutter pub add just_audio audio_waveforms audio_session`
Expected: `pubspec.yaml` is updated.

- [ ] **Step 2: Create VoiceService**
Define a service to manage audio sessions and provide global access to playback states.
```dart
// talktive_flutter/lib/services/voice_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';

class VoiceService {
  final Ref ref;
  VoiceService(this.ref);

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }
}

final voiceServiceProvider = Provider((ref) => VoiceService(ref));
```

- [ ] **Step 3: Commit**
```bash
git add talktive_flutter/pubspec.yaml talktive_flutter/lib/services/voice_service.dart
git commit -m "feat(voice): add audio dependencies and VoiceService scaffold"
```

---

### Task 3: Interactive VoiceMessagePlayer

**Files:**
- Modify: `talktive_flutter/lib/widgets/chat/voice_message_player.dart`

- [ ] **Step 1: Implement the Seekable Waveform Player**
Rewrite `VoiceMessagePlayer` to use `just_audio` and manual waveform rendering from `amplitudes`.
```dart
// talktive_flutter/lib/widgets/chat/voice_message_player.dart
// ... imports including just_audio
class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final List<int> amplitudes;
  final bool isCurrentUser;
  // ...
}
// Implement _VoiceMessagePlayerState with AudioPlayer and seek logic
```

- [ ] **Step 2: Add Proximity Sensor Support**
Use `audio_session` to handle proximity events.
```dart
// In _VoiceMessagePlayerState
_session.becomingNoisyEventStream.listen((_) => _player.pause());
```

- [ ] **Step 3: Commit**
```bash
git add talktive_flutter/lib/widgets/chat/voice_message_player.dart
git commit -m "feat(voice): implement interactive seekable waveform player"
```

---

### Task 4: Advanced DuoChatInput (Recording)

**Files:**
- Modify: `talktive_flutter/lib/widgets/duo/duo_chat_input.dart`

- [ ] **Step 1: Integrate audio_waveforms Recorder**
Update `_DuoChatInputState` to use `RecorderController`.
```dart
// talktive_flutter/lib/widgets/duo/duo_chat_input.dart
final recorderController = RecorderController();
// ... config and start recording
```

- [ ] **Step 2: Implement "Lock to Record" Gesture**
Add vertical drag detection to lock the recording state.
```dart
// In _onDragUpdate
if (details.delta.dy < -50) _lockRecording();
```

- [ ] **Step 3: Implement Visual Pulse Animation**
Add an animation that scales based on `recorderController.onCurrentAmplitude`.

- [ ] **Step 4: Commit**
```bash
git add talktive_flutter/lib/widgets/duo/duo_chat_input.dart
git commit -m "feat(voice): add advanced recording gestures and pulse animations"
```

---

### Task 5: Integration & Final Polish

**Files:**
- Modify: `talktive_flutter/lib/widgets/chat/chat_screen_mixin.dart`
- Modify: `talktive_flutter/lib/widgets/chat/message_bubble.dart`

- [ ] **Step 1: Update ChatScreenMixin**
Capture and send amplitudes from the recorder.
```dart
// talktive_flutter/lib/widgets/chat/chat_screen_mixin.dart
Future<void> sendVoiceMessage(String path, int durationSeconds, List<int> amplitudes) async {
  // ... upload and send message with amplitudes
}
```

- [ ] **Step 2: Update MessageBubble**
Pass `message.amplitudes` to `VoiceMessagePlayer`.

- [ ] **Step 3: Final Verification**
Run full app and verify:
1. Hold to record (pulsing mic).
2. Slide left to cancel (trash icon).
3. Slide up to lock.
4. Player shows real waveform.
5. Tapping waveform seeks.
6. Proximity sensor works (if testing on real device).

- [ ] **Step 4: Commit**
```bash
git add .
git commit -m "feat(voice): wire up backend and frontend for premium voice messaging"
```
