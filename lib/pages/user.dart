import 'package:flutter/material.dart';

import '../services/avatar.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Avatar avatar;

  void _callback() => setState(() {});

  @override
  void initState() {
    super.initState();
    avatar = Avatar();
    avatar.addListener(_callback);
  }

  @override
  void dispose() {
    avatar.removeListener(_callback);
    super.dispose();
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
                avatar.current.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              Text(avatar.current.name),
              IconButton(
                onPressed: () {
                  avatar.refresh();
                },
                icon: const Icon(Icons.refresh),
              ),
              FilledButton(
                onPressed: () {},
                child: const Text('Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
