import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/user.dart';
import '../services/chat_cache.dart';
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../services/message_cache.dart';
import '../services/server_clock.dart';
import '../services/settings.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info.dart';
import '../widgets/info_notice.dart';
import '../widgets/layout.dart';
import '../widgets/user_list.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Settings settings;
  late Fireauth fireauth;
  late Firestore firestore;
  late ServerClock serverClock;
  late ChatCache chatCache;
  late ChatMessageCache chatMessageCache;

  List<User> _seenUsers = [];
  List<User> _users = [];
  bool _isPopulated = false;
  bool _canRefresh = true;
  Timer? _refreshTimer;

  String? _selectedGender;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();

    settings = context.read<Settings>();
    fireauth = context.read<Fireauth>();
    firestore = context.read<Firestore>();
    serverClock = context.read<ServerClock>();
    chatCache = context.read<ChatCache>();
    chatMessageCache = context.read<ChatMessageCache>();

    _selectedGender = settings.selectedGender;
    _selectedLanguage = settings.selectedLanguage;

    _fetchUsers(chatCache.chats);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatCache = Provider.of<ChatCache>(context);
  }

  void _handleGenderChanged(String? value) {
    if (_selectedGender == value) return;

    setState(() {
      _selectedGender = value;
      settings.setSelectedGender(value);
      _refreshUsers(noCache: true);
    });
  }

  void _handleLanguageChanged(String? value) {
    if (_selectedLanguage == value) return;

    setState(() {
      _selectedLanguage = value;
      settings.setSelectedLanguage(value);
      _refreshUsers(noCache: true);
    });
  }

  void _resetFilters() async {
    setState(() {
      _selectedGender = null;
      _selectedLanguage = null;
    });
    await settings.resetFilters();
    _refreshUsers(noCache: true);
  }

  Future<void> _refreshUsers({bool noCache = false}) async {
    if (!_canRefresh) return;

    setState(() => _canRefresh = false);

    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _canRefresh = true);
      }
    });

    serverClock = context.read<ServerClock>();
    _fetchUsers(chatCache.chats, noCache: noCache);
  }

  Future<void> _fetchUsers(List<Chat> chats, {bool noCache = false}) async {
    final userId = fireauth.instance.currentUser!.uid;
    final serverNow = serverClock.now;

    final users = await firestore.fetchUsers(
      userId,
      serverNow,
      genderFilter: _selectedGender,
      languageFilter: _selectedLanguage,
      noCache: noCache,
    );

    setState(() {
      _seenUsers = _users;
      _users = users;
      _isPopulated = true;
    });
  }

  List<User> _filterUsers() {
    final userId = fireauth.instance.currentUser!.uid;
    final users =
        _users.where((user) {
          return user.id != userId;
        }).toList();
    return users;
  }

  List<String> _knownUserIds(List<Chat> chats) {
    final userId = fireauth.instance.currentUser!.uid;
    final partnerIds = _partnerIds(userId, chats);
    return [userId, ...partnerIds];
  }

  List<String> _seenUserIds() {
    return _seenUsers.map((user) => user.id).toList();
  }

  List<String> _partnerIds(String userId, List<Chat> chats) {
    return chats.map((chat) {
      return chat.id.replaceFirst(userId, '');
    }).toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['No more users here.', 'Try again later.', ''];
    const info = 'Please do not give out personal information to strangers.';

    final chats = chatCache.chats;
    final knownUserIds = _knownUserIds(chats);
    final seenUserIds = _seenUserIds();
    final users = _filterUsers();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Active Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh users',
            onPressed: _canRefresh ? _refreshUsers : null,
          ),
        ],
      ),
      body: SafeArea(
        child:
            users.isEmpty
                ? (_isPopulated
                    ? Column(
                      children: [
                        FilterBar(
                          selectedGender: _selectedGender,
                          selectedLanguage: _selectedLanguage,
                          onGenderChanged: _handleGenderChanged,
                          onLanguageChanged: _handleLanguageChanged,
                          onReset: _resetFilters,
                          canRefresh: _canRefresh,
                        ),
                        Expanded(
                          child: const Center(child: Info(lines: lines)),
                        ),
                      ],
                    )
                    : const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ))
                : Layout(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      if (!settings.hasHiddenUsersNotice)
                        InfoNotice(
                          content: info,
                          onDismiss: () => settings.hideUsersNotice(),
                        ),
                      FilterBar(
                        selectedGender: _selectedGender,
                        selectedLanguage: _selectedLanguage,
                        onGenderChanged: _handleGenderChanged,
                        onLanguageChanged: _handleLanguageChanged,
                        onReset: _resetFilters,
                        canRefresh: _canRefresh,
                      ),
                      Expanded(
                        child: UserList(
                          users: users,
                          knownUserIds: knownUserIds,
                          seenUserIds: seenUserIds,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
