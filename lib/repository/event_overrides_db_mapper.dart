import 'package:chrono_pilot/domain/enums/override_type.dart';
import 'package:chrono_pilot/domain/models/event_override_model.dart';

EventOverride eventOverrideFromDb(Map<String, dynamic> row) {
  return EventOverride(
    id: row['id'],
    userId: row['userId'],
    recurringEventId: row['recurringEventId'],
    type: OverrideType.values.byName(row['type']),
    originalDateTime: DateTime.parse(row['originalDateTime']),
    newStartDateTime: row['newStartDateTime'] != null
        ? DateTime.parse(row['newStartDateTime'])
        : null,
    newEndDateTime: row['newEndDateTime'] != null
        ? DateTime.parse(row['newEndDateTime'])
        : null,
    note: row['note'],
  );
}

Map<String, dynamic> eventOverrideToDb(EventOverride eventOverride) {
  return {
    'id': eventOverride.id,
    'userId': eventOverride.userId,
    'recurringEventId': eventOverride.recurringEventId,
    'type': eventOverride.type.name,
    'originalDateTime': eventOverride.originalDateTime.toIso8601String(),
    'newStartDateTime': eventOverride.newStartDateTime?.toIso8601String(),
    'newEndDateTime': eventOverride.newEndDateTime?.toIso8601String(),
    'note': eventOverride.note,
  };
}

