import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/history.dart';
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
    theme = Theme.of(context);
    avatar = Provider.of<Avatar>(context);
    languageCode = getLanguageCode(context);
  }

  Future<void> _refresh() async {
    await _doAction(() async {
      final userId = fireauth.instance.currentUser!.uid;
      avatar.refresh();
      await firedata.updateAvatar(userId, avatar.code);
    });
  }

  Future<void> _chats() async {
    await _doAction(() async {
      await _enterPage(const ChatsPage());
    });
  }

  Future<void> _redirect() async {
    await _doAction(() async {
      if (_user!.isNew) {
        await _enterPage(ProfilePage(
          user: _user,
          onComplete: _users,
        ));
      } else {
        await _users();
      }
    });
  }

  Future<void> _users() async {
    await _enterPage(UsersPage());
  }

  Future<void> _profile() async {
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
                  if (!_user!.isNew)
                    Text(
                      _user!.displayName ?? avatar.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                  if (!_user!.isNew) const SizedBox(height: 4),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Change avatar',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _chats,
                    icon: Icon(
                      Icons.circle,
                      size: 12,
                      color: null, // theme.colorScheme.errorContainer
                    ),
                    label: const Text('Chats'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _redirect,
                    icon: const Icon(Icons.radio_button_unchecked, size: 12),
                    label: const Text('Users'),
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
