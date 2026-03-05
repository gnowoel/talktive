import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../serverpod_client.dart';
import '../../config/theme.dart';
import 'chat_thread_screen.dart';

class ChatLoaderScreen extends ConsumerStatefulWidget {
  final int channelId;

  const ChatLoaderScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChatLoaderScreen> createState() => _ChatLoaderScreenState();
}

class _ChatLoaderScreenState extends ConsumerState<ChatLoaderScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    try {
      final result = await client.privateChat.getPrivateChatDetails(
        widget.channelId,
      );

      final privateChat = result.chat;
      final otherResident = result.otherResident;

      if (!mounted) return;

      // Navigate to the chat thread screen replacing the loader
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatThreadScreen(
            privateChat: privateChat,
            otherUserId: otherResident.userInfoId.toString(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Loading Chat...'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppTheme.primaryColor)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.duoRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load chat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadChat();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/chats'),
                    child: const Text('Go to Chats'),
                  ),
                ],
              ),
      ),
    );
  }
}
