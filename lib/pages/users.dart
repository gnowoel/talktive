import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

import '../services/fireauth.dart';
import '../services/firestore.dart';

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

    _selectedGender = null;
    _selectedLanguage = null;

    _fetchUsers();
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
    if (!mounted) return;
    setState(() {
      _selectedGender = null;
      _selectedLanguage = null;
      _isLoadingFilters = true;
    });
    _refreshUsers(noCache: true);
  }

  Future<void> _refreshUsers({bool noCache = false}) async {
    await Future.delayed(const Duration(seconds: 1));
    _fetchUsers(noCache: noCache);
  }

  Future<void> _fetchUsers({
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

    if (!mounted) return;
    setState(() {
      _seenUsers = _users;
      _users = users;
      _isPopulated = true;
      _isLoadingFilters = false;
    });
  }

  void _removeUser(User user) {
    setState(() {
      _users.removeWhere((u) => u.id == user.id);
    });
  }

  void _restoreUser(User user) {
    setState(() {
      // Insert the user back at the correct position based on updatedAt
      final insertIndex =
          _users.indexWhere((u) => u.updatedAt < user.updatedAt);
      if (insertIndex == -1) {
        _users.add(user);
      } else {
        _users.insert(insertIndex, user);
      }
    });
  }

  List<User> _filterUsers() {
    final userId = fireauth.instance.currentUser!.uid;
    final serverNow = serverClock.now;
    final users = _users.where((user) {
      // Filter out current user
      if (user.id == userId) return false;

      // Filter out users with future revivedAt (timeout)
      if (user.revivedAt != null && user.revivedAt! >= serverNow) return false;

      return true;
    }).toList();
    return users;
  }

  List<String> _seenUserIds() {
    return _seenUsers.map((user) => user.id).toList();
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
                                  seenUserIds: seenUserIds,
                                  onRemove: _removeUser,
                                  onRestore: _restoreUser,
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
