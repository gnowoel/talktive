import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../config/theme.dart';
import '../../helpers/url_helper.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final bool isCurrentUser;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.isCurrentUser,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    
    // Set audio context to ensures it plays through the speaker
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isRestricted_9_0: true,
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioMode: AndroidAudioMode.normal,
        ),
        iOS: const AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          ],
        ),
      ));
    }
    
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
        });
      }
    });

    _player.onLog.listen((log) => debugPrint('AudioPlayer Log: $log'));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(UrlHelper.resolve(widget.url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCurrentUser ? Colors.white : AppTheme.primaryColor;
    final secondaryColor = widget.isCurrentUser 
        ? Colors.white.withValues(alpha: 0.3) 
        : AppTheme.primaryColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                color: widget.isCurrentUser ? AppTheme.primaryColor : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _duration.inMilliseconds > 0 
                          ? _position.inMilliseconds / _duration.inMilliseconds 
                          : 0.0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isCurrentUser ? Colors.white.withValues(alpha: 0.8) : AppTheme.textLight,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isCurrentUser ? Colors.white.withValues(alpha: 0.8) : AppTheme.textLight,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
