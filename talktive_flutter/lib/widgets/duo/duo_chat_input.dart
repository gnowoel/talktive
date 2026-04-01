import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Duolingo-style chat input with a pill-shaped design and vibrant send button.
class DuoChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String path, int durationSeconds, List<int> amplitudes)?
  onVoiceSend;
  final Future<bool> Function()? onVoiceStart;
  final bool enabled;
  final String hintText;
  final VoidCallback? onImagePick;
  final Widget? prefix;
  final Color? activeColor;
  final FocusNode? focusNode;
  final bool isSending;
  final bool isLoading;
  final Function(bool isTyping)? onTypingStatusChanged;

  const DuoChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoiceSend,
    this.onVoiceStart,
    this.enabled = true,
    this.isSending = false,
    this.isLoading = false,
    this.hintText = 'Type a message...',
    this.onImagePick,
    this.prefix,
    this.activeColor,
    this.focusNode,
    this.onTypingStatusChanged,
  });

  @override
  State<DuoChatInput> createState() => _DuoChatInputState();
}

class _DuoChatInputState extends State<DuoChatInput> {
  late final RecorderController _recorderController;
  bool _isRecording = false;
  DateTime? _recordStartTime;
  Timer? _recordTimer;
  String _recordDuration = '0:00';
  Timer? _typingTimer;
  bool _wasTyping = false;

  // Voice Recording Enhancements
  double _dragDeltaX = 0;
  bool _isCancelling = false;
  double _currentAmplitude = 0.0;
  List<int> _amplitudes = [];

  static const double _cancelThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _recorderController = RecorderController();
    _recorderController.addListener(_onRecorderUpdate);
  }

  void _onRecorderUpdate() {
    if (mounted && _isRecording && _recorderController.waveData.isNotEmpty) {
      setState(() {
        _currentAmplitude = _recorderController.waveData.last;
        // Normalize 0-1 to 0-100 for storage/sending
        _amplitudes.add((_currentAmplitude * 100).toInt().clamp(0, 100));
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recorderController.removeListener(_onRecorderUpdate);
    _recorderController.dispose();
    _recordTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to toggle send/voice button

    // Typing flag logic
    if (widget.onTypingStatusChanged != null) {
      final isNotEmpty = widget.controller.text.trim().isNotEmpty;

      if (isNotEmpty != _wasTyping) {
        _wasTyping = isNotEmpty;
        widget.onTypingStatusChanged!(isNotEmpty);
      }

      // Automatically clear typing status after 3 seconds of inactivity
      _typingTimer?.cancel();
      if (isNotEmpty) {
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && _wasTyping) {
            _wasTyping = false;
            widget.onTypingStatusChanged!(false);
          }
        });
      }
    }
  }

  Future<void> _startRecording() async {
    if (widget.onVoiceStart != null) {
      final canStart = await widget.onVoiceStart!();
      if (!canStart) return;
    }

    try {
      if (await _recorderController.checkPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        _amplitudes = [];

        await _recorderController.record(path: path);

        _recordStartTime = DateTime.now();
        _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (
          timer,
        ) {
          final duration = _recorderController.elapsedDuration;
          if (duration.inSeconds >= 60) {
            _stopRecording();
            return;
          }
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;
          if (mounted) {
            setState(() {
              _recordDuration =
                  '$minutes:${seconds.toString().padLeft(2, '0')}';
            });
          }
        });

        setState(() {
          _isRecording = true;
          _recordDuration = '0:00';
          _dragDeltaX = 0;
          _isCancelling = false;
          _currentAmplitude = 0;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  void _handleDragEnd() {
    _stopRecording();
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    if (!_isRecording) return;

    final actualCancel = cancel || _isCancelling;
    String? path;

    try {
      _recordTimer?.cancel();
      // Add a timeout to prevent hanging on emulators
      path = await _recorderController.stop().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Voice recorder stop timed out');
          return null;
        },
      );

      final durationMs = _recordStartTime != null
          ? DateTime.now().difference(_recordStartTime!).inMilliseconds
          : 0;

      if (!actualCancel && path != null && widget.onVoiceSend != null) {
        if (durationMs < 1000) {
          // Too short!
          HapticFeedback.vibrate();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Hold to record! Voice message too short. 🎙️',
                ),
                backgroundColor: AppTheme.duoRed,
                behavior: SnackBarBehavior.floating,
                duration: 1.seconds,
              ),
            );
          }
          // Clean up
          final file = File(path);
          if (await file.exists()) await file.delete();
        } else {
          widget.onVoiceSend!(path, (durationMs / 1000).ceil(), _amplitudes);
          HapticFeedback.mediumImpact();
        }
      } else if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error in _stopRecording: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _dragDeltaX = 0;
          _isCancelling = false;
          _currentAmplitude = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showVoice =
        widget.controller.text.trim().isEmpty && widget.onVoiceSend != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: AppTheme.duoSpacingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: 300.ms,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isRecording ? _buildRecordingInfo() : _buildInputInfo(),
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            _buildActionButton(showVoice),
          ],
        ),
      ),
    );
  }

  Widget _buildInputInfo() {
    final themeColor = widget.activeColor ?? AppTheme.primaryColor;

    return Row(
      key: const ValueKey('input_info'),
      children: [
        if (widget.prefix != null) ...[
          widget.prefix!,
          const SizedBox(width: AppTheme.duoSpacingSmall),
        ],

        // Image picker button
        if (widget.onImagePick != null) ...[
          GestureDetector(
            onTap: (widget.enabled && !widget.isSending && !widget.isLoading)
                ? widget.onImagePick
                : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                Icons.image,
                size: 20,
                color:
                    (widget.enabled && !widget.isSending && !widget.isLoading)
                    ? themeColor
                    : AppTheme.textLight,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.duoSpacingSmall),
        ],

        // Text input field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusPill),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Rubik',
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _effectiveHintText,
                hintStyle: const TextStyle(
                  color: AppTheme.textLight,
                  fontFamily: 'Rubik',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.duoSpacingMedium,
                  vertical: AppTheme.duoSpacingSmall,
                ),
              ),
              onSubmitted:
                  (widget.enabled && !widget.isSending && !widget.isLoading)
                  ? (_) => _handleSend()
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingInfo() {
    final cancelProgress = (_dragDeltaX / _cancelThreshold).clamp(0.0, 1.0);

    return Row(
      key: const ValueKey('recording_info'),
      children: [
        // Cancel Area
        SizedBox(
          width: 80 + (60 * cancelProgress),
          child: Row(
            children: [
              Icon(
                    _isCancelling ? Icons.delete : Icons.delete_outline,
                    color: _isCancelling ? AppTheme.duoRed : AppTheme.textLight,
                    size: 22 + (10 * cancelProgress),
                  )
                  .animate(target: _isCancelling ? 1 : 0)
                  .shake(hz: 4, curve: Curves.easeInOut)
                  .scale(end: const Offset(1.2, 1.2)),
              if (cancelProgress > 0.1)
                Expanded(
                  child: Text(
                    _isCancelling ? 'Release' : 'Cancel',
                    style: TextStyle(
                      color:
                          _isCancelling ? AppTheme.duoRed : AppTheme.textLight,
                      fontSize: 13,
                      fontWeight:
                          _isCancelling ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'Rubik',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),

        // Waveform & Timer
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.duoRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusPill),
              border: Border.all(color: AppTheme.duoRed.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.duoRed.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.duoRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 12),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 8),
                Text(
                  _recordDuration,
                  style: const TextStyle(
                    color: AppTheme.duoRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AudioWaveforms(
                        size: const Size(double.infinity, 32),
                        recorderController: _recorderController,
                        enableGesture: false,
                        waveStyle: const WaveStyle(
                          waveColor: AppTheme.duoRed,
                          showDurationLabel: false,
                          spacing: 4.0,
                          showBottom: true,
                          extendWaveform: true,
                          showMiddleLine: false,
                        ),
                      ),
                      if (cancelProgress < 0.3)
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '👈 Slide to cancel',
                              style: TextStyle(
                                color: AppTheme.duoRed.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Rubik',
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(
                                  duration: 2.seconds,
                                  color: Colors.white.withValues(alpha: 0.8),
                                )
                                .fadeOut(
                                  delay: 3.seconds,
                                  duration: 500.ms,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool showVoice) {
    final themeColor = widget.activeColor ?? AppTheme.primaryColor;

    return GestureDetector(
      onLongPressStart: (widget.enabled &&
              !widget.isSending &&
              !widget.isLoading &&
              showVoice)
          ? (_) => _startRecording()
          : null,
      onLongPressMoveUpdate: (details) {
        if (!_isRecording) return;
        setState(() {
          // details.offsetFromOrigin.dx is negative when swiping left
          _dragDeltaX = -details.offsetFromOrigin.dx;
          if (_dragDeltaX < 0) _dragDeltaX = 0;

          if (_dragDeltaX > _cancelThreshold && !_isCancelling) {
            _isCancelling = true;
            HapticFeedback.vibrate();
          } else if (_dragDeltaX <= _cancelThreshold && _isCancelling) {
            _isCancelling = false;
          }
        });
      },
      onLongPressEnd: (_) => _handleDragEnd(),
      onLongPressCancel: () => _handleDragEnd(),
      onTap: (widget.enabled &&
              !widget.isSending &&
              !widget.isLoading &&
              !showVoice)
          ? _handleSend
          : null,
      child: Container(
                width: _isRecording ? 56 : 48,
                height: _isRecording ? 56 : 48,
                decoration: BoxDecoration(
                  gradient:
                      (widget.enabled && !widget.isSending && !widget.isLoading)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isRecording
                              ? (_isCancelling
                                    ? [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ]
                                    : [
                                        AppTheme.duoRed,
                                        AppTheme.duoRed.withValues(alpha: 0.8),
                                      ])
                              : [themeColor, themeColor.withValues(alpha: 0.8)],
                        )
                      : null,
                  color:
                      (widget.enabled && !widget.isSending && !widget.isLoading)
                      ? null
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow:
                      (widget.enabled && !widget.isSending && !widget.isLoading)
                      ? [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? (_isCancelling
                                              ? Colors.grey
                                              : AppTheme.duoRed)
                                        : themeColor)
                                    .withValues(
                                      alpha:
                                          0.3 +
                                          (_isRecording
                                              ? (_currentAmplitude * 0.4)
                                              : 0),
                                    ),
                            blurRadius:
                                8 +
                                (_isRecording ? (_currentAmplitude * 12) : 0),
                            spreadRadius: (_isRecording
                                ? (_currentAmplitude * 4)
                                : 0),
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    showVoice
                        ? (_isRecording
                              ? (_isCancelling
                                    ? Icons.delete_outline
                                    : Icons.mic)
                              : Icons.mic)
                        : Icons.send,
                    color: Colors.white,
                    size: _isRecording ? 28 : 24,
                  ),
                ),
              )
              .animate(target: _isRecording ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: Offset(
                  1.1 + (_currentAmplitude * 0.2),
                  1.1 + (_currentAmplitude * 0.2),
                ),
                duration: 200.ms,
                curve: Curves.easeInOut,
              ),
    );
  }

  String get _effectiveHintText {
    if (widget.isLoading) return 'Loading profile...';
    if (widget.isSending) return 'Sending...';
    return widget.hintText;
  }

  void _handleSend() {
    if (widget.isSending ||
        widget.isLoading ||
        widget.controller.text.trim().isEmpty) {
      return;
    }
    HapticFeedback.lightImpact();
    widget.onSend();
  }
}
