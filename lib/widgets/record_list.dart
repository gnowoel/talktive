import 'package:flutter/material.dart';

import '../models/record.dart';
import 'record_item.dart';

class RecordList extends StatefulWidget {
  final List<Record> records;

  const RecordList({
    super.key,
    required this.records,
  });

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: widget.records.length,
      itemBuilder: (context, index) {
        return RecordItem(record: widget.records[index]);
      },
    );
  }
}
