import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report.dart';
import '../../services/firedata.dart';
import '../../widgets/layout.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';

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

    return StreamBuilder<List<Report>>(
      stream: firedata.subscribeToReports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              title: Text('Reports'),
            ),
            body: SafeArea(child: Center(child: const Text('(Empty)'))),
          );
        }

        _reports = snapshot.data!;

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            title: Text('Reports (${_reports.length})'),
          ),
          body: SafeArea(
            child: Layout(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return ReportItem(
                    report: report,
                    onTap: () => _showReportDetails(report),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReportItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportItem({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(report.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHigh,
      child: ListTile(
        leading: Icon(
          report.status == 'pending' ? Icons.report_outlined : Icons.task_alt,
          color:
              report.status == 'pending'
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
        ),
        title: Text(
          report.partnerDisplayName ?? 'Report #${report.id.substring(0, 8)}',
        ),
        subtitle: Text('Created ${timeago.format(createdAt, clock: now)}'),
        trailing: TextButton(
          onPressed: onTap,
          child:
              report.revivedAt == null
                  ? const Text('Review')
                  : Text(
                    '${DateTime.fromMillisecondsSinceEpoch(report.revivedAt!).difference(now).inDays}d',
                  ),
        ),
        // trailing: report.status == 'pending'
        //     ? TextButton(
        //         onPressed: onTap,
        //         child: const Text('Review'),
        //       )
        //     : Text(
        //         'Resolved',
        //         style: TextStyle(
        //           color: theme.colorScheme.outline,
        //         ),
        //       ),
        onTap: () {
          final userId = report.userId;
          final chatId = report.chatId;
          final displayName = report.partnerDisplayName;
          context.push(
            Messaging.encodeReportRoute(userId, chatId, displayName),
          );
        },
      ),
    );
  }
}

class ReportDetailsDialog extends StatefulWidget {
  final Report report;

  const ReportDetailsDialog({super.key, required this.report});

  @override
  State<ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<ReportDetailsDialog> {
  String _resolution = '0';
  bool _isProcessing = false;

  Future<void> _resolve() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final firedata = context.read<Firedata>();
      final serverClock = context.read<ServerClock>();

      await firedata.resolveReport(
        report: widget.report,
        resolution: _resolution,
        serverNow: serverClock.now,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.fromMillisecondsSinceEpoch(ServerClock().now);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      widget.report.createdAt,
    );

    return AlertDialog(
      title: Text('Report Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${widget.report.status}'),
          const SizedBox(height: 16),
          Text('Created: ${timeago.format(createdAt, clock: now)}'),
          if (widget.report.revivedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Revived: ${DateTime.fromMillisecondsSinceEpoch(widget.report.revivedAt!).difference(now).inDays}d',
            ),
          ],
          const SizedBox(height: 16),
          const Text('Suspension duration:'),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('No suspension'),
            value: '0',
            groupValue: _resolution,
            onChanged: (value) {
              setState(() {
                _resolution = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('1 day'),
            value: '1',
            groupValue: _resolution,
            onChanged: (value) {
              setState(() {
                _resolution = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('3 days'),
            value: '3',
            groupValue: _resolution,
            onChanged: (value) {
              setState(() {
                _resolution = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('7 days'),
            value: '7',
            groupValue: _resolution,
            onChanged: (value) {
              setState(() {
                _resolution = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('14 days'),
            value: '14',
            groupValue: _resolution,
            onChanged: (value) {
              setState(() {
                _resolution = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : () => _resolve(),
          child:
              _isProcessing
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                  : const Text('Resolve'),
        ),
      ],
    );
  }
}
