import 'package:hive/hive.dart';

import '../models/location.dart';
import 'hive_service.dart';

class LocationService {
  LocationService({required this.locationsBox});

  final Box<Location> locationsBox;

  List<Location> getAll() {
    final locations = locationsBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return locations;
  }

  Location? findById(int id) {
    try {
      return locationsBox.values.firstWhere((location) => location.id == id);
    } catch (_) {
      return null;
    }
  }

  Location? getWarehouse() {
    try {
      return locationsBox.values
          .firstWhere((location) => location.type == 'warehouse');
    } catch (_) {
      return null;
    }
  }

  Location? findByName(String name) {
    try {
      return locationsBox.values.firstWhere(
        (location) => location.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Location> ensureLocationByName(String name, {String type = 'store'}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return getWarehouse() ?? await ensureDefaultWarehouse();
    }
    final existing = findByName(trimmed);
    if (existing != null) return existing;

    final location = Location(
      id: DateTime.now().microsecondsSinceEpoch,
      name: trimmed,
      type: type,
      isActive: true,
    );
    await locationsBox.add(location);
    return location;
  }

  List<Location> getStores() {
    return locationsBox.values
        .where((location) => location.type == 'store')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Location> ensureDefaultWarehouse() async {
    final existingWarehouse = getWarehouse();
    if (existingWarehouse != null) return existingWarehouse;

    final warehouse = Location(
      id: DateTime.now().microsecondsSinceEpoch,
      name: 'Warehouse',
      type: 'warehouse',
      isActive: true,
    );
    await locationsBox.add(warehouse);
    return warehouse;
  }
}

Future<LocationService> buildLocationService() async {
  final locations = Hive.box<Location>(HiveService.locationsBox);
  final service = LocationService(locationsBox: locations);
  await service.ensureDefaultWarehouse();
  return service;
}
