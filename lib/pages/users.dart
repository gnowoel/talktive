import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/firedata.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Firedata firedata;
  late List<User> _users;

  @override
  void initState() {
    super.initState();
    firedata = Provider.of<Firedata>(context, listen: false);
    _users = [];
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await firedata.getUsers();
    setState(() => _users = [..._users, ...users]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: SafeArea(
        child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              return Text(_users[index].displayName!);
            }),
      ),
    );
  }
}
