import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';

String scheduleTypeLabel(EventScheduleType scheduleType) {
  return switch (scheduleType) {
    EventScheduleType.oneTime => 'One-time',
    EventScheduleType.recurring => 'Recurring',
  };
}

String contentTypeLabel(EventContentType contentType) {
  return switch (contentType) {
    EventContentType.ordinary => 'Event',
    EventContentType.todo => 'Task',
    EventContentType.education => 'Class',
  };
}

String scheduleAndContentLabel({
  required EventScheduleType scheduleType,
  required EventContentType contentType,
}) {
  return switch ((scheduleType, contentType)) {
    (EventScheduleType.oneTime, EventContentType.ordinary) => 'One-time event',
    (EventScheduleType.oneTime, EventContentType.todo) => 'Task',
    (EventScheduleType.oneTime, EventContentType.education) => 'Class session',
    (EventScheduleType.recurring, EventContentType.ordinary) => 'Recurring event',
    (EventScheduleType.recurring, EventContentType.todo) => 'Recurring task',
    (EventScheduleType.recurring, EventContentType.education) => 'Recurring class',
  };
}
