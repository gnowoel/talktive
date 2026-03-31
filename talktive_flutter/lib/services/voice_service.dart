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
