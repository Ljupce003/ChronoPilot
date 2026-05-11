import 'dart:convert';

import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';
import 'package:chrono_pilot/utils/enum_utils.dart';
import 'package:chrono_pilot/utils/event_classification.dart';

import 'event_location.dart';
import 'education_details.dart';

class EventModel {
  final String id;
  final String userId;

  final String title;
  final String? description;

  final DateTime? startDateTime;
  final DateTime? endDateTime;

  final EventLocation? location;
  final String? imagePath;

  final EventScheduleType scheduleType;
  final EventContentType contentType;

  // TO-DO / Task fields
  final bool isCompleted;
  final DateTime? deadline;

  // Education fields
  final EducationDetails? educationDetails;
  final EducationSubtype? educationSubtype;

  // Recurring rule embedded
  final RecurringRule? recurringRule;

  EventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
    this.location,
    this.imagePath,
    this.scheduleType = EventScheduleType.oneTime,
    this.contentType = EventContentType.ordinary,
    this.isCompleted = false,
    this.deadline,
    this.educationDetails,
    this.educationSubtype,
    this.recurringRule,
  });

  bool get isRecurring => scheduleType == EventScheduleType.recurring;

  String get scheduleAndContentText =>
      scheduleAndContentLabel(
        scheduleType: scheduleType,
        contentType: contentType,
      );

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      startDateTime: json['startDateTime'] != null
          ? DateTime.parse(json['startDateTime'])
          : null,
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'])
          : null,
      location: json['location'] != null
          ? EventLocation.fromJson(json['location'])
          : null,
      imagePath: json['imagePath'],
      scheduleType: enumFromString<EventScheduleType>(
            EventScheduleType.values,
            json['scheduleType'],
          ) ??
          EventScheduleType.oneTime,
      contentType: enumFromString<EventContentType>(
            EventContentType.values,
            json['contentType'],
          ) ??
          EventContentType.ordinary,
      isCompleted: json['isCompleted'] ?? false,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      educationDetails: json['educationDetails'] != null
          ? EducationDetails.fromJson(json['educationDetails'])
          : null,
      educationSubtype: enumFromString<EducationSubtype>(
        EducationSubtype.values,
        json['educationSubtype'],
      ),
      recurringRule: json['recurringRule'] != null
          ? RecurringRule.fromJson(json['recurringRule'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'location': location?.toJson(),
      'imagePath': imagePath,
      'scheduleType': scheduleType.name,
      'contentType': contentType.name,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
      'educationDetails': educationDetails?.toJson(),
      'educationSubtype': educationSubtype?.name,
      'recurringRule': recurringRule?.toJson(),
    };
  }

  Map<String, dynamic> toJsonEncoded() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'location': location != null ? jsonEncode(location!.toJson()) : null,
      'imagePath': imagePath,
      'scheduleType': scheduleType.name,
      'contentType': contentType.name,
      'isCompleted': isCompleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
      'educationDetails': educationDetails != null
          ? jsonEncode(educationDetails!.toJson())
          : null,
      'educationSubtype': educationSubtype?.name,
      'recurringRule': recurringRule != null
          ? jsonEncode(recurringRule!.toJson())
          : null,
    };
  }
}