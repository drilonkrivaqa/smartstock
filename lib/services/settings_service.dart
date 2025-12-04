import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'hive_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._box) {
    _darkMode = _box.get('darkMode', defaultValue: false) as bool;
    _highlightLowStock =
        _box.get('highlightLowStock', defaultValue: true) as bool;
  }

  final Box _box;
  late bool _darkMode;
  late bool _highlightLowStock;

  bool get darkMode => _darkMode;
  bool get highlightLowStock => _highlightLowStock;

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
}

Future<SettingsController> buildSettingsController() async {
  final settingsBox = Hive.box(HiveService.settingsBox);
  return SettingsController(settingsBox);
}
