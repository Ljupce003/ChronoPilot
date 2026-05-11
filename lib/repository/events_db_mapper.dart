import 'dart:convert';

import 'package:chrono_pilot/domain/enums/event_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_type.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';

EventModel fromDb(Map<String, dynamic> row) {
  final rawEducationDetails = row['educationDetails'] ?? row['lectureDetails'];

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
    type: _parseEventType(row['type']),
    isCompleted: row['isCompleted'] == 1,
    deadline: row['deadline'] != null
        ? DateTime.parse(row['deadline'])
        : null,
    educationDetails: rawEducationDetails != null
        ? EducationDetails.fromJson(jsonDecode(rawEducationDetails))
        : null,
    subtype: row['subtype'] != null
        ? EventSubtype.values.byName(row['subtype'])
        : null,
    recurringRule: row['recurringRule'] != null
        ? RecurringRule.fromJson(jsonDecode(row['recurringRule']))
        : null,
  );
}

EventType _parseEventType(dynamic rawType) {
  final value = rawType?.toString();
  if (value == null || value.isEmpty) {
    return EventType.single;
  }

  // Backward compatibility with older persisted enum values.
  if (value == 'lecture') {
    return EventType.education;
  }

  return EventType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => EventType.single,
  );
}
