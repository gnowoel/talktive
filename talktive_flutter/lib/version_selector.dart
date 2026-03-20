import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void _selectVersion(AppVersion version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_app_version', version.name);
    
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
      return const App();
    } else if (_selectedVersion == AppVersion.serverpod) {
      return ServerpodApp(onExit: _reset);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // App Branding
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Talktive',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safe Chat',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const Spacer(),

                  // Primary Action
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => _selectVersion(AppVersion.firebase),
                      style: FilledButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Start'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Secondary Action
                  TextButton(
                    onPressed: () => _selectVersion(AppVersion.serverpod),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('New safer version'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
