import 'package:flutter/material.dart';
import 'app.dart';
import 'serverpod_app.dart';

enum AppVersion { firebase, serverpod }

class VersionSelector extends StatefulWidget {
  const VersionSelector({super.key});

  @override
  State<VersionSelector> createState() => _VersionSelectorState();
}

class _VersionSelectorState extends State<VersionSelector> {
  AppVersion? _selectedVersion;

  void _selectVersion(AppVersion version) {
    setState(() {
      _selectedVersion = version;
    });
  }

  void _reset() {
    setState(() {
      _selectedVersion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedVersion == AppVersion.firebase) {
      return App(onExit: _reset);
    } else if (_selectedVersion == AppVersion.serverpod) {
      return ServerpodApp(onExit: _reset);
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Select Version')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose your backend:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _selectVersion(AppVersion.firebase),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                child: const Text('Firebase (Old)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _selectVersion(AppVersion.serverpod),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                child: const Text('Serverpod (New)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
