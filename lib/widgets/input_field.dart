import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
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
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    avatar = Provider.of<Avatar>(context);
  }

  Future<void> _sendMessage() async {
    final roomId = widget.room.id;
    final userId = fireauth.instance.currentUser!.uid;
    final userName = avatar.name;
    final userCode = avatar.code;
    final content = _controller.text.trim();

    firedata.sendMessage(
      roomId,
      userId,
      userName,
      userCode,
      content,
    );
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
