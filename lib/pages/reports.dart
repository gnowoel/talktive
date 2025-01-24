import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report.dart';
import '../../services/cache.dart';
import '../../services/firedata.dart';
import '../../widgets/layout.dart';
import '../services/messaging.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Firedata firedata;
  List<Report> _reports = [];

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();
  }

  void _showReportDetails(Report report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailsDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Reports'),
      ),
      body: SafeArea(
        child: Layout(
          child: StreamBuilder<List<Report>>(
            stream: firedata.subscribeToReports(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              _reports = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return ReportItem(
                    report: report,
                    onTap: () => _showReportDetails(report),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ReportItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportItem({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(report.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHigh,
      child: ListTile(
        leading: Icon(
          report.status == 'pending' ? Icons.report_outlined : Icons.task_alt,
          color: report.status == 'pending'
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
        title: Text(report.partnerDisplayName ??
            'Report #${report.id.substring(0, 8)}'),
        subtitle: Text(
          'Created ${timeago.format(createdAt, clock: now)}',
        ),
        trailing: report.status == 'pending'
            ? TextButton(
                onPressed: onTap,
                child: const Text('Review'),
              )
            : Text(
                'Resolved',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                ),
              ),
        onTap: () {
          final userId = report.userId;
          final chatId = report.chatId;
          final displayName = report.partnerDisplayName;
          context
              .push(Messaging.encodeReviewRoute(userId, chatId, displayName));
        },
      ),
    );
  }
}

class ReportDetailsDialog extends StatefulWidget {
  final Report report;

  const ReportDetailsDialog({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<ReportDetailsDialog> {
  final _resolutionController = TextEditingController(text: '30');
  bool _isProcessing = false;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (_isProcessing) return;

    final resolution = _resolutionController.text.trim();
    if (resolution.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final firedata = context.read<Firedata>();
      final cache = context.read<Cache>();

      await firedata.resolveReport(
        report: widget.report,
        resolution: resolution,
        serverNow: cache.now,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.report.createdAt);

    return AlertDialog(
      title: Text('Report Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${widget.report.status}'),
          const SizedBox(height: 8),
          Text('Created: ${timeago.format(createdAt, clock: now)}'),
          const SizedBox(height: 16),
          if (widget.report.status == 'pending') ...[
            TextField(
              controller: _resolutionController,
              decoration: const InputDecoration(
                labelText: 'Resolution',
                hintText: 'Enter resolution details',
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ] else ...[
            Text('Resolution: ${widget.report.resolution}'),
            const SizedBox(height: 8),
            Text('Resolved by: ${widget.report.adminId}'),
            Text(
              'Resolved: ${timeago.format(
                DateTime.fromMillisecondsSinceEpoch(widget.report.resolvedAt!),
                clock: now,
              )}',
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (widget.report.status == 'pending')
          FilledButton(
            onPressed: _isProcessing ? null : () => _resolve(),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  )
                : const Text('Resolve'),
          ),
      ],
    );
  }
}
