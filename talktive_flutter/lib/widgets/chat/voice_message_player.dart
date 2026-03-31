import 'dart:math';
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
  final List<int>? amplitudes;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.isCurrentUser,
    this.amplitudes,
  });

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late final List<double> _normalizedAmplitudes;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _normalizedAmplitudes = _normalizeAmplitudes(widget.amplitudes);

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(UrlHelper.resolve(widget.url));
      
      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _position = _duration;
              _player.seek(Duration.zero);
              _player.pause();
              ref.read(voiceServiceProvider).onPlayerStopped(_player);
            }
          });
        }
      });

      _player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });

      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    ref.read(voiceServiceProvider).onPlayerStopped(_player);
    _player.dispose();
    super.dispose();
  }

  List<double> _normalizeAmplitudes(List<int>? amplitudes) {
    if (amplitudes == null || amplitudes.isEmpty) {
      // Generate some default bars if no amplitudes provided
      final random = Random(widget.url.hashCode);
      return List.generate(30, (_) => 0.2 + random.nextDouble() * 0.8);
    }
    
    final maxAmp = amplitudes.reduce(max).toDouble();
    if (maxAmp == 0) return List.filled(amplitudes.length, 0.1);
    
    return amplitudes.map((amp) => (amp / maxAmp).clamp(0.1, 1.0)).toList();
  }

  Future<void> _togglePlay() async {
    final voiceService = ref.read(voiceServiceProvider);
    if (_isPlaying) {
      await _player.pause();
      voiceService.onPlayerPaused(_player);
    } else {
      await voiceService.play(_player);
    }
  }

  void _seek(double percent) {
    if (_duration == Duration.zero) return;
    final seekPos = _duration * percent;
    _player.seek(seekPos);
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

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: AnimatedContainer(
                duration: 200.ms,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                  color: widget.isCurrentUser ? AppTheme.primaryColor : Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final box = context.findRenderObject() as RenderBox;
                      final localOffset = box.globalToLocal(details.globalPosition);
                      // Adjust for the play button and spacing (40 + 12 = 52)
                      final waveformX = localOffset.dx - 52;
                      final waveformWidth = box.size.width - 52;
                      if (waveformX >= 0 && waveformX <= waveformWidth) {
                        _seek(waveformX / waveformWidth);
                      }
                    },
                    onTapDown: (details) {
                      final box = context.findRenderObject() as RenderBox;
                      final localOffset = box.globalToLocal(details.globalPosition);
                      final waveformX = localOffset.dx - 52;
                      final waveformWidth = box.size.width - 52;
                      if (waveformX >= 0 && waveformX <= waveformWidth) {
                        _seek(waveformX / waveformWidth);
                      }
                    },
                    child: SizedBox(
                      height: 32,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: WaveformPainter(
                          amplitudes: _normalizedAmplitudes,
                          progress: progress,
                          activeColor: themeColor,
                          inactiveColor: inactiveColor,
                          isPlaying: _isPlaying,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 10,
                          color: labelColor,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 10,
                          color: labelColor,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
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
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isPlaying;

  WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final barWidth = 2.5;
    final spacing = 3.5;
    final totalBarWidth = barWidth + spacing;
    
    // We want to draw bars across the entire width
    final maxBars = (size.width / totalBarWidth).floor();
    final actualAmplitudes = _getSampledAmplitudes(amplitudes, maxBars);
    
    for (int i = 0; i < actualAmplitudes.length; i++) {
      final barHeight = actualAmplitudes[i] * size.height;
      final x = i * totalBarWidth + barWidth / 2;
      
      final barProgress = i / actualAmplitudes.length;
      final isActive = barProgress <= progress;
      
      paint.color = isActive ? activeColor : inactiveColor;
      
      final yOffset = (size.height - barHeight) / 2;
      
      canvas.drawLine(
        Offset(x, yOffset),
        Offset(x, yOffset + barHeight),
        paint,
      );
    }
  }

  List<double> _getSampledAmplitudes(List<double> data, int count) {
    if (data.length == count) return data;
    if (data.isEmpty) return List.filled(count, 0.1);

    final result = <double>[];
    final step = data.length / count;
    
    for (int i = 0; i < count; i++) {
      final index = (i * step).floor();
      result.add(data[index]);
    }
    
    return result;
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.isPlaying != isPlaying ||
           oldDelegate.amplitudes != amplitudes;
  }
}
