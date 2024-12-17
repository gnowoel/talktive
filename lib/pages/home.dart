import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../services/avatar.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import 'chats.dart';
import 'profile.dart';
import 'users.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ThemeData theme;
  late String languageCode;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;
  late Cache cache;

  User? _user;
  List<Chat> _chats = [];
  Timer? _timer;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    theme = Theme.of(context);
    languageCode = getLanguageCode(context);

    avatar = Provider.of<Avatar>(context);
    cache = Provider.of<Cache>(context);

    _user = cache.user;
    _setChatsAndTimer();
  }

  void _setChatsAndTimer() {
    _chats = cache.chats.where((chat) => chat.isActive).toList();

    final nextTime = getNextTime(_chats);

    if (nextTime == null) return;

    final duration = Duration(
      milliseconds: nextTime,
    );

    _timer?.cancel();

    _timer = Timer(duration, () {
      setState(() {
        _setChatsAndTimer();
      });
    });
  }

  Future<void> _changeAvatar() async {
    await _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      avatar.refresh();
      await firedata.updateAvatar(userId, avatar.code);
    });
  }

  Future<void> _chatsPage() async {
    await _doAction(() async {
      await _enterPage(ChatsPage());
    });
  }

  Future<void> _usersPage() async {
    await _doAction(() async {
      if (_user!.isNew) {
        await _enterPage(ProfilePage(
          user: _user,
          onComplete: () async => await _enterPage(UsersPage()),
        ));
      } else {
        await _enterPage(UsersPage());
      }
    });
  }

  Future<void> _updateProfile() async {
    await _doAction(() async {
      await _enterPage(ProfilePage(user: _user));
    });
  }

  Future<void> _enterPage(Widget widget) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => widget));
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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: SafeArea(
          child: const SizedBox(),
        ),
      );
    }

    final newMessageCountTotal = chatsUnreadMessageCount(_chats);

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
                children: <Widget>[
                  Text(
                    _user!.photoURL ?? avatar.code,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  if (!_user!.isNew)
                    Text(
                      _user!.displayName ?? avatar.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                  if (!_user!.isNew) const SizedBox(height: 6),
                  IconButton(
                    onPressed: _changeAvatar,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Change avatar',
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _usersPage,
                    child: const Text('Users'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _chatsPage,
                    child: const Text('Chats'),
                  ),
                  const SizedBox(height: 8),
                  newMessageCountTotal > 0
                      ? TextButton(
                          onPressed: _chatsPage,
                          child: Badge(
                            label: Text('$newMessageCountTotal',
                                style: TextStyle(fontSize: 14)),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        )
                      : IconButton(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.sentiment_satisfied_outlined),
                          tooltip: 'Update profile',
                        ),
                ],
              ),
            ),
            Expanded(
              child: _buildTip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.lightbulb_outlined,
          size: 16,
        ),
        label: Text(
          _user!.isNew
              ? "Don't forget to update your profile"
              : "Inactive chats will expire in 3 days",
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
