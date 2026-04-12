import '../enums/event_subtype.dart';
import 'event_location.dart';
import 'lecture_details.dart';

class RecurringEventModel {
  final String id;
  final String userId;

  final String title;

  final List<int> daysOfWeek;

  // 1 = Monday ... 7 = Sunday

  final DateTime startDate;
  final DateTime? endDate;

  final DateTime startTime;
  final DateTime endTime;

  final EventLocation? location;

  // Lecture/Auditory/Lab model
  final LectureDetails? lectureDetails;
  final EventSubtype? subtype;

  RecurringEventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.startTime,
    required this.endTime,
    this.location,
    this.lectureDetails,
    this.subtype,
  });

  factory RecurringEventModel.fromJson(Map<String, dynamic> json) {
    return RecurringEventModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      location: json['location'] != null
          ? EventLocation.fromJson(json['location'])
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
      'daysOfWeek': daysOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location?.toJson(),

      'lectureDetails': lectureDetails?.toJson(),
      'subtype': subtype?.name,
    };
  }
}
