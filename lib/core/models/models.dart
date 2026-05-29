import 'package:soaksafe/core/constants/app_strings.dart';

/// A maintainable water body. Checklists and saved events are scoped per
/// target so pool and hot tub maintenance are tracked independently.
enum MaintenanceTarget {
  pool,
  hotTub;

  String get storageValue =>
      this == MaintenanceTarget.hotTub ? 'HOT_TUB' : 'POOL';

  String get label => this == MaintenanceTarget.hotTub
      ? AppStrings.waterBodyHotTub
      : AppStrings.waterBodyPool;

  static MaintenanceTarget fromStorage(String? value) =>
      value == 'HOT_TUB' ? MaintenanceTarget.hotTub : MaintenanceTarget.pool;
}

class EventLineItem {
  const EventLineItem(this.label, this.amount);

  final String label;
  final double? amount;
}

class CustomLineEntry {
  const CustomLineEntry({
    required this.label,
    required this.selected,
    this.amount,
  });

  final String label;
  final bool selected;
  final double? amount;
}

class UserRecord {
  UserRecord({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.poolSizeGallons,
    required this.poolSaltWater,
    required this.poolAboveGround,
    this.hotTubSizeGallons = 0,
    this.hotTubSaltWater = false,
  });

  final int id;
  final String username;
  final String password;
  final String fullName;
  final int poolSizeGallons;
  final bool poolSaltWater;
  final bool poolAboveGround;
  final int hotTubSizeGallons;
  final bool hotTubSaltWater;
}

class ChecklistRecord {
  ChecklistRecord({
    required this.userId,
    this.target = MaintenanceTarget.pool,
    this.vacuum = false,
    this.cleanSkimmer = false,
    this.addWater = false,
    this.brushWalls = false,
    this.chlorine = 0,
    this.phUp = 0,
    this.phDown = 0,
    this.noPhos = 0,
    this.customLinesJson,
  });

  final int userId;
  final MaintenanceTarget target;
  bool vacuum;
  bool cleanSkimmer;
  bool addWater;
  bool brushWalls;
  double chlorine;
  double phUp;
  double phDown;
  double noPhos;
  String? customLinesJson;
}

class MaintenanceEventRecord {
  MaintenanceEventRecord({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventTimeMillis,
    required this.dateMillis,
    this.target = MaintenanceTarget.pool,
    this.vacuum = false,
    this.cleanSkimmer = false,
    this.addWater = false,
    this.brushWalls = false,
    this.chlorine = 0,
    this.phUp = 0,
    this.phDown = 0,
    this.noPhos = 0,
    this.lineItemsJson,
  });

  final int id;
  final int userId;
  final String eventType;
  final MaintenanceTarget target;
  int eventTimeMillis;
  int dateMillis;
  bool vacuum;
  bool cleanSkimmer;
  bool addWater;
  bool brushWalls;
  double chlorine;
  double phUp;
  double phDown;
  double noPhos;
  String? lineItemsJson;
}
