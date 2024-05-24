import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/history.dart';
import '../widgets/info.dart';
import 'chat.dart';
import 'empty.dart';
import 'recents.dart';

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
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    history = Provider.of<History>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

    if (mounted) {
      _enterPage(ChatPage(room: room));
    }
  }

  Future<void> read() async {
    final recentRoomIds = history.recentRoomIds;
    final room = await firedata.selectRoom(recentRoomIds);

    final lines = [
      'No more to read.',
      'But you can write.',
      '',
    ];

    if (mounted) {
      if (room != null) {
        _enterPage(ChatPage(room: room));
      } else {
        _enterPage(EmptyPage(child: Info(lines: lines)));
      }
    }
  }

  void recents() {
    _enterPage(const RecentsPage());
  }

  void _enterPage(Widget widget) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
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
              const SizedBox(height: 4),
              FilledButton(
                onPressed: read,
                child: const Text('Read'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: write,
                child: const Text('Write'),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: recents,
                icon: const Icon(Icons.history),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
