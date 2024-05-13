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
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Text(
          widget.record.roomUserCode,
          style: const TextStyle(fontSize: 36),
        ),
        title: Text(
          widget.record.roomUserName,
        ),
        subtitle: const Text('Less than 1 hour ago.'),
        trailing: IconButton(
          icon: const Icon(Icons.keyboard_arrow_right),
          onPressed: () {},
        ),
      ),
    );
  }
}
