import 'package:chrono_pilot/domain/enums/override_type.dart';
import 'package:chrono_pilot/utils/enum_utils.dart';

class EventOverride {
  final String id;
  final String userId;

  final String recurringEventId;

  final OverrideType overrideType;

  final DateTime originalDateTime;

  // only used if modified
  final DateTime? newStartDateTime;
  final DateTime? newEndDateTime;
  final String? replacementEventId;

  final String? note;

  EventOverride({
    required this.id,
    required this.userId,
    required this.recurringEventId,
    required this.overrideType,
    required this.originalDateTime,
    this.newStartDateTime,
    this.newEndDateTime,
    this.replacementEventId,
    this.note,
  });

  factory EventOverride.fromJson(Map<String, dynamic> json) {
    return EventOverride(
      id: json['id'],
      userId: json['userId'],
      recurringEventId: json['recurringEventId'],
      overrideType: enumFromString(OverrideType.values, json['overrideType']) ??
          OverrideType.values.first,
      originalDateTime: DateTime.parse(json['originalDateTime']),
      newStartDateTime: json['newStartDateTime'] != null
          ? DateTime.parse(json['newStartDateTime'])
          : null,
      newEndDateTime: json['newEndDateTime'] != null
          ? DateTime.parse(json['newEndDateTime'])
          : null,
      replacementEventId: json['replacementEventId'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recurringEventId': recurringEventId,
      'overrideType': overrideType.name,
      'originalDateTime': originalDateTime.toIso8601String(),
      'newStartDateTime': newStartDateTime?.toIso8601String(),
      'newEndDateTime': newEndDateTime?.toIso8601String(),
      'replacementEventId': replacementEventId,
      'note': note,
    };
  }
}
