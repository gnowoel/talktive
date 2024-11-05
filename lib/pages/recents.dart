import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../services/clock.dart';
import '../services/history.dart';
import '../widgets/info.dart';
import '../widgets/record_list.dart';

class RecentsPage extends StatefulWidget {
  const RecentsPage({super.key});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage>
    with SingleTickerProviderStateMixin {
  late History history;
  late List<Record> records;
  late Ticker ticker;

  DateTime then = DateTime.fromMillisecondsSinceEpoch(Clock().serverNow());

  @override
  void initState() {
    super.initState();
    history = Provider.of<History>(context, listen: false);
    records = history.visibleRecentRecords;
    ticker = createTicker((_) {
      final now = DateTime.fromMillisecondsSinceEpoch(Clock().serverNow());
      if (now.difference(then).inSeconds > 1) {
        setState(() {
          records = history.visibleRecentRecords;
          then = now;
        });
      }
    });
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['Your recent chats', 'will appear here.', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('History'),
      ),
      body: SafeArea(
        child: records.isEmpty
            ? const Center(child: Info(lines: lines))
            : _buildLayout(),
      ),
    );
  }

  LayoutBuilder _buildLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        if (constraints.maxWidth >= 600) {
          return Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(24),
                ),
                border: Border.all(color: theme.colorScheme.secondaryContainer),
              ),
              constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
              child: RecordList(records: records),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: RecordList(records: records),
          );
        }
      },
    );
  }
}
