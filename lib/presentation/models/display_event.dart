import 'display_event_type.dart';

class DisplayEvent {
  final String id;

  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;

  final DisplayEventType type;

  final String? recurringEventId;
  final bool isOverride;

  final bool isCompleted;

  final String? locationName;

  DisplayEvent({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.type,
    this.recurringEventId,
    this.isOverride = false,
    this.isCompleted = false,
    this.locationName,
  });
}