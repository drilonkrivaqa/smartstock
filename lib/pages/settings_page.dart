import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                value: settingsController.darkMode,
                title: const Text('Dark mode'),
                onChanged: (value) => settingsController.toggleTheme(value),
                secondary: const Icon(Icons.dark_mode_outlined),
              ),
              SwitchListTile(
                value: settingsController.highlightLowStock,
                title: const Text('Highlight low stock items'),
                onChanged: (value) =>
                    settingsController.toggleHighlightLowStock(value),
                secondary: const Icon(Icons.notification_important_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
