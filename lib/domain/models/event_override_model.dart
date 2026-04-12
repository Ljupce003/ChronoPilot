import '../enums/override_type.dart';

class EventOverride {
  final String id;
  final String userId;

  final String recurringEventId;

  final OverrideType type;

  // only used if modified
  final DateTime? newStartDateTime;
  final DateTime? newEndDateTime;

  final String? note;

  EventOverride({
    required this.id,
    required this.userId,
    required this.recurringEventId,
    required this.type,
    this.newStartDateTime,
    this.newEndDateTime,
    this.note,
  });

  factory EventOverride.fromJson(Map<String, dynamic> json) {
    return EventOverride(
      id: json['id'],
      userId: json['userId'],
      recurringEventId: json['recurringEventId'],
      type: OverrideType.values.byName(json['type']),
      newStartDateTime: json['newStartDateTime'] != null
          ? DateTime.parse(json['newStartDateTime'])
          : null,
      newEndDateTime: json['newEndDateTime'] != null
          ? DateTime.parse(json['newEndDateTime'])
          : null,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recurringEventId': recurringEventId,
      'type': type.name,
      'newStartDateTime': newStartDateTime?.toIso8601String(),
      'newEndDateTime': newEndDateTime?.toIso8601String(),
      'note': note,
    };
  }
}
