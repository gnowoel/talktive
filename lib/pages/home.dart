import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/history.dart';
import 'chat.dart';
import 'profile.dart';
import 'recents.dart';
import 'rooms.dart';
import 'users.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String languageCode;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;
  late History history;

  late StreamSubscription userSubscription;

  User? _user;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    history = Provider.of<History>(context, listen: false);

    final userId = fireauth.instance.currentUser!.uid;
    userSubscription = firedata.subscribeToUser(userId).listen((user) async {
      setState(() => _user = user);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    avatar = Provider.of<Avatar>(context);
    languageCode = getLanguageCode(context);
  }

  void _refresh() {
    _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      avatar.refresh();
      await firedata.updateAvatar(userId, avatar.code);
    });
  }

  Future<void> _fetch() async {
    _doAction(() async {
      final recentRoomIds = history.recentRoomIds;
      final rooms = await firedata.fetchRooms(languageCode, recentRoomIds);

      _enterPage(RoomsPage(rooms: rooms));
    });
  }

  Future<void> _users() async {
    _doAction(() async {
      _enterPage(UsersPage());
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

  void _profile() {
    _doAction(() async {
      _enterPage(const ProfilePage());
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
  void dispose() {
    userSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageName = getLanguageName(languageCode);
    final isEnglish = languageName == 'English';

    if (_user == null) {
      return Scaffold(
        body: SafeArea(
          child: const SizedBox(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: const SizedBox(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _user!.photoURL ?? avatar.code,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  Text(_user!.displayName ?? avatar.name),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Change avatar',
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _user!.isNew ? _profile : _users,
                    child: const Text('Users'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _recents,
                    child: const Text('Chats'),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: _profile,
                    icon: const Icon(Icons.sentiment_satisfied_outlined),
                    tooltip: 'Update profile',
                  ),
                ],
              ),
            ),
            Expanded(
              child: isEnglish ? const SizedBox() : _buildLanguageTip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTip() {
    final colorScheme = Theme.of(context).colorScheme;
    final languageName = getLanguageName(languageCode);

    return Center(
      child: TextButton.icon(
        onPressed: _profile,
        icon: const Icon(
          Icons.lightbulb_outlined,
          size: 16,
        ),
        label: Text(
          'You can chat in $languageName!',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
