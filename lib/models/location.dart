import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 4)
class Location extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  bool isActive;

  Location({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
  });
}
