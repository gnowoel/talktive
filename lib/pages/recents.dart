import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../services/history.dart';
import '../widgets/record_list.dart';

class RecentsPage extends StatefulWidget {
  const RecentsPage({super.key});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> {
  late History history;
  late List<Record> records;
  late Ticker ticker;

  @override
  void initState() {
    super.initState();
    history = Provider.of<History>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    records = history.recentRecords;
    ticker = Ticker((elapsed) {
      print('elapsed: $elapsed');
      setState(() {
        records = history.recentRecords;
      });
    });
    ticker.start();
  }

  @override
  void dispose() {
    ticker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Recents'),
      ),
      body: RecordList(records: records),
    );
  }
}
