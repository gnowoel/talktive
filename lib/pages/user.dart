import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/history.dart';
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
  late History history;

  @override
  void initState() {
    super.initState();
    history = Provider.of<History>(context, listen: false);
    history.loadRecords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    avatar = Provider.of<Avatar>(context);
  }

  Future<void> write() async {
    final userId = fireauth.instance.currentUser!.uid;
    final userName = avatar.name;
    final userCode = avatar.code;
    final languageCode = Localizations.localeOf(context).languageCode;

    final room = await firedata.createRoom(
      userId,
      userName,
      userCode,
      languageCode,
    );

    enter(room);
  }

  Future<void> read() async {
    final room = await firedata.selectRoom();
    if (room != null) {
      enter(room);
    }
  }

  void enter(Room room) {
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
                avatar.code,
                style: const TextStyle(fontSize: 64),
              ),
              Text(avatar.name),
              IconButton(
                onPressed: () {
                  avatar.refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
              FilledButton(
                onPressed: read,
                child: const Text('Read'),
              ),
              OutlinedButton(
                onPressed: write,
                child: const Text('Write'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
