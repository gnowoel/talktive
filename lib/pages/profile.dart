import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ThemeData theme;
  late Fireauth fireauth;
  late Firedata firedata;
  late Avatar avatar;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
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
    fireauth = Provider.of<Fireauth>(context, listen: false);
    firedata = Provider.of<Firedata>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    avatar = Provider.of<Avatar>(context);
  }

  String? _validateName(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a display name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 30) {
      return 'Name must be less than 30 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a brief description';
    }
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.length > 200) {
      return 'Description must be less than 200 characters';
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
        final now = DateTime.now().millisecondsSinceEpoch;

        await firedata.updateProfile(
          userId: userId,
          displayName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          gender: _selectedGender!,
          timestamp: now,
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  avatar.code,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'What do people call you?',
                    ),
                    validator: _validateName,
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
                    // maxLines: 3,
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
                // width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _submit,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
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
