import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/admin.dart';
import '../models/user.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../widgets/layout.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  final VoidCallback? onComplete;

  const ProfilePage({
    super.key,
    this.user,
    this.onComplete,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ThemeData theme;
  late String languageCode;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;

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

  final minDisplayNameLength = 2;
  final maxDisplayNameLength = 30;
  final minDescriptionLength = 10;
  final maxDescriptionLength = 200;

  @override
  void initState() {
    super.initState();
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
    avatar = Provider.of<Avatar>(context, listen: false);

    _photoURL = widget.user?.photoURL ?? avatar.code;
    _displayNameController =
        TextEditingController(text: widget.user?.displayName);
    _descriptionController =
        TextEditingController(text: widget.user?.description);
    _selectedGender = widget.user?.gender;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    languageCode = getLanguageCode(context);
  }

  String? _validateDisplayName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a display name';
    }
    if (value.length < minDisplayNameLength) {
      return 'Must be at least $minDisplayNameLength characters';
    }
    if (value.length > maxDisplayNameLength) {
      return 'Must be less than $maxDisplayNameLength characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a brief description';
    }
    if (value.length < minDescriptionLength) {
      return 'Must be at least $minDescriptionLength characters';
    }
    if (value.length > maxDescriptionLength) {
      return 'Must be less than $maxDescriptionLength characters';
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
        final userId = fireauth.instance.currentUser!.uid;

        var displayName = _displayNameController.text.trim();
        var description = _descriptionController.text.trim();

        if (displayName.length > maxDisplayNameLength) {
          displayName = '${displayName.substring(0, maxDisplayNameLength)}...';
        }
        if (description.length > maxDescriptionLength) {
          description = '${description.substring(0, maxDescriptionLength)}...';
        }

        await firedata.updateProfile(
          userId: userId,
          languageCode: languageCode,
          photoURL: _photoURL,
          displayName: displayName,
          description: description,
          gender: _selectedGender!,
        );

        if (mounted) {
          Navigator.pop(context);
          widget.onComplete?.call();
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
  void dispose() {
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.user == null ? true : widget.user!.isNew;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: isNew ? const Text('About you') : const Text('My profile'),
        actions: [
          FutureBuilder<Admin?>(
            future: firedata.fetchAdmin(widget.user!.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    context.push('/admin/reports');
                  },
                  tooltip: 'Admin Panel',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Layout(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNew)
                      Card(
                        elevation: 0,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Make it easy for other people to find you.',
                                  style: TextStyle(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          _photoURL,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'What do people call you?',
                            ),
                            validator: _validateDisplayName,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Tell us a bit about yourself',
                            ),
                            validator: _validateDescription,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
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
                          Center(
                            child: FilledButton(
                              onPressed: _isProcessing ? null : _submit,
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(isNew ? 'Continue' : 'Save'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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
