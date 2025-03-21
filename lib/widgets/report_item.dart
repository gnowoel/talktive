import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/report.dart';
import '../services/messaging.dart';
import '../services/server_clock.dart';

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
          final chatCreatedAt = '0';
          context.push(
            Messaging.encodeReportRoute(userId, chatId, chatCreatedAt),
          );
        },
      ),
    );
  }
}
