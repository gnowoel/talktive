import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../services/firedata.dart';

class InputField extends StatefulWidget {
  final Room room;

  const InputField({
    super.key,
    required this.room,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late Firedata firedata;
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();

    firedata.sendMessage(widget.room.id, Message(content: content));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
          ),
        ),
        IconButton(
          onPressed: _sendMessage,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}
