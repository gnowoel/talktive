import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../models/topic.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';

import '../widgets/layout.dart';

import 'two_person_topic.dart';
import 'normal_topic.dart';

class TopicPage extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;

  const TopicPage({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
  });

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firestore firestore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    fireauth = Provider.of<Fireauth>(context);
    firestore = Provider.of<Firestore>(context);
  }

  Future<Topic> _loadTopic() async {
    final userId = fireauth.instance.currentUser!.uid;

    // First try to get from cache or subscription
    try {
      final subscription = firestore.subscribeToTopic(userId, widget.topicId);
      final topic = await subscription.first;

      if (topic.isDummy) {
        throw AppException('The topic has been deleted.');
      }

      return topic;
    } catch (e) {
      throw AppException('Failed to load topic: ${e.toString()}');
    }
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Loading...'),
      ),
      body: SafeArea(
        child: Layout(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage(String error) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Error'),
      ),
      body: SafeArea(
        child: Layout(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Topic>(
      future: _loadTopic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPage();
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          final errorMessage = error is AppException
              ? error.message
              : 'An unexpected error occurred';
          return _buildErrorPage(errorMessage);
        }

        if (!snapshot.hasData) {
          return _buildErrorPage('Topic not found');
        }

        final topic = snapshot.data!;

        // Route to appropriate page based on topic type
        if (topic.isTwoPersonTopic) {
          return TwoPersonTopicPage(
            topicId: widget.topicId,
            topicCreatorId: widget.topicCreatorId,
          );
        } else {
          return NormalTopicPage(
            topicId: widget.topicId,
            topicCreatorId: widget.topicCreatorId,
          );
        }
      },
    );
  }
}
