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
  double _dragDeltaY = 0;
  bool _isCancelling = false;
  bool _isLocked = false;
  double _currentAmplitude = 0.0;
  List<int> _amplitudes = [];

  static const double _cancelThreshold = 80.0;
  static const double _lockThreshold = -60.0; // Negative for upward drag

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
          _isLocked = false;
          _recordDuration = '0:00';
          _dragDeltaX = 0;
          _dragDeltaY = 0;
          _isCancelling = false;
          _currentAmplitude = 0;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isRecording || _isLocked) return;

    setState(() {
      _dragDeltaX -= details.delta.dx; // Track left swipe
      _dragDeltaY += details.delta.dy; // Track up swipe (negative delta)

      if (_dragDeltaX < 0) _dragDeltaX = 0;

      // Cancel detection (Slide Left)
      if (_dragDeltaX > _cancelThreshold && !_isCancelling) {
        _isCancelling = true;
        HapticFeedback.vibrate();
      } else if (_dragDeltaX <= _cancelThreshold && _isCancelling) {
        _isCancelling = false;
      }

      // Lock detection (Slide Up)
      if (_dragDeltaY < _lockThreshold && !_isLocked) {
        _isLocked = true;
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _handleDragEnd() {
    if (_isLocked) return; // Keep recording if locked
    _stopRecording();
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    if (!_isRecording) return;

    _recordTimer?.cancel();

    final path = await _recorderController.stop();
    final durationMs =
        _recordStartTime != null
            ? DateTime.now().difference(_recordStartTime!).inMilliseconds
            : 0;

    final actualCancel = cancel || _isCancelling;

    setState(() {
      _isRecording = false;
      _isLocked = false;
      _dragDeltaX = 0;
      _dragDeltaY = 0;
      _isCancelling = false;
      _currentAmplitude = 0;
    });

    if (!actualCancel && path != null && widget.onVoiceSend != null) {
      if (durationMs < 1000) {
        // Too short!
        HapticFeedback.vibrate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Hold to record! Voice message too short. 🎙️'),
              backgroundColor: AppTheme.duoRed,
              behavior: SnackBarBehavior.floating,
              duration: 1.seconds,
            ),
          );
        }
        // Clean up
        final file = File(path);
        if (await file.exists()) await file.delete();
        return;
      }

      widget.onVoiceSend!(path, (durationMs / 1000).ceil(), _amplitudes);
      HapticFeedback.mediumImpact();
    } else if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.activeColor ?? AppTheme.primaryColor;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isCancelling
                                ? Colors.grey.shade100
                                : (_isLocked
                                    ? AppTheme.duoBlue.withValues(alpha: 0.1)
                                    : AppTheme.duoRed.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                                Icons.mic,
                                color:
                                    _isCancelling
                                        ? Colors.grey
                                        : (_isLocked
                                            ? AppTheme.duoBlue
                                            : AppTheme.duoRed),
                                size: 16,
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(
                                duration: 1.seconds,
                                color: Colors.white,
                              ),
                          const SizedBox(width: 4),
                          Text(
                            _recordDuration,
                            style: TextStyle(
                              color:
                                  _isCancelling
                                      ? Colors.grey
                                      : (_isLocked
                                          ? AppTheme.duoBlue
                                          : AppTheme.duoRed),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child:
                            _isLocked
                                ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          () => _stopRecording(cancel: true),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.duoRed,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppTheme.duoRed,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _stopRecording(),
                                      icon: const Icon(
                                        Icons.send,
                                        color: AppTheme.duoBlue,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Send',
                                        style: TextStyle(
                                          color: AppTheme.duoBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : Text(
                                      _isCancelling
                                          ? 'Release to delete'
                                          : ' < < Slide to cancel | ^ Slide to lock',
                                      style: TextStyle(
                                        color:
                                            _isCancelling
                                                ? AppTheme.duoRed
                                                : AppTheme.textLight,
                                        fontSize: 13,
                                        fontWeight:
                                            _isCancelling
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontFamily: 'Rubik',
                                      ),
                                    )
                                    .animate(onPlay: (c) => c.repeat())
                                    .shimmer(
                                      delay: 500.ms,
                                      duration: 2.seconds,
                                    ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (widget.prefix != null && !_isRecording) ...[
                  widget.prefix!,
                  const SizedBox(width: AppTheme.duoSpacingSmall),
                ],

                // Image picker button (optional)
                if (widget.onImagePick != null && !_isRecording)
                  GestureDetector(
                    onTap:
                        (widget.enabled &&
                                !widget.isSending &&
                                !widget.isLoading)
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
                            (widget.enabled &&
                                    !widget.isSending &&
                                    !widget.isLoading)
                                ? themeColor
                                : AppTheme.textLight,
                      ),
                    ),
                  ),

                if (widget.onImagePick != null && !_isRecording)
                  const SizedBox(width: AppTheme.duoSpacingSmall),

                // Text input field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(
                        AppTheme.duoRadiusPill,
                      ),
                      border: Border.all(
                        color:
                            _isRecording
                                ? (_isLocked
                                        ? AppTheme.duoBlue
                                        : AppTheme.duoRed)
                                    .withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                      ),
                    ),
                    child:
                        _isRecording
                            ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.duoSpacingMedium,
                                vertical: 12,
                              ),
                              child: Text(
                                _isLocked
                                    ? 'Voice recording locked...'
                                    : 'Recording voice message...',
                                style: TextStyle(
                                  color:
                                      _isLocked
                                          ? AppTheme.duoBlue
                                          : AppTheme.duoRed,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                            )
                            : TextField(
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
                                  (widget.enabled &&
                                          !widget.isSending &&
                                          !widget.isLoading)
                                      ? (_) => _handleSend()
                                      : null,
                            ),
                  ),
                ),

                const SizedBox(width: AppTheme.duoSpacingSmall),

                // Send/Voice button
                GestureDetector(
                  onPanUpdate: _isRecording ? _onDragUpdate : null,
                  onPanEnd: _isRecording ? (_) => _handleDragEnd() : null,
                  onTap:
                      (widget.enabled &&
                              !widget.isSending &&
                              !widget.isLoading &&
                              !showVoice)
                          ? _handleSend
                          : null,
                  onLongPress:
                      (widget.enabled &&
                              !widget.isSending &&
                              !widget.isLoading &&
                              showVoice)
                          ? _startRecording
                          : null,
                  onLongPressUp: _isRecording ? _handleDragEnd : null,
                  child:
                      Container(
                            width: _isRecording ? 56 : 48,
                            height: _isRecording ? 56 : 48,
                            decoration: BoxDecoration(
                              gradient:
                                  (widget.enabled &&
                                          !widget.isSending &&
                                          !widget.isLoading)
                                      ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors:
                                            _isRecording
                                                ? (_isCancelling
                                                    ? [
                                                      Colors.grey.shade400,
                                                      Colors.grey.shade600,
                                                    ]
                                                    : (_isLocked
                                                        ? AppTheme
                                                            .duoBlueGradient
                                                        : [
                                                          AppTheme.duoRed,
                                                          AppTheme.duoRed
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                        ]))
                                                : [
                                                  themeColor,
                                                  themeColor.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                ],
                                      )
                                      : null,
                              color:
                                  (widget.enabled &&
                                          !widget.isSending &&
                                          !widget.isLoading)
                                      ? null
                                      : Colors.grey.shade300,
                              shape: BoxShape.circle,
                              boxShadow:
                                  (widget.enabled &&
                                          !widget.isSending &&
                                          !widget.isLoading)
                                      ? [
                                        BoxShadow(
                                          color:
                                              (_isRecording
                                                      ? (_isCancelling
                                                          ? Colors.grey
                                                          : (_isLocked
                                                              ? AppTheme.duoBlue
                                                              : AppTheme
                                                                  .duoRed))
                                                      : themeColor)
                                                  .withValues(
                                                    alpha:
                                                        0.3 +
                                                        (_isRecording
                                                            ? (_currentAmplitude *
                                                                0.4)
                                                            : 0),
                                                  ),
                                          blurRadius:
                                              8 +
                                              (_isRecording
                                                  ? (_currentAmplitude * 12)
                                                  : 0),
                                          spreadRadius:
                                              (_isRecording
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
                                            : (_isLocked
                                                ? Icons.lock
                                                : Icons.mic))
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
                ),
              ],
            ),
          ],
        ),
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
