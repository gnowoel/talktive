import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../helpers/helpers.dart';
import '../../services/avatar.dart';
import '../../services/fireauth.dart';
import '../../services/firedata.dart';
import '../models/user.dart';
import '../services/server_clock.dart';
import '../widgets/layout.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late ThemeData theme;
  late String languageCode;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;
  late ServerClock serverClock;

  late String _photoURL;
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;

  final _formKey = GlobalKey<FormState>();
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
    serverClock = context.read<ServerClock>();

    final user = widget.user;

    _photoURL = user.photoURL ?? avatar.code;
    _displayNameController = TextEditingController(text: user.displayName);
    _descriptionController = TextEditingController(text: user.description);
    _selectedGender = user.gender;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    languageCode = getLanguageCode(context);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _descriptionController.dispose();
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
          userId: widget.user.id,
          languageCode: languageCode,
          photoURL: _photoURL,
          displayName: displayName,
          description: description,
          gender: _selectedGender!,
        );

        if (mounted) {
          context.pop(); // Go back to profile page
        }
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
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: Layout(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      _photoURL,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: _changeAvatar,
                      icon: const Icon(Icons.shuffle),
                      tooltip: 'Change avatar',
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
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
