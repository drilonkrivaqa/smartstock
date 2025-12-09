import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final locations = settingsController.locations;
        final active = settingsController.activeLocation;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: settingsController.darkMode,
                    title: const Text('Dark mode'),
                    onChanged: (value) =>
                        settingsController.toggleTheme(value),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                  SwitchListTile(
                    value: settingsController.highlightLowStock,
                    title: const Text('Highlight low stock items'),
                    onChanged: (value) =>
                        settingsController.toggleHighlightLowStock(value),
                    secondary:
                    const Icon(Icons.notification_important_outlined),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selling points (supermarkets)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define your different points of sale (e.g. main supermarket, '
                        'mini market, kiosk). Every sale will be tagged with the '
                        'currently active point.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Active selling point',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: active,
                        items: locations
                            .map(
                              (loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(loc),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settingsController.setActiveLocation(value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: locations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final loc = locations[index];
                      final isActive = loc == active;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isActive
                              ? Icons.storefront
                              : Icons.storefront_outlined,
                        ),
                        title: Text(loc),
                        subtitle: isActive
                            ? const Text('Active',
                            style: TextStyle(fontWeight: FontWeight.w500))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Rename',
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final controller =
                                TextEditingController(text: loc);
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Rename selling point'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(controller.text.trim());
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result != null && result.isNotEmpty) {
                                  await settingsController.renameLocation(
                                      loc, result);
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: locations.length <= 1
                                  ? null
                                  : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                        'Delete selling point?'),
                                    content: Text(
                                      'Are you sure you want to delete "$loc"?\n'
                                          'Existing sales will still show this name.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await settingsController
                                      .removeLocation(loc);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add selling point'),
                      onPressed: () async {
                        final controller = TextEditingController();
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('New selling point'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                hintText: 'e.g. Mini market #2',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(controller.text.trim());
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                        if (result != null && result.isNotEmpty) {
                          await settingsController.addLocation(result);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
