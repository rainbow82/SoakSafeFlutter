import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/database/app_database.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/utils/codecs.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._db);

  final AppDatabase _db;

  Future<ChecklistRecord> loadChecklist(
    int userId,
    MaintenanceTarget target,
  ) =>
      _db.getChecklistOrDefault(userId, target);

  Future<void> saveFullChecklist(int userId, ChecklistRecord checklist) async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final target = checklist.target;

    await _db.upsertChecklist(checklist);
    await _db.upsertMaintenanceDate(userId, midnight.millisecondsSinceEpoch);

    final items = _checklistToLineItems(checklist);
    final existing = await _db.checklistSavedEventForDay(userId, now, target);
    final eventTimeMillis = now.millisecondsSinceEpoch;

    if (existing != null) {
      existing.eventTimeMillis = eventTimeMillis;
      existing.dateMillis = eventTimeMillis;
      LineItemsCodec.applyLinesToEvent(existing, items);
      await _db.updateEvent(existing);
      return;
    }

    final event = MaintenanceEventRecord(
      id: 0,
      userId: userId,
      eventType: 'CHECKLIST_SAVED',
      target: target,
      eventTimeMillis: eventTimeMillis,
      dateMillis: eventTimeMillis,
    );
    LineItemsCodec.applyLinesToEvent(event, items);
    await _db.insertEvent(event);
  }

  Future<List<MaintenanceEventRecord>> loadEvents(int userId) async {
    final events = await _db.listEvents(userId);
    return events.where((e) => e.eventType == 'CHECKLIST_SAVED').toList();
  }

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
