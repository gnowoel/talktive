import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/firestore.dart';
import '../services/user_cache.dart';
import 'user_info_dialog.dart';

class UserInfoLoader extends StatefulWidget {
  final String userId;
  final String photoURL;
  final String displayName;

  const UserInfoLoader({
    super.key,
    required this.userId,
    required this.photoURL,
    required this.displayName,
  });

  @override
  State<UserInfoLoader> createState() => _UserInfoLoaderState();
}

class _UserInfoLoaderState extends State<UserInfoLoader> {
  late Firestore firestore;
  late UserCache userCache;
  User? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();

    final user = userCache.user!;
    if (widget.userId == user.id) {
      _user = user;
    } else {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await firestore.fetchUser(widget.userId);
      if (mounted) {
        setState(() => _user = user);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ErrorHandler.showSnackBarMessage(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return UserInfoDialog(
        photoURL: widget.photoURL,
        displayName: widget.displayName,
        error: _error,
      );
    }

    return UserInfoDialog(
      photoURL: _user!.photoURL!,
      displayName: _user!.displayName!,
      user: _user,
    );
  }
}
