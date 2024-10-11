import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../helpers/exception.dart';
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

    if (kIsWeb) {
      languageCode = View.of(context).platformDispatcher.locale.languageCode;
    } else {
      languageCode = Platform.localeName.split('_').first;
    }

    avatar = Provider.of<Avatar>(context);
  }

  void _refresh() {
    _doAction(() async {
      avatar.refresh();
    });
  }

  Future<void> _read() async {
    _doAction(() async {
      final recentRoomIds = history.recentRoomIds;
      final room = await firedata.selectRoom(languageCode, recentRoomIds);

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
    });
  }

  Future<void> _write() async {
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
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Change profile',
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: _read,
                child: const Text('Read'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _write,
                child: const Text('Write'),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: _recents,
                icon: const Icon(Icons.history),
                tooltip: 'Recent rooms',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
