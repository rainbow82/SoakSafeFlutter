import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/database/app_database.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/utils/codecs.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._db);

  final AppDatabase _db;

  Future<ChecklistRecord> loadChecklist(int userId) =>
      _db.getOrCreateChecklist(userId);

  Future<void> saveFullChecklist(int userId, ChecklistRecord checklist) async {
    await _db.upsertChecklist(checklist);
    final event = MaintenanceEventRecord(
      id: 0,
      userId: userId,
      eventType: 'CHECKLIST_SAVED',
      eventTimeMillis: DateTime.now().millisecondsSinceEpoch,
      dateMillis: DateTime.now().millisecondsSinceEpoch,
    );
    final items = _checklistToLineItems(checklist);
    LineItemsCodec.applyLinesToEvent(event, items);
    await _db.insertEvent(event);
  }

  Future<void> ensureTodayDate(int userId) async {
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    await _db.upsertMaintenanceDate(userId, midnight.millisecondsSinceEpoch);
  }

  Future<List<MaintenanceEventRecord>> loadEvents(int userId) =>
      _db.listEvents(userId);

  Future<MaintenanceEventRecord?> eventById(int eventId, int userId) =>
      _db.eventById(eventId, userId);

  Future<void> updateEvent(MaintenanceEventRecord event) =>
      _db.updateEvent(event);

  Future<void> deleteEvent(int eventId, int userId) =>
      _db.deleteEvent(eventId, userId);

  List<EventLineItem> _checklistToLineItems(ChecklistRecord c) {
    final items = <EventLineItem>[];
    if (c.vacuum) items.add(const EventLineItem(AppStrings.taskVacuum, null));
    if (c.cleanSkimmer) {
      items.add(const EventLineItem(AppStrings.taskCleanSkimmer, null));
    }
    if (c.addWater) items.add(const EventLineItem(AppStrings.taskAddWater, null));
    if (c.brushWalls) {
      items.add(const EventLineItem(AppStrings.taskBrushWalls, null));
    }
    if (c.chlorine > 0) {
      items.add(EventLineItem(AppStrings.chemicalChlorine, c.chlorine));
    }
    if (c.phUp > 0) items.add(EventLineItem(AppStrings.chemicalPhUp, c.phUp));
    if (c.phDown > 0) {
      items.add(EventLineItem(AppStrings.chemicalPhDown, c.phDown));
    }
    if (c.noPhos > 0) {
      items.add(EventLineItem(AppStrings.chemicalNoPhos, c.noPhos));
    }
    for (final custom in CustomLinesCodec.decode(c.customLinesJson)) {
      if (!custom.selected) continue;
      items.add(EventLineItem(custom.label, custom.amount));
    }
    return items;
  }
}
