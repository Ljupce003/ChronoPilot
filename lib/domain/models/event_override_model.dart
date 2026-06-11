import 'package:chrono_pilot/domain/enums/override_type.dart';
import 'package:chrono_pilot/utils/enum_utils.dart';

/// Stores the override state for one recurring event occurrence.
///
/// Overrides can represent cancellations or modifications and may optionally
/// point to a replacement event row created for the altered occurrence.
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

  /// Creates an override record.
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

  /// Creates an override model from a decoded JSON map.
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

  /// Serializes the override to a JSON-compatible map.
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
