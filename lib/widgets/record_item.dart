import 'package:flutter/material.dart';

import '../models/record.dart';

class RecordItem extends StatefulWidget {
  final Record record;

  const RecordItem({
    super.key,
    required this.record,
  });

  @override
  State<RecordItem> createState() => _RecordItemState();
}

class _RecordItemState extends State<RecordItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(widget.record.roomUserCode),
      ),
    );
  }
}
