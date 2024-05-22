import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../services/firedata.dart';
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

  DateTime then = DateTime.fromMillisecondsSinceEpoch(Firedata().now());

  @override
  void initState() {
    super.initState();
    history = Provider.of<History>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    records = history.recentRecords;
    ticker = createTicker((_) {
      final now = DateTime.fromMillisecondsSinceEpoch(Firedata().now());
      if (now.difference(then).inSeconds > 1) {
        setState(() {
          records = history.recentRecords;
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
    const lines = ['Your recent chats', 'will appear here.', ''];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
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
        if (constraints.maxWidth >= 600) {
          return Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.all(
                  Radius.circular(24),
                ),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
              child: RecordList(records: records),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: RecordList(records: records),
          );
        }
      },
    );
  }
}
