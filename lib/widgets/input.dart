import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

class Input extends StatefulWidget {
  final String roomId;

  const Input({
    super.key,
    required this.roomId,
  });

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
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
    final roomId = widget.roomId;
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 4, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(
            Radius.circular(32),
          ),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                minLines: 1,
                maxLines: 12,
                controller: _controller,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter message',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
