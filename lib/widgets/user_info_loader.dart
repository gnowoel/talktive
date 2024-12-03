import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/cache.dart';
import '../services/firedata.dart';
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
  late Firedata firedata;
  User? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();

    final user = Cache().user;
    if (widget.userId == user!.id) {
      _user = user;
    } else {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await firedata.fetchUser(widget.userId);
      if (kDebugMode) {
        await Future.delayed(const Duration(seconds: 2));
      }
      if (mounted) {
        setState(() => _user = user);
      }
    } on AppException catch (e) {
      setState(() => _error = e.toString());
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
