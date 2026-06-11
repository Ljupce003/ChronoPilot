import 'dart:convert';

import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';
import 'package:chrono_pilot/utils/enum_utils.dart';

/// Converts a raw SQLite row into an `EventModel`.
///
/// Enum fields are parsed defensively so older rows or unexpected casing do not
/// crash the app; unknown values fall back to sensible defaults.
EventModel fromDb(Map<String, dynamic> row) {
  return EventModel(
    id: row['id'],
    userId: row['userId'],
    title: row['title'],
    description: row['description'],
    startDateTime: row['startDateTime'] != null
        ? DateTime.parse(row['startDateTime'])
        : null,
    endDateTime: row['endDateTime'] != null
        ? DateTime.parse(row['endDateTime'])
        : null,
    location: row['location'] != null
        ? EventLocation.fromJson(jsonDecode(row['location']))
        : null,
    imagePath: row['imagePath'],
    scheduleType:
        enumFromString(EventScheduleType.values, row['scheduleType']) ??
            EventScheduleType.oneTime,
    contentType:
        enumFromString(EventContentType.values, row['contentType']) ??
            EventContentType.ordinary,
    isCompleted: row['isCompleted'] == 1,
    deadline: row['deadline'] != null
        ? DateTime.parse(row['deadline'])
        : null,
    educationDetails: row['educationDetails'] != null
        ? EducationDetails.fromJson(jsonDecode(row['educationDetails']))
        : null,
    educationSubtype: enumFromString<EducationSubtype>(
      EducationSubtype.values,
      row['educationSubtype'],
    ),
    recurringRule: row['recurringRule'] != null
        ? RecurringRule.fromJson(jsonDecode(row['recurringRule']))
        : null,
  );
}
