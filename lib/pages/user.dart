import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import 'chat.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    avatar = Provider.of<Avatar>(context);
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  Future<void> chat() async {
    final userId = fireauth.instance.currentUser!.uid;
    final userName = avatar.current.name;
    final userCode = avatar.current.emoji;
    final languageCode = Localizations.localeOf(context).languageCode;

    final room = await firedata.createRoom(
      userId,
      userName,
      userCode,
      languageCode,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage(room: room)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avatar.current.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              Text(avatar.current.name),
              IconButton(
                onPressed: () {
                  avatar.refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
              FilledButton(
                onPressed: chat,
                child: const Text('Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
