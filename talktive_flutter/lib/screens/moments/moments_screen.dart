import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:talktive/serverpod_client.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  List<Moment>? _moments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final moments = await client.moment.listMoments(limit: 20);
      setState(() {
        _moments = moments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _postMoment(String caption, String imageUrl) async {
    try {
      await client.moment.postMoment(imageUrl: imageUrl, caption: caption);
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _loadMoments(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    }
  }

  void _showCreateDialog() {
    final captionController = TextEditingController();
    final urlController = TextEditingController(
      text: 'https://picsum.photos/400/300',
    ); // Default random image

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Moment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: captionController,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                _postMoment(captionController.text, urlController.text);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(onPressed: _loadMoments, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_moments == null || _moments!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Moments', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: Text('No moments yet. Be the first!')),
        floatingActionButton: FloatingActionButton(
          heroTag: 'moments_empty_fab',
          onPressed: _showCreateDialog,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Moments', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMoments,
        child: ListView.builder(
          itemCount: _moments!.length,
          itemBuilder: (context, index) {
            final moment = _moments![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: moment.authorAvatar.isNotEmpty
                          ? NetworkImage(moment.authorAvatar)
                          : null,
                      child: moment.authorAvatar.isEmpty
                          ? Text(moment.authorName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(moment.authorName),
                    subtitle: Text('Floor ${moment.authorFloor}'),
                  ),
                  if (moment.imageUrl.isNotEmpty)
                    Image.network(
                      moment.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 200,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (moment.caption != null &&
                            moment.caption!.isNotEmpty)
                          Text(
                            moment.caption!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${moment.createdAt.toLocal().toString().split('.')[0]}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'moments_fab',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
