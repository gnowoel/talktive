import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class VoiceService {
  final Ref ref;
  VoiceService(this.ref);

  static AudioPlayer? _activePlayer;
  static AudioSession? _session;

  static Future<void> init() async {
    _session = await AudioSession.instance;
    await _session!.configure(const AudioSessionConfiguration.speech());

    // Listen for proximity sensor changes
    _session!.becomingNoisyEventStream.listen((_) {
      _activePlayer?.pause();
    });

    // Handle interruptions (calls, etc.)
    _session!.interruptionEventStream.listen((event) {
      if (event.begin) {
        _activePlayer?.pause();
      }
    });
  }

  Future<void> play(AudioPlayer player) async {
    if (_activePlayer != null && _activePlayer != player) {
      await _activePlayer!.pause();
    }
    _activePlayer = player;

    try {
      if (_session != null) {
        await _session!.setActive(true);
      }
    } catch (e) {
      debugPrint('VoiceService: Failed to set audio session active: $e');
    }

    await player.play();
  }

  void onPlayerPaused(AudioPlayer player) {
    if (_activePlayer == player) {}
  }

  void onPlayerStopped(AudioPlayer player) {
    if (_activePlayer == player) {
      _activePlayer = null;
      _session?.setActive(false);
    }
  }
}

final voiceServiceProvider = Provider((ref) => VoiceService(ref));
