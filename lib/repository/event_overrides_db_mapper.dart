import 'package:chrono_pilot/domain/enums/override_type.dart';
import 'package:chrono_pilot/domain/models/event_override_model.dart';

T? enumFromString<T extends Enum>(List<T> values, String? source) {
  if (source == null) return null;
  // Try exact match first (case-sensitive)
  try {
    return values.firstWhere((e) => e.name == source);
  } catch (_) {
    // Try case-insensitive
    try {
      return values.firstWhere((e) => e.name.toLowerCase() == source.toLowerCase());
    } catch (_) {
      // Nothing matched
      return null;
    }
  }
}

EventOverride eventOverrideFromDb(Map<String, dynamic> row) {
  // Use the safe enum parser to avoid throws when DB value has different casing or unexpected value
  final parsedType = enumFromString(OverrideType.values, row['overrideType'] as String?);

  return EventOverride(
    id: row['id'],
    userId: row['userId'],
    recurringEventId: row['recurringEventId'],
    overrideType: parsedType ?? OverrideType.values.first,
    originalDateTime: DateTime.parse(row['originalDateTime']),
    newStartDateTime: row['newStartDateTime'] != null
        ? DateTime.parse(row['newStartDateTime'])
        : null,
    newEndDateTime: row['newEndDateTime'] != null
        ? DateTime.parse(row['newEndDateTime'])
        : null,
    replacementEventId: row['replacementEventId'],
    note: row['note'],
  );
}

Map<String, dynamic> eventOverrideToDb(EventOverride eventOverride) {
  return {
    'id': eventOverride.id,
    'userId': eventOverride.userId,
    'recurringEventId': eventOverride.recurringEventId,
    'overrideType': eventOverride.overrideType.name,
    'originalDateTime': eventOverride.originalDateTime.toIso8601String(),
    'newStartDateTime': eventOverride.newStartDateTime?.toIso8601String(),
    'newEndDateTime': eventOverride.newEndDateTime?.toIso8601String(),
    'replacementEventId': eventOverride.replacementEventId,
    'note': eventOverride.note,
  };
}
