import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/report.dart';
import '../services/firedata.dart';
import '../services/server_clock.dart';

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
          child: _isProcessing
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
