import 'dart:ui';

import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/utils/app_theme.dart';

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
    EventContentType.holiday => 'Holiday',
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
    (EventScheduleType.oneTime, EventContentType.holiday) => 'Holiday',
    (EventScheduleType.recurring, EventContentType.ordinary) => 'Recurring event',
    (EventScheduleType.recurring, EventContentType.todo) => 'Recurring task',
    (EventScheduleType.recurring, EventContentType.education) => 'Recurring class',
    (EventScheduleType.recurring, EventContentType.holiday) => 'Recurring holiday',
  };
}

Color getColorForCard(EducationSubtype? subtype) {
  switch (subtype) {
    case EducationSubtype.lecture:
      return AppColors.educationLecture;
    case EducationSubtype.lab:
      return AppColors.educationLab;
    case EducationSubtype.auditory:
      return AppColors.educationAuditory;
    default:
    // Fallback color if subtype is null or an unhandled type
      return AppColors.educationLecture;
  }
}
