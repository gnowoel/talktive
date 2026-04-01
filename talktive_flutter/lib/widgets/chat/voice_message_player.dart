import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../helpers/url_helper.dart';
import '../../services/voice_service.dart';

class VoiceMessagePlayer extends ConsumerStatefulWidget {
  final String url;
  final bool isCurrentUser;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.isCurrentUser,
  });

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isInitializing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _stateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _ensureInitialized() async {
    if (_player != null || _isInitializing) return;

    setState(() => _isInitializing = true);
    try {
      final player = AudioPlayer();
      
      _stateSub = player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _position = _duration;
              player.seek(Duration.zero);
              player.pause();
              ref.read(voiceServiceProvider).onPlayerStopped(player);
            }
          });
        }
      });

      _durationSub = player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });

      _posSub = player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      await player.setUrl(UrlHelper.resolve(widget.url));
      _player = player;
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    if (_player != null) {
      ref.read(voiceServiceProvider).onPlayerStopped(_player!);
      _player!.dispose();
    }
    _stateSub?.cancel();
    _durationSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_player == null) {
      await _ensureInitialized();
    }
    
    if (_player == null) return;

    final voiceService = ref.read(voiceServiceProvider);
    if (_isPlaying) {
      await _player!.pause();
      voiceService.onPlayerPaused(_player!);
    } else {
      await voiceService.play(_player!);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isCurrentUser ? Colors.white : AppTheme.primaryColor;
    final inactiveColor = widget.isCurrentUser 
        ? Colors.white.withValues(alpha: 0.3) 
        : AppTheme.primaryColor.withValues(alpha: 0.15);
    final labelColor = widget.isCurrentUser 
        ? Colors.white.withValues(alpha: 0.8) 
        : AppTheme.textLight;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.isCurrentUser 
              ? Colors.white.withValues(alpha: 0.1) 
              : AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isCurrentUser ? Colors.black : themeColor)
                          .withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: _isInitializing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isCurrentUser ? AppTheme.primaryColor : Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: widget.isCurrentUser ? AppTheme.primaryColor : Colors.white,
                          size: 32,
                        ),
                ),
              )
              .animate(target: _isPlaying ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: themeColor,
                      inactiveTrackColor: inactiveColor,
                      thumbColor: themeColor,
                      overlayColor: themeColor.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (value) {
                        if (_player != null && _duration != Duration.zero) {
                          _player!.seek(_duration * value);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 11,
                            color: labelColor,
                            fontFamily: 'Rubik',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: labelColor,
                            fontFamily: 'Rubik',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
