import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Duolingo-style chat input with a pill-shaped design and vibrant send button.
class DuoChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String path, int durationSeconds)? onVoiceSend;
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
  final List<String>? mentionsWhitelist;

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
    this.mentionsWhitelist,
  });

  @override
  State<DuoChatInput> createState() => _DuoChatInputState();
}

class _DuoChatInputState extends State<DuoChatInput> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isFinishing = false;
  DateTime? _recordStartTime;
  Timer? _recordTimer;
  String _recordDuration = '0:00';
  Timer? _typingTimer;
  bool _wasTyping = false;

  // Mention Autocompletion
  OverlayEntry? _mentionOverlay;
  final LayerLink _layerLink = LayerLink();
  List<String> _filteredMentions = [];

  // Voice Recording Enhancements
  double _dragDeltaX = 0;
  bool _isCancelling = false;

  static const double _cancelThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _hideMentionOverlay();
    widget.controller.removeListener(_onTextChanged);
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to toggle send/voice button

    _checkMentions();

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

  void _checkMentions() {
    if (widget.mentionsWhitelist == null || widget.mentionsWhitelist!.isEmpty) {
      _hideMentionOverlay();
      return;
    }

    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _hideMentionOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;
    if (cursorPosition == 0) {
      _hideMentionOverlay();
      return;
    }

    // Find the last '@' before the cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      _hideMentionOverlay();
      return;
    }

    // Ensure there is a space before @ or it's at the start
    if (lastAtIndex > 0 && textBeforeCursor[lastAtIndex - 1] != ' ') {
      _hideMentionOverlay();
      return;
    }

    // The query is between @ and the cursor
    final query = textBeforeCursor.substring(lastAtIndex + 1);

    // If there is a space in the query, we check if it matches any name in whitelist.
    if (query.contains(' ') && !widget.mentionsWhitelist!.any((n) => n.toLowerCase().startsWith(query.toLowerCase()))) {
       _hideMentionOverlay();
       return;
    }

    _filteredMentions = widget.mentionsWhitelist!
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort((a, b) {
        // Prioritize names that start with the query
        final aStart = a.toLowerCase().startsWith(query.toLowerCase());
        final bStart = b.toLowerCase().startsWith(query.toLowerCase());
        if (aStart && !bStart) return -1;
        if (!aStart && bStart) return 1;
        return a.compareTo(b);
      });

    if (_filteredMentions.isNotEmpty) {
      // Small delay to ensure the layout has updated if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMentionOverlay();
      });
    } else {
      _hideMentionOverlay();
    }
  }

  void _showMentionOverlay() {
    if (_mentionOverlay != null) {
      _mentionOverlay!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    _mentionOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - (AppTheme.duoSpacingMedium * 2),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -8),
            followerAnchor: Alignment.bottomLeft,
            targetAnchor: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
              color: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium - 2),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredMentions.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final name = _filteredMentions[index];
                      return ListTile(
                        visualDensity: VisualDensity.compact,
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          radius: 14,
                          child: const Text(
                            '👤',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        onTap: () => _applyMention(name),
                      );
                    },
                  ),
                ),
              ),
            ).animate().slideY(begin: 0.1, end: 0, duration: 200.ms).fadeIn(),
          ),
        );
      },
    );

    overlay.insert(_mentionOverlay!);
  }

  void _hideMentionOverlay() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
  }

  void _applyMention(String name) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    final prefix = text.substring(0, lastAtIndex);
    final suffix = text.substring(cursorPosition);

    // Apply the mention with a trailing space
    final newText = '$prefix@$name $suffix';
    widget.controller.text = newText;

    // Position cursor after the mention and space
    final newPosition = lastAtIndex + name.length + 2;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newPosition),
    );

    _hideMentionOverlay();

    // Ensure focus is kept
    if (widget.focusNode != null) {
      widget.focusNode!.requestFocus();
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isFinishing) return;
    debugPrint('DuoChatInput: Attempting to start recording...');

    if (widget.onVoiceStart != null) {
      final canStart = await widget.onVoiceStart!();
      if (!canStart) {
        debugPrint('DuoChatInput: onVoiceStart returned false');
        return;
      }
    }

    try {
      debugPrint('DuoChatInput: Checking microphone permission...');
      if (await _audioRecorder.hasPermission()) {
        debugPrint('DuoChatInput: Permission granted');
        final directory = await getTemporaryDirectory();
        final ext = kIsWeb ? 'wav' : 'm4a';
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.$ext';

        const config = RecordConfig(
          encoder: kIsWeb ? AudioEncoder.wav : AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: kIsWeb ? 16000 : 44100,
          numChannels: 1,
        );

        debugPrint('DuoChatInput: Starting recorder with config: $config');
        await _audioRecorder.start(config, path: path);

        _recordStartTime = DateTime.now();
        _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (
          timer,
        ) {
          final duration = DateTime.now().difference(_recordStartTime!);
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
        });
        HapticFeedback.heavyImpact();
      } else {
        debugPrint('DuoChatInput: Microphone permission denied');
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  void _handleDragEnd() {
    if (kIsWeb) return; // Ignore drag end on web since we use toggle
    _stopRecording();
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    if (!_isRecording || _isFinishing) return;
    debugPrint('DuoChatInput: Stopping recording (cancel: $cancel)...');

    final actualCancel = cancel || _isCancelling;
    final startTimeToCapture = _recordStartTime;

    setState(() {
      _isRecording = false;
      _isFinishing = true;
      _dragDeltaX = 0;
      _isCancelling = false;
    });

    String? path;
    try {
      _recordTimer?.cancel();
      path = await _audioRecorder.stop();

      if (path != null) {
        if (!kIsWeb) {
          final file = File(path);
          if (await file.exists()) {
            final size = await file.length();
            debugPrint('Recording stopped. Path: $path, Size: $size bytes');
          }
        } else {
          debugPrint('Recording stopped. Path (Blob URL): $path');
        }
      }

      final durationMs = startTimeToCapture != null
          ? DateTime.now().difference(startTimeToCapture).inMilliseconds
          : 0;

      if (!actualCancel && path != null && widget.onVoiceSend != null) {
        if (durationMs < 1000) {
          // Too short!
          debugPrint('DuoChatInput: Recording too short ($durationMs ms)');
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
          if (!kIsWeb) {
            final file = File(path);
            if (await file.exists()) await file.delete();
          }
        } else {
          debugPrint('DuoChatInput: Sending voice message...');
          widget.onVoiceSend!(path, (durationMs / 1000).ceil());
          HapticFeedback.mediumImpact();
        }
      } else if (path != null && !kIsWeb) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        HapticFeedback.lightImpact();
      } else if (path != null && kIsWeb) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error in _stopRecording: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFinishing = false;
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

    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
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
    ),
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
                      color: _isCancelling
                          ? AppTheme.duoRed
                          : AppTheme.textLight,
                      fontSize: 13,
                      fontWeight: _isCancelling
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontFamily: 'Rubik',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),

        // Timer & Simplified Indicator
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.duoRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusPill),
              border: Border.all(color: AppTheme.duoRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.duoRed,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                    )
                    .fadeOut(begin: 0.5),
                const SizedBox(width: 12),
                Text(
                  _recordDuration,
                  style: const TextStyle(
                    color: AppTheme.duoRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Rubik',
                  ),
                ),
                const Spacer(),
                if (cancelProgress < 0.3)
                  Text(
                        '👈 Slide to cancel',
                        style: TextStyle(
                          color: AppTheme.duoRed.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Rubik',
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds),
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
      onLongPressStart:
          (widget.enabled &&
              !widget.isSending &&
              !widget.isLoading &&
              showVoice &&
              !kIsWeb) // Disable long press on web to avoid interference
          ? (_) => _startRecording()
          : null,
      onLongPressMoveUpdate: (details) {
        if (!_isRecording || kIsWeb) return;
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
      onLongPressEnd: kIsWeb ? null : (_) => _handleDragEnd(),
      onLongPressCancel: kIsWeb ? null : () => _handleDragEnd(),
      onTap: (widget.enabled && !widget.isSending && !widget.isLoading)
          ? () {
              debugPrint(
                'DuoChatInput: onTap triggered. showVoice: $showVoice, kIsWeb: $kIsWeb, _isRecording: $_isRecording',
              );
              if (showVoice) {
                if (kIsWeb) {
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                }
              } else {
                _handleSend();
              }
            }
          : null,
      child:
          Container(
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
                                    .withValues(alpha: 0.3),
                            blurRadius: 8,
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
                end: const Offset(1.1, 1.1),
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
