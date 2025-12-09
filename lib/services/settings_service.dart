import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'hive_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._box) {
    _darkMode = _box.get('darkMode', defaultValue: false) as bool;
    _highlightLowStock =
    _box.get('highlightLowStock', defaultValue: true) as bool;

    // Load locations list
    final storedLocations = _box.get('locations');
    if (storedLocations is List) {
      _locations = storedLocations.cast<String>();
    } else {
      _locations = ['Main supermarket'];
    }

    if (_locations.isEmpty) {
      _locations = ['Main supermarket'];
    }

    // Load active location
    final storedActive = _box.get('activeLocation');
    if (storedActive is String && _locations.contains(storedActive)) {
      _activeLocation = storedActive;
    } else {
      _activeLocation = _locations.first;
      _box.put('activeLocation', _activeLocation);
    }

    // Ensure list is saved
    _box.put('locations', _locations);
  }

  final Box _box;

  late bool _darkMode;
  late bool _highlightLowStock;

  late List<String> _locations;
  late String _activeLocation;

  bool get darkMode => _darkMode;
  bool get highlightLowStock => _highlightLowStock;

  /// All defined selling points (supermarket branches)
  List<String> get locations => List.unmodifiable(_locations);

  /// Currently active selling point
  String get activeLocation => _activeLocation;

  Future<void> toggleTheme(bool enabled) async {
    _darkMode = enabled;
    await _box.put('darkMode', enabled);
    notifyListeners();
  }

  Future<void> toggleHighlightLowStock(bool enabled) async {
    _highlightLowStock = enabled;
    await _box.put('highlightLowStock', enabled);
    notifyListeners();
  }

  /// Set the active selling point (by name)
  Future<void> setActiveLocation(String name) async {
    if (!_locations.contains(name)) return;
    _activeLocation = name;
    await _box.put('activeLocation', _activeLocation);
    notifyListeners();
  }

  /// Add a new selling point
  Future<void> addLocation(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_locations.contains(trimmed)) return;

    _locations = [..._locations, trimmed];
    await _box.put('locations', _locations);

    // If this is the first one, make it active
    if (_locations.length == 1) {
      _activeLocation = trimmed;
      await _box.put('activeLocation', _activeLocation);
    }

    notifyListeners();
  }

  /// Remove a selling point. If it is active, move active to first remaining.
  Future<void> removeLocation(String name) async {
    if (!_locations.contains(name)) return;
    if (_locations.length == 1) {
      // Always keep at least one location
      return;
    }

    _locations = _locations.where((e) => e != name).toList();
    await _box.put('locations', _locations);

    if (_activeLocation == name) {
      _activeLocation = _locations.first;
      await _box.put('activeLocation', _activeLocation);
    }

    notifyListeners();
  }

  /// Rename a selling point
  Future<void> renameLocation(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    if (!_locations.contains(oldName)) return;

    final index = _locations.indexOf(oldName);
    _locations[index] = trimmed;
    await _box.put('locations', _locations);

    if (_activeLocation == oldName) {
      _activeLocation = trimmed;
      await _box.put('activeLocation', _activeLocation);
    }

    notifyListeners();
  }
}

Future<SettingsController> buildSettingsController() async {
  final settingsBox = Hive.box(HiveService.settingsBox);
  return SettingsController(settingsBox);
}
