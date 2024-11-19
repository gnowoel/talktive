import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/history.dart';
import 'chat.dart';
import 'recents.dart';
import 'rooms.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late String languageCode;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;
  late History history;

  bool _isLocked = false;

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
    languageCode = getLanguageCode(context);
  }

  void _refresh() {
    _doAction(() async {
      avatar.refresh();
    });
  }

  Future<void> _fetch() async {
    _doAction(() async {
      final recentRoomIds = history.recentRoomIds;
      final rooms = await firedata.fetchRooms(languageCode, recentRoomIds);

      _enterPage(RoomsPage(rooms: rooms));
    });
  }

  Future<void> _create() async {
    await _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      final userName = avatar.name;
      final userCode = avatar.code;

      final room = await firedata.createRoom(
        userId,
        userName,
        userCode,
        languageCode,
      );

      if (mounted) {
        _enterPage(ChatPage(room: room));
      }
    });
  }

  void _recents() {
    _doAction(() async {
      _enterPage(const RecentsPage());
    });
  }

  void _enterPage(Widget widget) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
  }

  Future<void> _doAction(Future<void> Function() action) async {
    if (_isLocked == true) return;

    setState(() => _isLocked = true);

    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    }

    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SizedBox(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    avatar.code,
                    style: const TextStyle(fontSize: 64),
                  ),
                  Text(avatar.name),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Change profile',
                  ),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: _fetch,
                    child: const Text('Users'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _create,
                    child: const Text('Chats'),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: _recents,
                    // icon: const Icon(Icons.sentiment_neutral_outlined),
                    icon: const Icon(Icons.sentiment_satisfied_outlined),
                    tooltip: 'Recent rooms',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.lightbulb_outlined,
                    size: 16,
                  ),
                  label: const Text('Tell us more about you!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
