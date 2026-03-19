import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';

/// Duolingo-style chat input with a pill-shaped design and vibrant send button.
class DuoChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String path)? onVoiceSend;
  final bool enabled;
  final String hintText;
  final VoidCallback? onImagePick;
  final Widget? prefix;
  final Color? activeColor;
  final FocusNode? focusNode;
  final bool isSending;
  final bool isLoading;

  const DuoChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoiceSend,
    this.enabled = true,
    this.isSending = false,
    this.isLoading = false,
    this.hintText = 'Type a message...',
    this.onImagePick,
    this.prefix,
    this.activeColor,
    this.focusNode,
  });

  @override
  State<DuoChatInput> createState() => _DuoChatInputState();
}

class _DuoChatInputState extends State<DuoChatInput> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordStartTime;
  Timer? _recordTimer;
  String _recordDuration = '0:00';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to toggle send/voice button
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig(); // Default config: m4a/aac
        
        await _audioRecorder.start(config, path: path);
        
        _recordStartTime = DateTime.now();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final duration = DateTime.now().difference(_recordStartTime!);
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;
          setState(() {
            _recordDuration = '$minutes:${seconds.toString().padLeft(2, '0')}';
          });
        });

        setState(() {
          _isRecording = true;
          _recordDuration = '0:00';
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
    });

    if (!cancel && path != null && widget.onVoiceSend != null) {
      widget.onVoiceSend!(path);
      HapticFeedback.lightImpact();
    } else if (cancel && path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.activeColor ?? AppTheme.primaryColor;
    final showVoice = widget.controller.text.trim().isEmpty && widget.onVoiceSend != null;

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
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: AppTheme.duoRed, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recording: $_recordDuration',
                      style: const TextStyle(
                        color: AppTheme.duoRed,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Release to send',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                        fontFamily: 'Rubik',
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
                    onTap: (widget.enabled && !widget.isSending && !widget.isLoading) ? widget.onImagePick : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.lightBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        size: 20,
                        color: (widget.enabled && !widget.isSending && !widget.isLoading) ? themeColor : AppTheme.textLight,
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
                      borderRadius: BorderRadius.circular(AppTheme.duoRadiusPill),
                      border: Border.all(
                        color: _isRecording ? AppTheme.duoRed.withValues(alpha: 0.3) : Colors.grey.shade200,
                      ),
                    ),
                    child: _isRecording
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.duoSpacingMedium,
                              vertical: 12,
                            ),
                            child: Text(
                              'Recording voice message...',
                              style: TextStyle(
                                color: AppTheme.duoRed,
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
                            onSubmitted: (widget.enabled && !widget.isSending && !widget.isLoading) ? (_) => _handleSend() : null,
                          ),
                  ),
                ),

                const SizedBox(width: AppTheme.duoSpacingSmall),

                // Send/Voice button
                GestureDetector(
                  onTap: (widget.enabled && !widget.isSending && !widget.isLoading && !showVoice) ? _handleSend : null,
                  onLongPress: (widget.enabled && !widget.isSending && !widget.isLoading && showVoice) ? _startRecording : null,
                  onLongPressUp: _isRecording ? () => _stopRecording() : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: (widget.enabled && !widget.isSending && !widget.isLoading)
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isRecording 
                                ? [AppTheme.duoRed, AppTheme.duoRed.withValues(alpha: 0.8)]
                                : [themeColor, themeColor.withValues(alpha: 0.8)],
                            )
                          : null,
                      color: (widget.enabled && !widget.isSending && !widget.isLoading) ? null : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: (widget.enabled && !widget.isSending && !widget.isLoading)
                          ? [
                              BoxShadow(
                                color: (_isRecording ? AppTheme.duoRed : themeColor).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      showVoice ? (_isRecording ? Icons.stop : Icons.mic) : Icons.send, 
                      color: Colors.white, 
                      size: 20,
                    ),
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
    if (widget.isSending || widget.isLoading || widget.controller.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSend();
  }
}
