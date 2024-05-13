import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history.dart';
import '../widgets/record_list.dart';

class RecentsPage extends StatefulWidget {
  const RecentsPage({super.key});

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> {
  late History history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    history = Provider.of<History>(context);
  }

  @override
  Widget build(BuildContext context) {
    final records = history.records;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Recents'),
      ),
      body: RecordList(records: records),
    );
  }
}
