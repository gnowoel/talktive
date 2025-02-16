import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/helpers.dart';
import '../../models/user.dart';
import '../../services/avatar.dart';
import '../../services/fireauth.dart';
import '../../services/firedata.dart';

class ProfileStep extends StatefulWidget {
  final VoidCallback onNext;

  const ProfileStep({
    super.key,
    required this.onNext,
  });

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  late ThemeData theme;
  late String languageCode;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;

  late String _photoURL;
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  late StreamSubscription _userSubscription;

  final _formKey = GlobalKey<FormState>();

  User? _user;
  String? _selectedGender;
  bool _isProcessing = false;

  final _genderOptions = [
    {'label': 'Female', 'value': 'F'},
    {'label': 'Male', 'value': 'M'},
    {'label': 'Other', 'value': 'O'},
    {'label': 'Prefer not to say', 'value': 'X'},
  ];

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    avatar = context.read<Avatar>();

    final userId = fireauth.instance.currentUser!.uid;

    _userSubscription = firedata.subscribeToUser(userId).listen((user) {
      if (user != null) {
        setState(() {
          _user = user;
          _photoURL = _user?.photoURL ?? avatar.code;
          _displayNameController =
              TextEditingController(text: _user?.displayName);
          _descriptionController =
              TextEditingController(text: _user?.description);
          _selectedGender = _user?.gender;
        });
        _userSubscription.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    languageCode = getLanguageCode(context);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _changeAvatar() {
    avatar.refresh();
    setState(() => _photoURL = avatar.code);
  }

  String? _validateDisplayName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a display name';
    }
    if (value.length < 2) {
      return 'Must be at least 2 characters';
    }
    if (value.length > 30) {
      return 'Must be less than 30 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a brief description';
    }
    if (value.length < 10) {
      return 'Must be at least 10 characters';
    }
    if (value.length > 200) {
      return 'Must be less than 200 characters';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select an option';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isProcessing) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      try {
        var displayName = _displayNameController.text.trim();
        var description = _descriptionController.text.trim();

        await firedata.updateProfile(
          userId: _user!.id,
          languageCode: languageCode,
          photoURL: _photoURL,
          displayName: displayName,
          description: description,
          gender: _selectedGender!,
        );

        widget.onNext();
      } on AppException catch (e) {
        if (mounted) {
          ErrorHandler.showSnackBarMessage(context, e);
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                _photoURL,
                style: TextStyle(fontSize: 64),
              ),
              IconButton(
                onPressed: _changeAvatar,
                icon: const Icon(Icons.shuffle),
                tooltip: 'Change avatar',
              ),
              const SizedBox(height: 16),
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'What do people call you?',
                ),
                validator: _validateDisplayName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us a bit about yourself',
                ),
                validator: _validateDescription,
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                ),
                value: _selectedGender,
                items: _genderOptions
                    .map((option) => DropdownMenuItem(
                          value: option['value'],
                          child: Text(option['label']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
                validator: _validateGender,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isProcessing ? null : _submit,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
