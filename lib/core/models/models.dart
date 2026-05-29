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
  });

  final int id;
  final String username;
  final String password;
  final String fullName;
  final int poolSizeGallons;
  final bool poolSaltWater;
  final bool poolAboveGround;
}

class ChecklistRecord {
  ChecklistRecord({
    required this.userId,
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
