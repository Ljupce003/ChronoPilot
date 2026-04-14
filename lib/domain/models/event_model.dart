import 'dart:convert';

import 'package:chrono_pilot/domain/models/recurring_rule.dart';

import '../enums/event_subtype.dart';
import '../enums/event_type.dart';
import 'event_location.dart';
import 'lecture_details.dart';

class EventModel {
  final String id;
  final String userId;

  final String title;
  final String? description;

  final DateTime? startDateTime;
  final DateTime? endDateTime;

  final EventLocation? location;
  final String? imagePath;

  final EventType type;

  // TO-DO / Task fields
  final bool isCompleted;
  final DateTime? deadline;

  // Lecture fields
  final LectureDetails? lectureDetails;
  final EventSubtype? subtype;

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
    this.type = EventType.single,
    this.isCompleted = false,
    this.deadline,
    this.lectureDetails,
    this.subtype,
    this.recurringRule,
  });

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
      type: EventType.values.byName(json['type']),
      isCompleted: json['isCompleted'] ?? false,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      lectureDetails: json['lectureDetails'] != null
          ? LectureDetails.fromJson(json['lectureDetails'])
          : null,
      subtype: json['subtype'] != null
          ? EventSubtype.values.byName(json['subtype'])
          : null,
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
      'type': type.name,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
      'lectureDetails': lectureDetails?.toJson(),
      'subtype': subtype?.name,
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
      'type': type.name,
      'isCompleted': isCompleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
      'lectureDetails': lectureDetails != null ? jsonEncode(lectureDetails!.toJson()) : null,
      'subtype': subtype?.name,
      'recurringRule': recurringRule != null ? jsonEncode(recurringRule!.toJson()) : null,
    };
  }
}