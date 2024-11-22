import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../models/user.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  const ProfilePage({super.key, this.user});

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
          photoURL: avatar.code,
          displayName: displayName,
          description: description,
          gender: _selectedGender!,
        );

        if (mounted) {
          Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('About me'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: FilledButton(
                  onPressed: _isProcessing ? null : _submit,
                  child: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
