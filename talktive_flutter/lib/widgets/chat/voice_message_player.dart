import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
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
  late final List<double> _waveformHeights;
  static const int _barCount = 25;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveformHeights = _generateWaveform(widget.url, _barCount);

    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              audioFocus: AndroidAudioFocus.gain,
              contentType: AndroidContentType.speech,
              usageType: AndroidUsageType.media,
              audioMode: AndroidAudioMode.normal,
            ),
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        _player.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      }
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

  List<double> _generateWaveform(String seed, int count) {
    final random = Random(seed.hashCode);
    return List.generate(count, (_) => 0.2 + random.nextDouble() * 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCurrentUser
        ? Colors.white
        : AppTheme.primaryColor;
    final secondaryColor = widget.isCurrentUser
        ? Colors.white.withValues(alpha: 0.3)
        : AppTheme.primaryColor.withValues(alpha: 0.1);
    final labelColor = widget.isCurrentUser
        ? Colors.white.withValues(alpha: 0.8)
        : AppTheme.textLight;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 220.0;
        final waveformWidth = (maxWidth - 48).clamp(120.0, 220.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: waveformWidth + 48,
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
                      _playerState == PlayerState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: widget.isCurrentUser
                          ? AppTheme.primaryColor
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: waveformWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: waveformWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_barCount, (index) {
                            final barProgress = index / _barCount;
                            final isBarActive = progress >= barProgress;
                            final isPlaying =
                                _playerState == PlayerState.playing;

                            var bar = Container(
                              width: 3,
                              height: 24 * _waveformHeights[index],
                              decoration: BoxDecoration(
                                color: isBarActive
                                    ? themeColor
                                    : secondaryColor,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            );

                            if (isPlaying && isBarActive) {
                              return Flexible(
                                child: bar
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .scaleY(
                                      begin: 0.8,
                                      end: 1.2,
                                      duration: 400.ms + (index * 20).ms,
                                    )
                                    .shimmer(
                                      duration: 2.seconds,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                              );
                            }

                            return Flexible(child: bar);
                          }),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 10,
                              color: labelColor,
                              fontFamily: 'Rubik',
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 10,
                              color: labelColor,
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
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
