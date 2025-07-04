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
import '../widgets/scrollable_center.dart';
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
  bool _isLoadingFilters = false;

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

    _selectedGender = null;
    _selectedLanguage = null;

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
      _isLoadingFilters = true;
      _refreshUsers(noCache: true);
    });
  }

  void _handleLanguageChanged(String? value) {
    if (_selectedLanguage == value) return;

    setState(() {
      _selectedLanguage = value;
      _isLoadingFilters = true;
      _refreshUsers(noCache: true);
    });
  }

  void _resetFilters() async {
    setState(() {
      _selectedGender = null;
      _selectedLanguage = null;
      _isLoadingFilters = true;
    });
    _refreshUsers(noCache: true);
  }

  Future<void> _refreshUsers({bool noCache = false}) async {
    await Future.delayed(const Duration(seconds: 1));
    _fetchUsers(chatCache.chats, noCache: noCache);
  }

  Future<void> _fetchUsers(
    List<Chat> chats, {
    bool noCache = false,
  }) async {
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
      _isLoadingFilters = false;
    });
  }

  List<User> _filterUsers() {
    final userId = fireauth.instance.currentUser!.uid;
    final users = _users.where((user) {
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

    final isLoading = users.isEmpty && !_isPopulated || _isLoadingFilters;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Active Users'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUsers,
          child: Column(
            children: [
              const SizedBox(height: 10),
              if (settings.shouldShowUsersPageNotice) ...[
                InfoNotice(
                  content: info,
                  onDismiss: () => settings.saveUsersPageNoticeVersion(),
                ),
              ],
              Expanded(
                child: Column(
                  children: [
                    FilterBar(
                      selectedGender: _selectedGender,
                      selectedLanguage: _selectedLanguage,
                      onGenderChanged: _handleGenderChanged,
                      onLanguageChanged: _handleLanguageChanged,
                      onReset: _resetFilters,
                    ),
                    Expanded(
                      child: isLoading
                          ? const ScrollableCenter(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : users.isEmpty
                              ? const ScrollableCenter(
                                  child: Info(lines: lines),
                                )
                              : UserList(
                                  users: users,
                                  knownUserIds: knownUserIds,
                                  seenUserIds: seenUserIds,
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
