import 'dart:convert';

import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/models/models.dart';

abstract final class LineItemsCodec {
  static List<EventLineItem> decode(String? json) {
    if (json == null || json.trim().isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final raw in list)
          if (raw is Map<String, dynamic>)
            _fromMap(raw),
      ].where((e) => e.label.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static EventLineItem _fromMap(Map<String, dynamic> map) {
    final label = (map['label'] as String? ?? '').trim();
    final amountRaw = map['amount'];
    double? amount;
    if (amountRaw != null) {
      amount = (amountRaw as num).toDouble();
    }
    return EventLineItem(label, amount);
  }

  static String encode(List<EventLineItem> items) {
    final list = [
      for (final item in items)
        if (item.label.trim().isNotEmpty)
          {
            'label': item.label.trim(),
            'amount': item.amount,
          },
    ];
    return jsonEncode(list);
  }

  static List<EventLineItem> resolveLineItems(MaintenanceEventRecord event) {
    final fromJson = decode(event.lineItemsJson);
    if (fromJson.isNotEmpty) return fromJson;
    return fromLegacyEvent(event);
  }

  static List<EventLineItem> fromLegacyEvent(MaintenanceEventRecord e) {
    final out = <EventLineItem>[];
    if (e.vacuum) out.add(const EventLineItem(AppStrings.taskVacuum, null));
    if (e.cleanSkimmer) {
      out.add(const EventLineItem(AppStrings.taskCleanSkimmer, null));
    }
    if (e.addWater) out.add(const EventLineItem(AppStrings.taskAddWater, null));
    if (e.brushWalls) {
      out.add(const EventLineItem(AppStrings.taskBrushWalls, null));
    }
    if (e.chlorine > 0) {
      out.add(EventLineItem(AppStrings.chemicalChlorine, e.chlorine));
    }
    if (e.phUp > 0) out.add(EventLineItem(AppStrings.chemicalPhUp, e.phUp));
    if (e.phDown > 0) {
      out.add(EventLineItem(AppStrings.chemicalPhDown, e.phDown));
    }
    if (e.noPhos > 0) {
      out.add(EventLineItem(AppStrings.chemicalNoPhos, e.noPhos));
    }
    return out;
  }

  static void applyLinesToEvent(
    MaintenanceEventRecord e,
    List<EventLineItem> items,
  ) {
    e.lineItemsJson = encode(items);
    e.vacuum = false;
    e.cleanSkimmer = false;
    e.addWater = false;
    e.brushWalls = false;
    e.chlorine = 0;
    e.phUp = 0;
    e.phDown = 0;
    e.noPhos = 0;

    for (final item in items) {
      final label = item.label.trim();
      if (label.isEmpty) continue;
      if (item.amount == null) {
        if (label == AppStrings.taskVacuum) e.vacuum = true;
        if (label == AppStrings.taskCleanSkimmer) e.cleanSkimmer = true;
        if (label == AppStrings.taskAddWater) e.addWater = true;
        if (label == AppStrings.taskBrushWalls) e.brushWalls = true;
      } else {
        if (label == AppStrings.chemicalChlorine) e.chlorine = item.amount!;
        if (label == AppStrings.chemicalPhUp) e.phUp = item.amount!;
        if (label == AppStrings.chemicalPhDown) e.phDown = item.amount!;
        if (label == AppStrings.chemicalNoPhos) e.noPhos = item.amount!;
      }
    }
  }
}

abstract final class CustomLinesCodec {
  static List<CustomLineEntry> decode(String? json) {
    if (json == null || json.trim().isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final raw in list)
          if (raw is Map<String, dynamic>) _fromMap(raw),
      ].where((e) => e.label.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static CustomLineEntry _fromMap(Map<String, dynamic> map) {
    final label = (map['label'] as String? ?? '').trim();
    final selected = map['selected'] as bool? ?? false;
    final amountRaw = map['amount'];
    double? amount;
    if (amountRaw != null) amount = (amountRaw as num).toDouble();
    return CustomLineEntry(label: label, selected: selected, amount: amount);
  }

  static String encode(List<CustomLineEntry> entries) {
    final list = [
      for (final e in entries)
        if (e.label.trim().isNotEmpty)
          {
            'label': e.label.trim(),
            'selected': e.selected,
            'amount': e.amount,
          },
    ];
    return jsonEncode(list);
  }
}
