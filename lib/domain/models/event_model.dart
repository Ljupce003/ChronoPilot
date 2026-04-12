import '../enums/event_subtype.dart';
import '../enums/event_type.dart';
import 'event_location.dart';
import 'lecture_details.dart';

class EventModel {
  final String id;
  final String userId;

  final String title;

  // final DateTime date;

  final DateTime startDateTime;
  final DateTime endDateTime;

  final EventLocation? location;
  final String? imagePath;

  final String? recurringEventId;
  final EventType type;

  // TODO fields
  final bool isCompleted;
  final DateTime? deadline;

  // Lecture/Auditory/Lab model
  final LectureDetails? lectureDetails;
  final EventSubtype? subtype;

  EventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.location,
    this.imagePath,
    this.recurringEventId,
    this.type = EventType.single,
    this.isCompleted = false,
    this.deadline,
    this.lectureDetails,
    this.subtype,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      location: json['location'] != null
          ? EventLocation.fromJson(json['location'])
          : null,
      imagePath: json['imagePath'],
      recurringEventId: json['recurringEventId'],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'location': location?.toJson(),
      'imagePath': imagePath,
      'recurringEventId': recurringEventId,
      'type': type.name,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),

      'lectureDetails': lectureDetails?.toJson(),
      'subtype': subtype?.name,
    };
  }
}
